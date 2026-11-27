#!/bin/bash

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVICE_NAME="resthome.service"
SERVICE_FILE="$HOME/.config/systemd/user/$SERVICE_NAME"
HOST_NAME="rest.home"
PORT=8000
PROFILE_DIR="$DIR/firefox-setup-profile"   # NON nascosta: Firefox snap non puo' leggere cartelle nascoste
VENV_DIR="$DIR/.venv"
LOG_FILE="$DIR/server.log"
PYTHON=""
FF_CMD=()

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

pause_menu() {
    read -r -p "Press Enter to return to menu..."
}

show_menu() {
    clear
    echo -e "${CYAN}======================================${NC}"
    echo -e "${CYAN}       REST. - Control Menu           ${NC}"
    echo -e "${CYAN}======================================${NC}"
    echo "1) Install rest. (Server + Hosts)"
    echo "2) Start server"
    echo "3) Stop server"
    echo "4) Check server status"
    echo "5) Uninstall everything"
    echo "6) Exit"
    echo -e "${CYAN}======================================${NC}"
    read -r -p "Choose an option [1-6]: " choice
}

# ---------- utilita' ----------

# uso: pm_install "<pacchetti apt>" "<dnf>" "<pacman>" "<zypper>"
pm_install() {
    if command -v apt-get &>/dev/null; then
        sudo apt-get update -qq && sudo apt-get install -y $1
    elif command -v dnf &>/dev/null; then
        sudo dnf install -y $2
    elif command -v pacman &>/dev/null; then
        sudo pacman -S --noconfirm --needed $3
    elif command -v zypper &>/dev/null; then
        sudo zypper --non-interactive install $4
    else
        return 1
    fi
}

hosts_has_entry() {
    grep -qE "^[^#]*[[:space:]]rest\.home([[:space:]]|$)" /etc/hosts
}

wait_for_server() {
    local i
    for i in $(seq 1 40); do
        if ( exec 3<>/dev/tcp/127.0.0.1/$PORT ) 2>/dev/null; then
            return 0
        fi
        sleep 0.5
    done
    return 1
}

# ---------- Python + moduli ----------

ensure_python() {
    if ! command -v python3 &>/dev/null; then
        echo -e "${YELLOW}Python 3 not found. Installing (may ask for sudo password)...${NC}"
        pm_install "python3 python3-venv python3-pip" "python3 python3-pip" "python" "python3 python3-pip"
    fi
    if ! command -v python3 &>/dev/null; then
        echo -e "${RED}Error: could not install Python 3. Please install it manually.${NC}"
        return 1
    fi
    PYTHON="$(command -v python3)"

    # Se esiste requirements.txt installa i moduli in un venv dedicato
    if [ -f "$DIR/requirements.txt" ]; then
        echo -e "${CYAN}Installing Python modules from requirements.txt...${NC}"
        if [ ! -x "$VENV_DIR/bin/python" ]; then
            if ! "$PYTHON" -m venv "$VENV_DIR" 2>/dev/null; then
                rm -rf "$VENV_DIR"
                pm_install "python3-venv python3-pip" "python3-pip" "python-pip" "python3-pip"
                if ! "$PYTHON" -m venv "$VENV_DIR"; then
                    echo -e "${RED}Error: could not create virtual environment.${NC}"
                    return 1
                fi
            fi
        fi
        "$VENV_DIR/bin/python" -m pip install --upgrade pip -q
        if ! "$VENV_DIR/bin/python" -m pip install -r "$DIR/requirements.txt"; then
            echo -e "${RED}Error: module installation failed.${NC}"
            return 1
        fi
        PYTHON="$VENV_DIR/bin/python"
    fi
    return 0
}

# ---------- Firefox ----------

find_firefox() {
    FF_CMD=()
    local c
    for c in firefox firefox-esr /snap/bin/firefox /usr/bin/firefox /usr/lib/firefox/firefox /opt/firefox/firefox; do
        if command -v "$c" &>/dev/null; then
            FF_CMD=("$(command -v "$c")")
            return 0
        fi
    done
    if command -v flatpak &>/dev/null && flatpak info org.mozilla.firefox &>/dev/null; then
        FF_CMD=(flatpak run --filesystem="$PROFILE_DIR" org.mozilla.firefox)
        return 0
    fi
    return 1
}

ensure_firefox() {
    if find_firefox; then return 0; fi
    echo -e "${YELLOW}Firefox not found. Installing (may ask for sudo password)...${NC}"
    pm_install "firefox" "firefox" "firefox" "MozillaFirefox"
    if find_firefox; then return 0; fi
    echo -e "${RED}Error: Firefox not found and could not be installed automatically.${NC}"
    return 1
}

write_user_js() {
    cat > "$PROFILE_DIR/user.js" << 'EOF'
user_pref("browser.shell.checkDefaultBrowser", false);
user_pref("browser.startup.page", 0);
user_pref("browser.startup.homepage_override.mstone", "ignore");
user_pref("startup.homepage_welcome_url", "");
user_pref("startup.homepage_welcome_url.additional", "");
user_pref("browser.aboutwelcome.enabled", false);
user_pref("browser.rights.3.shown", true);
user_pref("browser.tabs.warnOnClose", false);
user_pref("datareporting.policy.dataSubmissionEnabled", false);
user_pref("datareporting.policy.firstRunURL", "");
user_pref("toolkit.telemetry.reportingpolicy.firstRun", false);
user_pref("trailhead.firstrun.didSeeAboutWelcome", true);
user_pref("signon.rememberSignons", false);
user_pref("signon.autofillForms", false);
user_pref("network.trr.mode", 5);
user_pref("network.proxy.type", 0);
user_pref("dom.security.https_only_mode", false);
user_pref("app.update.auto", false);
user_pref("app.update.enabled", false);
EOF
}

