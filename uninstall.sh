#!/bin/bash
# Run with sudo: sudo ./uninstall.sh

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}=== Idle Master Uninstall ===${NC}"

if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}Error: Run as root (sudo ./uninstall.sh)${NC}"
  exit 1
fi

# Get the actual user (not root)
REAL_USER="${SUDO_USER:-$USER}"

# 1. Stop and disable user service
echo -e "\n${GREEN}[1/3] Stopping service...${NC}"
su - "$REAL_USER" -c "systemctl --user stop idle_master 2>/dev/null"
su - "$REAL_USER" -c "systemctl --user disable idle_master 2>/dev/null"

# 2. Remove service file
echo -e "\n${GREEN}[2/3] Removing service file...${NC}"
SERVICE_FILE="/etc/systemd/user/idle_master.service"
if [ -f "$SERVICE_FILE" ]; then
    rm -f "$SERVICE_FILE"
    echo "Removed $SERVICE_FILE"
else
    echo "Service file not found (already removed)"
fi

# 3. Remove binary
echo -e "\n${GREEN}[3/3] Removing binary...${NC}"
BINARY="/usr/local/bin/idle_master"
if [ -f "$BINARY" ]; then
    rm -f "$BINARY"
    echo "Removed $BINARY"
else
    echo "Binary not found (already removed)"
fi

# Reload systemd
su - "$REAL_USER" -c "systemctl --user daemon-reload 2>/dev/null"

echo -e "\n${GREEN}Uninstall complete!${NC}"
