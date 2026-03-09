#!/bin/bash
# =======================================
#   AUTHOR    : SDGAMER
#   TOOL      : PTERODACTYL EXTENSION INSTALLER (MENU LOOP FIX)
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
echo -e "${GREEN}      PTERODACTYL EXTENSION INSTALLER (AUTO-MENU) ${NC}"
echo "======================================================="
echo

# 1. Check Directory
if [ ! -d "/var/www/pterodactyl" ]; then
    echo -e "${RED}Error: /var/www/pterodactyl directory not found!${NC}"
    exit 1
fi
cd /var/www/pterodactyl || exit

# 2. Setup Temp Directory
echo -e "${YELLOW}Downloading Extension Files...${NC}"
rm -rf temp_ext
git clone https://github.com/sdgamer8263-sketch/pterodactyl_extention.git temp_ext &> /dev/null

cd temp_ext || exit 1
files=(*.blueprint)

if [ ${#files[@]} -eq 0 ]; then
    echo -e "${RED}Kono blueprint file paoa jayni!${NC}"
    cd .. && rm -rf temp_ext
    exit 1
fi

# 3. Selection Menu
echo -e "${CYAN}Available Extensions:${NC}"
for i in "${!files[@]}"; do
    echo -e "${GREEN}[$((i+1))]${NC} ${files[$i]}"
done

echo -e "\n${YELLOW}Select extensions (e.g. 1 or all):${NC}"
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
echo -e "\n${YELLOW}Installing Files...${NC}"
for file in "${selected_files[@]}"; do
    cp "$file" /var/www/pterodactyl/
done

cd /var/www/pterodactyl
rm -rf temp_ext

# 5. Permissions & Optimize
echo -e "${YELLOW}Applying Permissions & Optimizing...${NC}"
chown -R www-data:www-data /var/www/pterodactyl
chmod -R 755 /var/www/pterodactyl 
php artisan migrate --force
php artisan optimize:clear
systemctl restart nginx

# 6. --- MENU LOOP FIX ---
echo -e "\n${CYAN}Downloading Main Menu...${NC}"
curl -fsSL https://raw.githubusercontent.com/sdgamer8263-sketch/pterodactyl_extention/main/addon-installer.sh -o addon-installer.sh
chmod +x addon-installer.sh

# Infinite loop to keep returning to the menu
while true; do
    echo -e "\n${GREEN}Opening Main Menu...${NC}"
    sleep 2
    
    # Run the menu script
    bash addon-installer.sh < /dev/tty
    
    echo -e "\n${YELLOW}-----------------------------------${NC}"
    echo -e "${CYAN}Menu theke beriye esechen.${NC}"
    echo -e "${YELLOW}Abar ki Menu-te fire jete chan? (y/n)${NC}"
    read -p "Choice [y]: " retry < /dev/tty
    
    # Default to 'y' if user just presses Enter
    retry=${retry:-y}

    if [[ "$retry" != "y" && "$retry" != "Y" ]]; then
        echo -e "${RED}Exiting Installer. Bye!${NC}"
        break
    fi
done

# Cleanup
rm addon-installer.sh
exec bash
