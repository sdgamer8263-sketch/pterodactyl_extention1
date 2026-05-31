# 2. GitHub se Zip file download karna aur Unzip + Overwrite karna
echo "-> Downloading and extracting theme files..."
wget -q https://raw.githubusercontent.com/sdgamer8263-sketch/pterodactyl_extention1/main/pterodactyl.zip -O pterodactyl.zip

unzip -o pterodactyl.zip

# FIX: Agar files ek aur 'pterodactyl' folder mein chali gayi hain, toh unhe bahar nikal kar overwrite karna
if [ -d "pterodactyl" ]; then
    echo "-> Moving files from nested folder..."
    cp -r pterodactyl/* ./
    rm -rf pterodactyl
fi

# Extract hone ke baad zip file ko delete kar dena
rm pterodactyl.zip
