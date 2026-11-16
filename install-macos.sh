#!/bin/bash

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLIST="$HOME/Library/LaunchAgents/com.resthome.server.plist"
LABEL="com.resthome.server"

GREEN='\033[0;32m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

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
    read -p "Choose an option [1-6]: " choice
}

install_rest() {
    echo -e "\n${CYAN}Installing...${NC}"
    
    if ! command -v python3 &> /dev/null; then
        echo -e "${RED}Error: Python 3 not found.${NC}"
        read -p "Press Enter to return to menu..."
        return
    fi

    mkdir -p "$HOME/Library/LaunchAgents"
    cat > "$PLIST" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>$LABEL</string>
    <key>ProgramArguments</key>
    <array>
        <string>$(command -v python3)</string>
        <string>-m</string>
        <string>http.server</string>
        <string>8000</string>
    </array>
    <key>WorkingDirectory</key>
    <string>$DIR</string>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
</dict>
</plist>
EOF

    launchctl unload "$PLIST" 2>/dev/null || true
    launchctl load "$PLIST"
    
    if ! grep -q "rest.home" /etc/hosts; then
        echo -e "${CYAN}Adding 'rest.home' to /etc/hosts (may ask for sudo password)...${NC}"
        echo "127.0.0.1 rest.home" | sudo tee -a /etc/hosts > /dev/null
    fi
    echo -e "${GREEN}✓ Installation complete! Go to http://rest.home:8000${NC}"
    read -p "Press Enter to return to menu..."
}

start_rest() {
    echo -e "\n${CYAN}Starting server...${NC}"
    launchctl start $LABEL
    echo -e "${GREEN}✓ Server started.${NC}"
    read -p "Press Enter to return to menu..."
}

stop_rest() {
    echo -e "\n${CYAN}Stopping server...${NC}"
    launchctl stop $LABEL
    echo -e "${GREEN}✓ Server stopped.${NC}"
    read -p "Press Enter to return to menu..."
}

status_rest() {
    echo -e "\n${CYAN}Server status:${NC}"
    if launchctl list | grep -q $LABEL; then
        echo -e "${GREEN}Active.${NC}"
    else
        echo -e "${RED}Not active.${NC}"
    fi
    read -p "Press Enter to return to menu..."
}

uninstall_rest() {
    echo -e "\n${RED}Uninstalling...${NC}"
    launchctl unload "$PLIST" 2>/dev/null || true
    rm -f "$PLIST"
    
    echo -e "${CYAN}Removing entry from /etc/hosts (may ask for sudo password)...${NC}"
    sudo sed -i '' '/rest.home/d' /etc/hosts
    echo -e "${GREEN}✓ Uninstallation complete.${NC}"
    read -p "Press Enter to return to menu..."
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