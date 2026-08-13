#!/bin/bash

# Ensure script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (sudo bash install.sh)"
  exit 1
fi

PTERODACTYL_DIR="/var/www/pterodactyl"
ADDON_URL="https://raw.githubusercontent.com/sdgamer8263-sketch/pterodactyl_extention1/main/addon.zip"

echo "=================================================="
echo "Starting Pterodactyl Minecraft Addon Automated Installer"
echo "=================================================="

# 1. Auto-download and Unzip Addon in Pterodactyl Root Directory
echo "[+] Downloading addon.zip from repository..."
cd /tmp
wget -O addon.zip "$ADDON_URL"

if [ -f "addon.zip" ]; then
    echo "[+] Unzipping addon.zip to $PTERODACTYL_DIR..."
    unzip -o addon.zip -d "$PTERODACTYL_DIR"
    rm -f addon.zip
else
    echo "[-] Error: Could not download addon.zip. Please check the URL."
    exit 1
fi

cd "$PTERODACTYL_DIR"

# 2. Edit config/services.php
echo "[+] Updating config/services.php..."
SERVICES_PHP="config/services.php"
if grep -q "curseforge" "$SERVICES_PHP"; then
    echo "[*] Curseforge config already exists. Skipping."
else
    # Appending the configuration before the last ];
    sed -i '$d' "$SERVICES_PHP"
    cat <<EOF >> "$SERVICES_PHP"
    'curseforge' => [
        'api_key' => env('CURSEFORGE_API_KEY'),
    ],
];
EOF
fi

# 3. Edit routes/api-client.php
echo "[+] Updating routes/api-client.php..."
API_CLIENT="routes/api-client.php"
if grep -q "api-mcpack.php" "$API_CLIENT"; then
    echo "[*] API mcpack route already exists. Skipping."
else
    # Replacing the last }); with the include and })
    sed -i '$d' "$API_CLIENT"
    cat <<EOF >> "$API_CLIENT"
include __DIR__.'/api-mcpack.php';
});
EOF
fi

# 4. Install Dependencies & Build Assets
echo "[+] Installing Node.js, Yarn, and building panel assets..."
cd "$PTERODACTYL_DIR"

curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -
apt install -y nodejs
npm i -g yarn
yarn

php artisan down
composer dump-autoload
php artisan migrate --force
export NODE_OPTIONS=--openssl-legacy-provider
yarn build:production

# 5. Clear Caches & Optimize
echo "[+] Clearing caches and optimizing..."
php artisan cache:clear
php artisan view:clear
php artisan config:clear
php artisan route:clear

chown -R www-data:www-data /var/www/pterodactyl/*
chmod -R 755 storage/* bootstrap/cache

php artisan queue:restart
php artisan optimize
systemctl restart pteroq.service
php artisan up

echo "=================================================="
echo "Installation Completed Successfully!"
echo "=================================================="

