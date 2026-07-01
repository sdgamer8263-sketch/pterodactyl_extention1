#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e 

# Colors for better output visibility
GREEN='\033[0;32m'
CYAN='\033[0;36m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# ==========================================
# BANNER FUNCTION
# ==========================================
show_banner() {
    clear
    echo -e "${CYAN}"
    echo '    _    ____  _____  __  '
    echo '   / \  |  _ \|_ _\ \/ /  '
    echo '  / _ \ | |_) || | \  /   '
    echo ' / ___ \|  _ < | | /  \   '
    echo '/_/   \_\_| \_\___/_/\_\  '
    echo -e "${NC}"
    echo -e "${YELLOW}      POWERED BY SKA      ${NC}"
    echo ""
    echo -e "${GREEN}=======================================================${NC}"
    echo -e "${GREEN}  Arix Addon & Theme - Sequential Installer Script     ${NC}"
    echo -e "${GREEN}=======================================================${NC}"
    echo -e "${YELLOW}⚠️ WARNING: Make sure you have a clean Pterodactyl installed.${NC}"
    echo ""
}

# ==========================================
# SECURITY: LICENSE KEY CHECK FUNCTION
# ==========================================
verify_license() {
    # The actual key is encoded in Hex format.
    # New Key: ai9cU0$pJu4cY_Tk9#zP+qzw!Rt7
    _SECRET="\x61\x69\x39\x63\x55\x30\x24\x70\x4a\x75\x34\x63\x59\x5f\x54\x6b\x39\x23\x7a\x50\x2b\x71\x7a\x77\x21\x52\x74\x37"
    DECODED_SECRET=$(printf "%b" "$_SECRET")

    echo -e "\n${YELLOW}🔒 SECURITY CHECK: This Blueprint version requires a valid license key.${NC}"
    read -s -p "Enter your License Key: " USER_INPUT_KEY
    echo ""

    if [ "$USER_INPUT_KEY" != "$DECODED_SECRET" ]; then
        echo -e "${RED}❌ ERROR: Invalid License Key! Access Denied.${NC}"
        echo -e "${CYAN}Please contact SDGAMER/SKA to get a valid key.${NC}"
        sleep 2
        return 1 # Return failure
    else
        echo -e "${GREEN}✅ License Verified! Starting Installation...${NC}"
        sleep 2
        return 0 # Return success
    fi
}

DOWNLOAD_URL=""

# ==========================================
# MENU FUNCTIONS
# ==========================================
non_blueprint_menu() {
    while true; do
        show_banner
        echo -e "${CYAN}--- Arix Non Blueprint Version ---${NC}"
        echo "1) Arix v1.3.1"
        echo "2) Arix v2.0.8"
        echo "3) Arix v2.1.0"
        echo "4) Back to Main Menu"
        read -p "Select an option [1-4]: " nb_choice

        case $nb_choice in
            1)
                DOWNLOAD_URL="https://raw.githubusercontent.com/sdgamer8263-sketch/pterodactyl_extention1/main/sd/v131/pterodactyl.zip"
                break 2 # Breaks both inner and outer loops
                ;;
            2)
                DOWNLOAD_URL="https://raw.githubusercontent.com/sdgamer8263-sketch/pterodactyl_extention1/main/sd/v208/pterodactyl.zip"
                break 2
                ;;
            3)
                DOWNLOAD_URL="https://raw.githubusercontent.com/sdgamer8263-sketch/pterodactyl_extention1/main/sd/v210/pterodactyl.zip"
                break 2
                ;;
            4)
                break # Just breaks inner loop, returning to main menu
                ;;
            *)
                echo -e "${RED}Invalid option! Please try again.${NC}"
                sleep 1
                ;;
        esac
    done
}

