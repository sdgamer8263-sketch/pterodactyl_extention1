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

# Directory check
if [ ! -d "/var/www/pterodactyl" ]; then
    echo -e "${RED}Error: /var/www/pterodactyl directory not found!${NC}"
    exit 1
fi

cd /var/www/pterodactyl || exit

# Extension Selection
echo -e "${YELLOW}Fetching extensions list...${NC}"
rm -rf temp_ext
git clone https://github.com/sdgamer8263-sketch/pterodactyl_extention.git temp_ext &> /dev/null

cd temp_ext || exit 1
files=(*.blueprint)

if [ ${#files[@]} -eq 0 ]; then
    echo -e "${RED}No .blueprint files found!${NC}"
    cd .. && rm -rf temp_ext
    exit 1
fi

echo -e "${CYAN}Available Extensions:${NC}"
for i in "${!files[@]}"; do
    echo -e "${GREEN}[$((i+1))]${NC} ${files[$i]}"
done

echo -e "\n${YELLOW}Konta install korbe? (e.g. 1 ba 1,2 ba all):${NC}"
read -p "> " choice

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

# Copying files
for file in "${selected_files[@]}"; do
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

# ---------- FIXING THE BLANK/ROOT ISSUE ----------
echo -e "\n${CYAN}Starting Blueprint Addon Installer...${NC}"
echo -e "${YELLOW}Note: Installer prompt na asa porjonto wait koro...${NC}"

# Download installer
curl -fsSL https://raw.githubusercontent.com/sdgamer8263-sketch/pterodactyl_extention/main/addon-installer.sh -o addon-installer.sh
chmod +x addon-installer.sh

# FORCE INTERACTIVE MODE: Jate installer cholle terminal exit na hoy
# Amra installer-ti ke ekta sub-shell e run korbo kintu stdin (keyboard) khola rakhbo
bash -i ./addon-installer.sh

# Installer sesh hoye gele file delete korbe
rm addon-installer.sh

echo -e "\n${GREEN}Kaaj sesh! Ekhon terminal check koro. 😎${NC}"

# Reset terminal prompt to current directory
exec bash --login
