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

# ==========================================
# CRITICAL FIX: Removing Conflicting GPG Keys
# ==========================================
echo -e "${CYAN}-> Fixing previous Node.js GPG conflicts...${NC}"
sudo rm -f /etc/apt/sources.list.d/nodesource.list
sudo rm -f /etc/apt/keyrings/nodesource.gpg
sudo rm -f /usr/share/keyrings/nodesource.gpg

# 1. System Dependencies Install karna
echo -e "${CYAN}-> Installing system dependencies...${NC}"
sudo apt update
sudo apt install -y ca-certificates curl git gnupg unzip wget zip

# 2. Node.js v22 Repository & Install
echo -e "${CYAN}-> Setting up Node.js 22.x...${NC}"
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
sudo apt-get install -y nodejs

# 3. Install Yarn
echo -e "${CYAN}-> Installing Yarn...${NC}"
npm i -g yarn

# 4. Pterodactyl Folder mein jana
cd /var/www/pterodactyl || { echo -e "${RED}Error: /var/www/pterodactyl folder not found!${NC}"; exit 1; }


# ==========================================
# PHASE 1: ARIX ADDON PROCESS (PEHLE YEH HOGA)
# ==========================================
echo -e "${GREEN}-------------------------------------------${NC}"
echo -e "${GREEN}📦 STARTING PHASE 1: ARIX ADDON PROCESS     ${NC}"
echo -e "${GREEN}-------------------------------------------${NC}"

echo -e "${CYAN}-> Downloading and extracting Arix Addon...${NC}"
curl -L -o arixaddon.zip "https://github.com/sdgamer8263-sketch/pterodactyl_extention1/raw/main/arixaddon.zip"
unzip -o arixaddon.zip
rm arixaddon.zip # Cleanup

echo -e "${CYAN}-> Installing Node packages & Addon dependencies...${NC}"
yarn add xterm-addon-unicode11
curl -sL https://deb.nodesource.com/setup_22.x | sudo -E bash - 
sudo apt install -y nodejs
npm i -g yarn # Install Yarn

cd /var/www/pterodactyl
yarn # Installs panel build dependencies
cd /var/www/pterodactyl
export NODE_OPTIONS=--openssl-legacy-provider # for NodeJS v17+
yarn build:production # Build panel

# ==========================================
# PHASE 2: ARIX THEME PROCESS (ESKE BAAD YEH HOGA)
# ==========================================
echo -e "${GREEN}-------------------------------------------${NC}"
echo -e "${GREEN}🎨 STARTING PHASE 2: ARIX THEME PROCESS     ${NC}"
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
php artisan arix install

echo -e "${CYAN}-> Building the Pterodactyl Panel (This might take a few minutes)...${NC}"
yarn build:production


# ==========================================
# PHASE 3: PERMISSIONS & CACHE FIXES
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

echo -e "${GREEN}=======================================================${NC}"
echo -e "${GREEN}  Installation Complete! 🎉 SDGAMER, Your panel is ready!${NC}"
echo -e "${GREEN}=======================================================${NC}"
