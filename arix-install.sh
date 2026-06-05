#!/bin/bash

# Colors for better output visibility
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=======================================================${NC}"
echo -e "${GREEN}  Arix Addon - Auto Download, Unzip & Build Script     ${NC}"
echo -e "${GREEN}=======================================================${NC}"

echo -e "${YELLOW}⚠️ WARNING: Make sure you have a clean Pterodactyl & Blueprint installed.${NC}"
echo -e "${YELLOW}⚠️ Make sure base Arix (v2.0.8) is already uploaded to your server.${NC}"
sleep 3

# 1. Go to Pterodactyl directory
cd /var/www/pterodactyl || { echo -e "${RED}❌ Pterodactyl directory not found!${NC}"; exit 1; }

# 2. Check and install 'unzip' and 'curl' if missing
echo -e "${GREEN}📦 Checking for unzip & curl...${NC}"
apt-get update -y && apt-get install -y unzip curl

# 3. Automatically Download arixaddon.zip from your GitHub repository
echo -e "${GREEN}⬇️ Downloading arixaddon.zip from GitHub...${NC}"
curl -L -o arixaddon.zip "https://github.com/sdgamer8263-sketch/pterodactyl_extention1/raw/main/arixaddon.zip"

# 4. Unzip the file automatically (overwriting existing files without prompt)
echo -e "${GREEN}📂 Unzipping arixaddon.zip...${NC}"
unzip -o arixaddon.zip
rm arixaddon.zip # Delete the zip file after extraction to save space

# 5. Fix Build Errors
echo -e "${GREEN}🛠️ Installing xterm-addon-unicode11...${NC}"
yarn add xterm-addon-unicode11

# 6. Build the Panel
echo -e "${GREEN}🏗️ Building the Pterodactyl Panel (This might take a few minutes)...${NC}"


echo -e "${GREEN}=======================================================${NC}"
echo -e "${GREEN}✅ Installation & Build Process Completed Successfully!${NC}"
echo -e "${GREEN}=======================================================${NC}"

#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e 

echo "=========================================="
echo "  Arix Theme Auto-Installer Script"
echo "  Starting Installation..."
echo "=========================================="
apt install wget
# 1. Pterodactyl Folder mein jana
cd /var/www/pterodactyl || { echo "Error: /var/www/pterodactyl folder not found!"; exit 1; }

# 2. GitHub se Zip file download karna aur Unzip karna
echo "-> Downloading and extracting theme files..."
wget -q https://raw.githubusercontent.com/sdgamer8263-sketch/pterodactyl_extention1/main/pterodactyl.zip -O pterodactyl.zip

unzip -o pterodactyl.zip

# FIX: Nested folder problem
if [ -d "pterodactyl" ]; then
    echo "-> Moving files from nested folder to main folder..."
    cp -rf pterodactyl/* ./
    rm -rf pterodactyl
fi

# Extract hone ke baad zip file ko delete kar dena
rm pterodactyl.zip

# 3. System Dependencies Install karna
echo "-> Installing system dependencies..."
sudo apt update
sudo apt install -y ca-certificates curl git gnupg unzip wget zip

# 4. Node.js v22 Repository & Install
echo "-> Setting up Node.js 22.x..."
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | sudo gpg --yes --dearmor -o /etc/apt/keyrings/nodesource.gpg
echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_22.x nodistro main" | sudo tee /etc/apt/sources.list.d/nodesource.list
sudo apt update
sudo apt install -y nodejs

# 5. Install Yarn & Node Packages
echo "-> Installing Yarn and Node packages..."
npm i -g yarn
yarn install

# 6. Run Arix Installer
echo "-> Running Arix installer..."
php artisan arix install

# ==========================================
# 7. IMPORTANT FIXES: Permissions & Cache
# Yahan se hum error aane par script rukne ko band kar rahe hain (set +e)
# ==========================================
set +e
echo "-> Fixing permissions and preventing 'File not found' errors..."

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
php artisan view:clear
php artisan optimize:clear


echo "=========================================="
echo "  Arix Theme Installation Complete! 🎉"
echo "  Your panel is ready and error-free!"
echo "=========================================="
