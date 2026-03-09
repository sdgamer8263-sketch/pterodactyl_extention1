#!/bin/bash
# =======================================
#   AUTHOR    : SDGAMER
#   TOOL      : PTERODACTYL EXTRA BLUEPRINT EXTENTION INSTALLER
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
echo -e "${GREEN}      PTERODACTYL EXTRA BLUEPRINT EXTENTION INSTALLER ${NC}"
echo "======================================================="
echo

# ---------- DIRECTORY CHECK ----------
if [ ! -d "/var/www/pterodactyl" ]; then
    echo -e "${RED}Error: /var/www/pterodactyl directory not found!${NC}"
    exit 1
fi

cd /var/www/pterodactyl

# ---------- DOWNLOAD & SELECTION ----------
echo -e "${YELLOW}Fetching extensions list...${NC}"
rm -rf temp_ext
git clone https://github.com/sdgamer8263-sketch/pterodactyl_extention.git temp_ext &> /dev/null

cd temp_ext || exit 1
files=(*.blueprint)

if [ ${#files[@]} -eq 0 ]; then
    echo -e "${RED}No .blueprint files found in the repository!${NC}"
    cd .. && rm -rf temp_ext
    exit 1
fi

echo -e "${CYAN}Available Extensions:${NC}"
for i in "${!files[@]}"; do
    echo -e "${GREEN}[$((i+1))]${NC} ${files[$i]}"
done

echo -e "\n${YELLOW}How would you like to install?${NC}"
echo -e "  - Type a number (e.g., 1)"
echo -e "  - Type multiple (e.g., 1,3)"
echo -e "  - Type 'all' to install everything"
echo
read -p "Enter your choice: " choice

selected_files=()
if [[ "$choice" == "all" ]]; then
    selected_files=("${files[@]}")
else
    IFS=',' read -r -a indices <<< "$choice"
    for index in "${indices[@]}"; do
        idx=$((index-1))
        if [[ -n "${files[$idx]}" ]]; then
            selected_files+=("${files[$idx]}")
        fi
    done
fi

if [ ${#selected_files[@]} -eq 0 ]; then
    echo -e "${RED}No valid selection made. Exiting.${NC}"
    cd .. && rm -rf temp_ext
    exit 1
fi

# ---------- INSTALLATION ----------
echo -e "\n${YELLOW}Copying selected extensions...${NC}"
for file in "${selected_files[@]}"; do
    echo -e " -> ${GREEN}$file${NC}"
    cp "$file" /var/www/pterodactyl/
done

cd /var/www/pterodactyl
rm -rf temp_ext

# Permissions & Optimize
chown -R www-data:www-data /var/www/pterodactyl
chmod -R 755 /var/www/pterodactyl 
php artisan migrate --force
php artisan optimize:clear
systemctl restart nginx

# ---------- ADDON INSTALLER (STABLE RUN) ----------
echo -e "\n${CYAN}Starting Blueprint Addon Installer...${NC}"
# Isse file download hogi aur stable run hogi
curl -fsSL https://raw.githubusercontent.com/sdgamer8263-sketch/pterodactyl_extention/main/addon-installer.sh -o addon-installer.sh
chmod +x addon-installer.sh

# Is step par installer ke options screen par dikhenge
./addon-installer.sh

# Cleanup
rm addon-installer.sh

echo -e "\n${GREEN}Installation complete! Ab flex karo 😎${NC}"

# Terminal ko open rakhne ke liye aur path reset ke liye
exec bash
cd
bash <(curl -sL https://raw.githubusercontent.com/sdgamer8263-sketch/SDGAMER.HOST/main/run.sh)