launch_setup() {
    local url="http://$HOST_NAME:$PORT/setup.html"
    if ! getent hosts "$HOST_NAME" 2>/dev/null | grep -q "127.0.0.1"; then
        url="http://127.0.0.1:$PORT/setup.html"
    fi

    if [ -z "$DISPLAY$WAYLAND_DISPLAY" ]; then
        echo -e "${YELLOW}No graphical session detected. Open this address manually:${NC} $url"
        return 0
    fi

    # Profilo nuovo e isolato + -no-remote = SEMPRE una nuova finestra Firefox separata,
    # anche se Firefox e' gia' aperto con il profilo normale.
    rm -rf "$PROFILE_DIR"
    mkdir -p "$PROFILE_DIR"
    write_user_js

    MOZ_NO_REMOTE=1 "${FF_CMD[@]}" -no-remote -profile "$PROFILE_DIR" -kiosk "$url" >/dev/null 2>&1

    # Aspetta che la finestra del setup venga davvero chiusa
    sleep 1
    while pgrep -f "$PROFILE_DIR" >/dev/null 2>&1; do sleep 1; done
    rm -rf "$PROFILE_DIR"
}

# ---------- azioni menu ----------

install_rest() {
    echo -e "\n${CYAN}Installing...${NC}"

    if [ ! -f "$DIR/server.py" ]; then
        echo -e "${RED}Error: server.py not found in $DIR${NC}"
        pause_menu
        return
    fi

    if ! ensure_python; then pause_menu; return; fi
    if ! ensure_firefox; then pause_menu; return; fi

    if ! systemctl --user daemon-reload 2>/dev/null; then
        echo -e "${RED}Error: systemd user session not available.${NC}"
        pause_menu
        return
    fi

    mkdir -p "$HOME/.config/systemd/user"
    cat > "$SERVICE_FILE" << EOF
[Unit]
Description=Resthome ASCII Server
After=default.target

[Service]
Type=simple
WorkingDirectory=$DIR
ExecStart="$PYTHON" -u server.py
StandardOutput=append:$LOG_FILE
StandardError=append:$LOG_FILE
Restart=on-failure
RestartSec=5

[Install]
WantedBy=default.target
EOF

    systemctl --user daemon-reload
    systemctl --user enable "$SERVICE_NAME"
    systemctl --user restart "$SERVICE_NAME"

    if ! hosts_has_entry; then
        echo -e "${CYAN}Adding 'rest.home' to /etc/hosts (may ask for sudo password)...${NC}"
        printf '\n127.0.0.1 rest.home\n' | sudo tee -a /etc/hosts > /dev/null
    fi

    echo -e "${CYAN}Waiting for the server...${NC}"
    if ! wait_for_server; then
        echo -e "${RED}Error: server did not start on port $PORT. Last log lines:${NC}"
        tail -n 15 "$LOG_FILE" 2>/dev/null
        pause_menu
        return
    fi

    echo -e "${GREEN}✓ Installation complete!${NC}"
    echo -e "${CYAN}Launching setup in a new fullscreen Firefox window...${NC}"
    echo -e "${YELLOW}(close the setup window with Alt+F4 when you are done)${NC}"

    launch_setup

    echo -e "\n${GREEN}✓ Setup complete!${NC}"
    echo -e "${CYAN}rest. is now available at http://$HOST_NAME:$PORT${NC}"
    pause_menu
}

start_rest() {
    echo -e "\n${CYAN}Starting server...${NC}"
    if [ ! -f "$SERVICE_FILE" ]; then
        echo -e "${RED}Not installed. Use option 1 first.${NC}"
    elif systemctl --user start "$SERVICE_NAME"; then
        echo -e "${GREEN}✓ Server started.${NC}"
    else
        echo -e "${RED}Could not start the server.${NC}"
    fi
    pause_menu
}

stop_rest() {
    echo -e "\n${CYAN}Stopping server...${NC}"
    if systemctl --user stop "$SERVICE_NAME" 2>/dev/null; then
        echo -e "${GREEN}✓ Server stopped.${NC}"
    else
        echo -e "${RED}Could not stop the server (not installed?).${NC}"
    fi
    pause_menu
}

status_rest() {
    echo -e "\n${CYAN}Server status:${NC}"
    if [ ! -f "$SERVICE_FILE" ]; then
        echo -e "${RED}Not installed.${NC}"
    else
        systemctl --user status "$SERVICE_NAME" 2>/dev/null | grep "Active:"
    fi
    pause_menu
}

uninstall_rest() {
    echo -e "\n${RED}Uninstalling...${NC}"
    systemctl --user stop "$SERVICE_NAME" 2>/dev/null
    systemctl --user disable "$SERVICE_NAME" 2>/dev/null
    rm -f "$SERVICE_FILE"
    systemctl --user daemon-reload 2>/dev/null

    echo -e "${CYAN}Removing entry from /etc/hosts (may ask for sudo password)...${NC}"
    sudo sed -i '/rest\.home/d' /etc/hosts

    rm -rf "$PROFILE_DIR" "$VENV_DIR"
    echo -e "${GREEN}✓ Uninstallation complete.${NC}"
    pause_menu
}

while true; do
    show_menu
    case $choice in
        1) install_rest ;;
        2) start_rest ;;
        3) stop_rest ;;
        4) status_rest ;;
        5) uninstall_rest ;;
        6) echo "Exiting."; exit 0 ;;
        *) echo -e "${RED}Invalid option.${NC}"; sleep 2 ;;
    esac
done
