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

# ---------- OS DETECTION (UBUNTU + DEBIAN) ----------
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        # Check if ID is ubuntu OR debian
        if [[ "$ID" == "ubuntu" || "$ID" == "debian" ]]; then
            echo -e "${GREEN}Detected OS: $NAME ($ID)${NC}"
        else
            echo -e "${RED}Error: Your OS is $ID. This script is only for Ubuntu or Debian!${NC}"
            exit 1
        fi
    else
        echo -e "${RED}Error: OS detection failed. Cannot confirm OS type.${NC}"
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
echo -e "${GREEN}      PTERODACTYL EXTRA BLUEPRINT EXTENTION INSTALLER (WITHOUT SFTP) ${NC}"
echo "======================================="
echo
} 

# ---------- EXECUTION ----------
detect_os
banner 

echo -e "${YELLOW}Starting Pterodactyl Extension Installation...${NC}" 

# Move to directory and start installation
cd /var/www/pterodactyl || { echo -e "${RED}Pterodactyl directory not found!${NC}"; exit 1; } 

# Update and install dependencies
apt update -y && apt install git unzip -y 

# Clone repository
echo -e "${YELLOW}Downloading extensions...${NC}"
git clone https://github.com/sdgamer8263-sketch/pterodactyl_extention.git temp_ext

# --- SELECTION MENU START ---
cd temp_ext || { echo -e "${RED}Failed to access download directory!${NC}"; exit 1; }

# Find all .blueprint files
files=(*.blueprint)

# Check if any files found
if [ ${#files[@]} -eq 0 ]; then
    echo -e "${RED}No .blueprint files found in the repository!${NC}"
    cd ..
    rm -rf temp_ext
    exit 1
fi

echo -e "\n${CYAN}Available Extensions:${NC}"
# List files with numbers
for i in "${!files[@]}"; do
    echo -e "${GREEN}[$((i+1))]${NC} ${files[$i]}"
done

echo -e "\n${YELLOW}How would you like to install?${NC}"
echo -e "  - Type a single number (e.g., ${CYAN}1${NC})"
echo -e "  - Type multiple numbers separated by commas (e.g., ${CYAN}1,3,5${NC})"
echo -e "  - Type ${CYAN}all${NC} to install everything"
echo
read -p "Enter your choice: " choice

selected_files=()

if [[ "$choice" == "all" ]]; then
    echo -e "${GREEN}Selected all extensions.${NC}"
    selected_files=("${files[@]}")
else
    # Split by comma
    IFS=',' read -r -a indices <<< "$choice"
    for index in "${indices[@]}"; do
        # Convert to 0-based index
        idx=$((index-1))
        # Validate index
        if [[ -n "${files[$idx]}" ]]; then
            selected_files+=("${files[$idx]}")
        else
            echo -e "${RED}Warning: Invalid selection number '$index', skipping...${NC}"
        fi
    done
fi

# Check if selection is empty
if [ ${#selected_files[@]} -eq 0 ]; then
    echo -e "${RED}No valid extensions selected. Exiting.${NC}"
    cd ..
    rm -rf temp_ext
    exit 1
fi

# Install (Copy) files
echo -e "\n${YELLOW}Installing selected extensions...${NC}"
for file in "${selected_files[@]}"; do
    echo -e " -> Copying ${CYAN}$file${NC}..."
    cp "$file" ../
done

cd ..
rm -rf temp_ext
# --- SELECTION MENU END ---

# Permissions
chown -R www-data:www-data /var/www/pterodactyl
chmod -R 755 /var/www/pterodactyl 

# Optimization
php artisan migrate --force
php artisan optimize:clear
systemctl restart nginx 

echo -e "${GREEN}Pterodactyl extension setup complete!${NC}" 

# Running the blueprint addon installer
echo -e "${CYAN}Running Blueprint Addon Installer...${NC}"
# Note: Using 'yes' to pipe into the installer if it asks for confirmation
yes | bash <(curl -fsSL https://raw.githubusercontent.com/hopingboyz/blueprint/main/addon-installer.sh) 

echo -e "\n${GREEN}Installation complete! Ab flex karo 😎${NC}"