blueprint_menu() {
    while true; do
        show_banner
        echo -e "${CYAN}--- Arix Blueprint Supported Version ---${NC}"
        echo "1) Arix v2.0.8"
        echo "2) Arix v2.1.0 [with Translation Pack]"
        echo "3) Back to Main Menu"
        read -p "Select an option [1-3]: " b_choice

        case $b_choice in
            1)
                if verify_license; then
                    DOWNLOAD_URL="https://raw.githubusercontent.com/sdgamer8263-sketch/pterodactyl_extention1/main/sd/av1/pterodactyl.zip"
                    break 2
                fi
                ;;
            2)
                if verify_license; then
                    DOWNLOAD_URL="https://raw.githubusercontent.com/sdgamer8263-sketch/pterodactyl_extention1/main/sd/av2/pterodactyl.zip"
                    break 2
                fi
                ;;
            3)
                break
                ;;
            *)
                echo -e "${RED}Invalid option! Please try again.${NC}"
                sleep 1
                ;;
        esac
    done
}

# ==========================================
# START: MENU SYSTEM
# ==========================================
while true; do
    show_banner
    echo -e "${CYAN}--- Select Arix Version Type ---${NC}"
    echo "a) Arix Non Blueprint Version"
    echo "b) Arix Blueprint Supported Version"
    echo "q) Quit Installer"
    read -p "Select an option [a/b/q]: " main_choice

    case $main_choice in
        a|A)
            non_blueprint_menu
            ;;
        b|B)
            blueprint_menu
            ;;
        q|Q)
            echo -e "${YELLOW}Exiting Installer...${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid option! Please try again.${NC}"
            sleep 1
            ;;
    esac
    
    # If a valid DOWNLOAD_URL is set from sub-menus, exit the menu system
    if [ -n "$DOWNLOAD_URL" ]; then
        break
    fi
done

# ==========================================
# REQUIREMENTS
# ==========================================
show_banner
echo -e "${CYAN}-> Checking required packages...${NC}"
apt-get update -y > /dev/null 2>&1
apt-get install -y unzip curl wget > /dev/null 2>&1

cd /var/www/pterodactyl || { echo -e "${RED}Error: /var/www/pterodactyl folder not found!${NC}"; exit 1; }

# ==========================================
# PHASE 1: ARIX THEME PROCESS 
# ==========================================
echo -e "${GREEN}-------------------------------------------${NC}"
echo -e "${GREEN}🎨 STARTING PHASE 1: ARIX THEME PROCESS     ${NC}"
echo -e "${GREEN}-------------------------------------------${NC}"

echo -e "${CYAN}-> Downloading Selected Arix Theme (Please wait)...${NC}"
curl -# -L -o pterodactyl.zip "$DOWNLOAD_URL"

echo -e "${CYAN}-> Extracting files...${NC}"
unzip -o pterodactyl.zip > /dev/null 2>&1

# FIX: Nested folder problem
if [ -d "pterodactyl" ]; then
    cp -rf pterodactyl/* ./
    rm -rf pterodactyl
fi
rm pterodactyl.zip # Cleanup

echo -e "${CYAN}-> Running Arix installer...${NC}"
# User apni Arix key khud enter karega yahan
php artisan arix install

echo -e "${CYAN}-> Building the Pterodactyl Panel (Takes 2-5 minutes, DO NOT CLOSE)...${NC}"
yarn add xterm-addon-unicode11 > /dev/null 2>&1
yarn build

# ==========================================
# PHASE 2: PERMISSIONS & CACHE FIXES
# ==========================================
set +e
echo -e "${CYAN}-> Fixing permissions and preventing 'File not found' errors...${NC}"

curl -sL https://raw.githubusercontent.com/pterodactyl/panel/master/public/index.php -o public/index.php > /dev/null 2>&1

chown -R www-data:www-data /var/www/pterodactyl 2>/dev/null
chown -R nginx:nginx /var/www/pterodactyl 2>/dev/null

find /var/www/pterodactyl -type d -exec chmod 755 {} \;
find /var/www/pterodactyl -type f -exec chmod 644 {} \;
chmod -R 775 storage/* bootstrap/cache/

chown -R www-data:www-data /var/www/pterodactyl/*
cd /var/www/pterodactyl 
yarn add xterm-addon-unicode11
yarn build
cd

echo -e "${GREEN}=======================================================${NC}"
echo -e "${GREEN}  Installation Complete! 🎉 Your Arix panel is ready!${NC}"
echo -e "${GREEN}=======================================================${NC}"
