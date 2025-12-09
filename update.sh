#!/bin/bash
# Run with sudo: sudo ./update.sh

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}=== Idle Master Update ===${NC}"

if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}Error: Run as root (sudo ./update.sh)${NC}"
  exit 1
fi

# Get the actual user (not root)
REAL_USER="${SUDO_USER:-$USER}"

# 1. Stop service
echo -e "\n${GREEN}[1/4] Stopping service...${NC}"
su - "$REAL_USER" -c "systemctl --user stop idle_master 2>/dev/null"

# 2. Rebuild
echo -e "\n${GREEN}[2/4] Rebuilding...${NC}"
make clean
if make; then
    echo "Build successful"
else
    echo -e "${RED}Build failed!${NC}"
    exit 1
fi

# 3. Install new binary
echo -e "\n${GREEN}[3/4] Installing...${NC}"
make install

# 4. Restart service
echo -e "\n${GREEN}[4/4] Restarting service...${NC}"
su - "$REAL_USER" -c "systemctl --user daemon-reload"
su - "$REAL_USER" -c "systemctl --user start idle_master"

echo -e "\n${GREEN}Update complete!${NC}"
echo "Check status: systemctl --user status idle_master"
