#!/bin/bash

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVICE_FILE="$HOME/.config/systemd/user/resthome.service"
SERVICE_NAME="resthome.service"

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
        echo -e "${RED}Error: Python 3 not found. Please install python3 first.${NC}"
        read -p "Press Enter to return to menu..."
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
ExecStart=/usr/bin/python3 server.py
Restart=on-failure
RestartSec=5

[Install]
WantedBy=default.target
EOF

    systemctl --user daemon-reload
    systemctl --user enable --now $SERVICE_NAME
    
    if ! grep -q "rest.home" /etc/hosts; then
        echo -e "${CYAN}Adding 'rest.home' to /etc/hosts (may ask for sudo password)...${NC}"
        echo "127.0.0.1 rest.home" | sudo tee -a /etc/hosts > /dev/null
    fi
    echo -e "${GREEN}✓ Installation complete!${NC}"
    echo -e "${CYAN}Open your browser and go to: http://rest.home:8000/setup.html${NC}"
    read -p "Press Enter to return to menu..."
}

start_rest() {
    echo -e "\n${CYAN}Starting server...${NC}"
    systemctl --user start $SERVICE_NAME
    echo -e "${GREEN}✓ Server started.${NC}"
    read -p "Press Enter to return to menu..."
}

stop_rest() {
    echo -e "\n${CYAN}Stopping server...${NC}"
    systemctl --user stop $SERVICE_NAME
    echo -e "${GREEN}✓ Server stopped.${NC}"
    read -p "Press Enter to return to menu..."
}

status_rest() {
    echo -e "\n${CYAN}Server status:${NC}"
    systemctl --user status $SERVICE_NAME | grep "Active:"
    read -p "Press Enter to return to menu..."
}

uninstall_rest() {
    echo -e "\n${RED}Uninstalling...${NC}"
    systemctl --user stop $SERVICE_NAME 2>/dev/null
    systemctl --user disable $SERVICE_NAME 2>/dev/null
    rm -f "$SERVICE_FILE"
    systemctl --user daemon-reload
    
    echo -e "${CYAN}Removing entry from /etc/hosts (may ask for sudo password)...${NC}"
    sudo sed -i '/rest.home/d' /etc/hosts
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
