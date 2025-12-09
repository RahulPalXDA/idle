#!/bin/bash
# Run with sudo: sudo ./setup.sh

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}=== Idle Master X11 Setup ===${NC}"

if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}Error: Run as root (sudo ./setup.sh)${NC}"
  exit 1
fi

# 1. Install Dependencies
echo -e "\n${GREEN}[1/3] Installing Libraries...${NC}"
if command -v apt-get &> /dev/null; then
    apt-get update -qq
    apt-get install -y clang libx11-dev libxss-dev libxtst-dev libcurl4-openssl-dev make
elif command -v pacman &> /dev/null; then
    pacman -Sy --noconfirm clang libx11 libxss libxtst curl make
fi

# 2. Compile & Install
echo -e "\n${GREEN}[2/3] Compiling...${NC}"
make clean
if make; then
    echo "Build Success."
    make install
else
    echo -e "${RED}Build Failed.${NC}"
    exit 1
fi

# 3. Create User Service
echo -e "\n${GREEN}[3/3] Creating User Service...${NC}"

SERVICE_FILE="/etc/systemd/user/idle_master.service"

cat > "$SERVICE_FILE" <<EOF
[Unit]
Description=Idle Master (X11 Userspace)
After=graphical-session.target network.target

[Service]
ExecStart=/usr/local/bin/idle_master
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=default.target
EOF

echo "Service created at $SERVICE_FILE"
echo -e "\n${GREEN}Done! Now run these commands as your NORMAL USER (not sudo):${NC}"
echo "----------------------------------------------------"
echo "  systemctl --user daemon-reload"
echo "  systemctl --user enable --now idle_master"
echo "----------------------------------------------------"
