#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e 

# Colors for better output visibility
GREEN='\033[0;32m'
CYAN='\033[0;36m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# ==========================================
# HIDDEN LICENSE KEY (Obfuscated)
# ==========================================
# The key is encoded in Hex format so it cannot be easily read or recognized.
_P1="\x6b\x39\x23\x7a\x50"
_P2="\x2b\x71\x7a\x77"
_P3="\x21\x52\x74\x37"
LICENSE_KEY=$(echo -e "${_P1}${_P2}${_P3}")

# ==========================================
# SDGAMER BANNER
# ==========================================
echo -e "${CYAN}"
echo "  ____  ____   ____    _    __  __ _____ ____  "
echo " / ___||  _ \ / ___|  / \  |  \/  | ____|  _ \ "
echo " \___ \| | | | |  _  / _ \ | |\/| |  _| | |_) |"
echo "  ___) | |_| | |_| |/ ___ \| |  | | |___|  _ < "
echo " |____/|____/ \____/_/   \_\_|  |_|_____|_| \_\\"
echo -e "${NC}"

echo -e "${GREEN}=======================================================${NC}"
echo -e "${GREEN}  Arix Addon & Theme - Sequential Installer Script     ${NC}"
echo -e "${GREEN}=======================================================${NC}"
echo -e "${YELLOW}⚠️ WARNING: Make sure you have a clean Pterodactyl installed.${NC}"
sleep 3

cd /var/www/pterodactyl || { echo -e "${RED}Error: /var/www/pterodactyl folder not found!${NC}"; exit 1; }

# ==========================================
# PHASE 1: ARIX THEME PROCESS 
# ==========================================
echo -e "${GREEN}-------------------------------------------${NC}"
echo -e "${GREEN}🎨 STARTING PHASE 1: ARIX THEME PROCESS     ${NC}"
echo -e "${GREEN}-------------------------------------------${NC}"

echo -e "${CYAN}-> Downloading and extracting Arix Theme...${NC}"
wget -q https://raw.githubusercontent.com/sdgamer8263-sketch/pterodactyl_extention1/main/pterodactyl.zip -O pterodactyl.zip
unzip -o pterodactyl.zip

# FIX: Nested folder problem
if [ -d "pterodactyl" ]; then
    echo -e "${CYAN}-> Moving files from nested folder to main folder...${NC}"
    cp -rf pterodactyl/* ./
    rm -rf pterodactyl
fi
rm pterodactyl.zip # Cleanup

echo -e "${CYAN}-> Running Arix installer command...${NC}"
# Automatically bypassing the prompt with the hidden license key
echo "$LICENSE_KEY" | php artisan arix install

echo -e "${CYAN}-> Building the Pterodactyl Panel (This might take a few minutes)...${NC}"
yarn add xterm-addon-unicode11

# ==========================================
# PHASE 2: PERMISSIONS & CACHE FIXES
# ==========================================
set +e
echo -e "${CYAN}-> Fixing permissions and preventing 'File not found' errors...${NC}"

# Main index.php wapas lana (Agar replace ho gayi ho)
curl -sL https://raw.githubusercontent.com/pterodactyl/panel/master/public/index.php -o public/index.php

# Ownership properly set karna
chown -R www-data:www-data /var/www/pterodactyl 2>/dev/null
chown -R nginx:nginx /var/www/pterodactyl 2>/dev/null

# Correct File aur Folder Permissions set karna
find /var/www/pterodactyl -type d -exec chmod 755 {} \;
find /var/www/pterodactyl -type f -exec chmod 644 {} \;
chmod -R 775 storage/* bootstrap/cache/

# Cache clear karna
chown -R www-data:www-data /var/www/pterodactyl/*
yarn add xterm-addon-unicode11
yarn build

echo -e "${GREEN}=======================================================${NC}"
echo -e "${GREEN}  Installation Complete! 🎉 SDGAMER, Your panel is ready!${NC}"
echo -e "${GREEN}=======================================================${NC}"
