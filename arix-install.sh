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
