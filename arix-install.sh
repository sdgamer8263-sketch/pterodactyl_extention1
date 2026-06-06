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
# HIDDEN LICENSE KEY (Encoded)
# ==========================================
_KEY="\x6b\x39\x23\x7a\x50\x2b\x71\x7a\x77\x21\x52\x74\x37"

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

# Required packages taaki unzip karte waqt error na aaye
echo -e "${CYAN}-> Checking required packages...${NC}"
apt-get update -y > /dev/null 2>&1
apt-get install -y unzip curl > /dev/null 2>&1

cd /var/www/pterodactyl || { echo -e "${RED}Error: /var/www/pterodactyl folder not found!${NC}"; exit 1; }

# ==========================================
# PHASE 1: ARIX THEME PROCESS 
# ==========================================
echo -e "${GREEN}-------------------------------------------${NC}"
echo -e "${GREEN}🎨 STARTING PHASE 1: ARIX THEME PROCESS     ${NC}"
echo -e "${GREEN}-------------------------------------------${NC}"

# Yaha progress bar show karega taaki aapko lage na ki screen hang hui hai
echo -e "${CYAN}-> Downloading Arix Theme (Please wait, progress bar below)...${NC}"
curl -# -L -o pterodactyl.zip https://raw.githubusercontent.com/sdgamer8263-sketch/pterodactyl_extention1/main/pterodactyl.zip

echo -e "${CYAN}-> Extracting files...${NC}"
unzip -o pterodactyl.zip > /dev/null 2>&1

# FIX: Nested folder problem
if [ -d "pterodactyl" ]; then
    cp -rf pterodactyl/* ./
    rm -rf pterodactyl
fi
rm pterodactyl.zip # Cleanup

echo -e "${CYAN}-> Running Arix installer (License Key auto-filling silently)...${NC}"
echo -e "$_KEY" | php artisan arix install > /dev/null 2>&1

echo -e "${CYAN}-> Building the Pterodactyl Panel (Takes 2-5 minutes, DO NOT CLOSE)...${NC}"
yarn add xterm-addon-unicode11 > /dev/null 2>&1
yarn build

# ==========================================
# PHASE 2: PERMISSIONS & CACHE FIXES
# ==========================================
set +e
echo -e "${CYAN}-> Fixing permissions and preventing 'File not found' errors...${NC}"

curl -sL https://raw.githubusercontent.com/pterodactyl/panel/master/public/index.php -o public/index.php > /dev/null 2>&1

chown -R www-data:www-data /var/www/pterodactyl 2>/dev/null
chown -R nginx:nginx /var/www/pterodactyl 2>/dev/null

find /var/www/pterodactyl -type d -exec chmod 755 {} \;
find /var/www/pterodactyl -type f -exec chmod 644 {} \;
chmod -R 775 storage/* bootstrap/cache/

chown -R www-data:www-data /var/www/pterodactyl/*

echo -e "${GREEN}=======================================================${NC}"
echo -e "${GREEN}  Installation Complete! 🎉 SDGAMER, Your panel is ready!${NC}"
echo -e "${GREEN}=======================================================${NC}"
