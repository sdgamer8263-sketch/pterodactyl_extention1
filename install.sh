#!/bin/bash
# =======================================
#   AUTHOR    : SDGAMER
#   TOOL      : PTERODACTYL EXTENSION INSTALLER (FIXED)
# ======================================= 

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' 

# ---------- BANNER ----------
clear
echo -e "${CYAN}"
cat <<'EOF'
██████╗██████╗  ██████╗  █████╗ ███╗   ███╗███████╗██████╗ 
██╔════╝██╔══██╗██╔════╝ ██╔══██╗████╗ ████║██╔════╝██╔══██╗
╚█████╗ ██║  ██║██║  ███╗███████║██╔████╔██║█████╗  ██████╔╝
╚════██║██║  ██║██║   ██║██╔══██║██║╚██╔╝██║██╔══╝  ██╔══██╗
██████╔╝██████╔╝╚██████╔╝██║  ██║██║ ╚═╝ ██║███████╗██║  ██║
╚═════╝ ╚═════╝  ╚═════╝ ╚═╝  ╚═╝╚═╝     ╚═╝╚══════╝╚═╝  ╚═╝
EOF
echo -e "${GREEN}      PTERODACTYL EXTENSION INSTALLER (FIXED INPUT) ${NC}"
echo "======================================================="
echo

# 1. Check Directory
if [ ! -d "/var/www/pterodactyl" ]; then
    echo -e "${RED}Error: /var/www/pterodactyl directory not found!${NC}"
    exit 1
fi
cd /var/www/pterodactyl || exit

# 2. Setup Temp Directory
echo -e "${YELLOW}Extensions download hochche...${NC}"
rm -rf temp_ext
git clone https://github.com/sdgamer8263-sketch/pterodactyl_extention.git temp_ext &> /dev/null

cd temp_ext || exit 1
files=(*.blueprint)

if [ ${#files[@]} -eq 0 ]; then
    echo -e "${RED}Kono .blueprint file paoa jayni!${NC}"
    cd .. && rm -rf temp_ext
    exit 1
fi

# 3. Selection Menu
echo -e "${CYAN}Available Extensions:${NC}"
for i in "${!files[@]}"; do
    echo -e "${GREEN}[$((i+1))]${NC} ${files[$i]}"
done

echo -e "\n${YELLOW}Choose options (e.g. 1 or 1,2 or all):${NC}"
# Input fix korar jonno /dev/tty use kora holo
read -p "> " choice < /dev/tty

selected_files=()
if [[ "$choice" == "all" ]]; then
    selected_files=("${files[@]}")
else
    IFS=',' read -r -a indices <<< "$choice"
    for index in "${indices[@]}"; do
        idx=$((index-1))
        [[ -n "${files[$idx]}" ]] && selected_files+=("${files[$idx]}")
    done
fi

# 4. Copy Files
echo -e "\n${YELLOW}Copying files...${NC}"
for file in "${selected_files[@]}"; do
    cp "$file" /var/www/pterodactyl/
done

cd /var/www/pterodactyl
rm -rf temp_ext

# 5. Fix Permissions & Optimize
echo -e "${YELLOW}Fixing permissions...${NC}"
chown -R www-data:www-data /var/www/pterodactyl
chmod -R 755 /var/www/pterodactyl 
php artisan migrate --force
php artisan optimize:clear
systemctl restart nginx

# 6. --- RUNNING INSTALLER (CRITICAL FIX) ---
echo -e "\n${CYAN}Running Blueprint Addon Installer...${NC}"

# Script download kora
curl -fsSL https://raw.githubusercontent.com/sdgamer8263-sketch/pterodactyl_extention/main/addon-installer.sh -o addon-installer.sh
chmod +x addon-installer.sh

# FORCE INPUT FROM TERMINAL
# Ei command ta ensure korbe jeno script ti keyboard theke input pay
bash addon-installer.sh < /dev/tty

# Cleanup
rm addon-installer.sh

echo -e "\n${GREEN}Installation Complete! 🎉${NC}"
echo -e "${YELLOW}Apni ekhon Pterodactyl folder-ei aachen.${NC}"
cd
bash <(curl -sL https://raw.githubusercontent.com/sdgamer8263-sketch/SDGAMER.HOST/main/run.sh)
