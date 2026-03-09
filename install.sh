#!/bin/bash
# =======================================
#   AUTHOR    : SDGAMER
#   TOOL      : PTERODACTYL EXTRA BLUEPRINT EXTENTION INSTALLER
# ======================================= 

# ---------- COLORS ----------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' 

# ---------- OS DETECTION ----------
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        if [[ "$ID" == "ubuntu" || "$ID" == "debian" ]]; then
            echo -e "${GREEN}Detected OS: $NAME ($ID)${NC}"
        else
            echo -e "${RED}Error: Your OS is $ID. This script is only for Ubuntu or Debian!${NC}"
            exit 1
        fi
    else
        echo -e "${RED}Error: OS detection failed.${NC}"
        exit 1
    fi
} 

# ---------- BANNER ----------
banner() {
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
echo "======================================="
echo
} 

# ---------- EXECUTION ----------
detect_os
banner 

echo -e "${YELLOW}Starting Pterodactyl Extension Installation...${NC}" 

# Move to directory
cd /var/www/pterodactyl || { echo -e "${RED}Pterodactyl directory not found!${NC}"; exit 1; } 

# Update and install dependencies
apt update -y && apt install git unzip curl -y 

# Clone repository
echo -e "${YELLOW}Downloading extensions...${NC}"
rm -rf temp_ext # Purge old temp if exists
git clone https://github.com/sdgamer8263-sketch/pterodactyl_extention.git temp_ext

# --- SELECTION MENU START ---
cd temp_ext || { echo -e "${RED}Failed to access download directory!${NC}"; exit 1; }

files=(*.blueprint)

if [ ${#files[@]} -eq 0 ]; then
    echo -e "${RED}No .blueprint files found!${NC}"
    cd ..
    rm -rf temp_ext
    exit 1
fi

echo -e "\n${CYAN}Available Extensions:${NC}"
for i in "${!files[@]}"; do
    echo -e "${GREEN}[$((i+1))]${NC} ${files[$i]}"
done

echo -e "\n${YELLOW}How would you like to install?${NC}"
echo -e "  - Single number (e.g., 1)"
echo -e "  - Multiple numbers (e.g., 1,3,5)"
echo -e "  - Type 'all' for everything"
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
    echo -e "${RED}No valid selection. Exiting.${NC}"
    cd ..
    rm -rf temp_ext
    exit 1
fi

echo -e "\n${YELLOW}Installing selected extensions...${NC}"
for file in "${selected_files[@]}"; do
    echo -e " -> Copying ${CYAN}$file${NC}..."
    cp "$file" ../
done

cd ..
rm -rf temp_ext
# --- SELECTION MENU END ---

# Fix Permissions
echo -e "${YELLOW}Applying permissions...${NC}"
chown -R www-data:www-data /var/www/pterodactyl
chmod -R 755 /var/www/pterodactyl 

# Optimization
echo -e "${YELLOW}Optimizing Pterodactyl...${NC}"
php artisan migrate --force
php artisan optimize:clear
systemctl restart nginx

# --- FIX: BLANK TERMINAL ISSUE ---
# 'yes' pipe kora bondho kora hoyeche jate installer interactive thake
echo -e "\n${CYAN}Running Blueprint Addon Installer...${NC}"
# Script download kore manually run kora hocche jate terminal hang na kore
curl -fsSL https://raw.githubusercontent.com/sdgamer8263-sketch/pterodactyl_extention/main/addon-installer.sh -o addon-installer.sh
bash addon-installer.sh
rm addon-installer.sh

echo -e "\n${GREEN}Installation complete! Ab flex karo 😎${NC}"

# Shell refresh korar jonno
exec $SHELL
