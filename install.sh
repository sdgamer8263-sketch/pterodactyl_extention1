#!/bin/bash

# ==========================================
# Configuration
# ==========================================
GITHUB_REPO="sdgamer8263-sketch/pterodactyl_extention1"
BRANCH="main"
FOLDER_PATH="ex"
API_URL="https://api.github.com/repos/${GITHUB_REPO}/contents/${FOLDER_PATH}?ref=${BRANCH}"
PTERODACTYL_DIR="/var/www/pterodactyl"
TRACKING_FILE="${PTERODACTYL_DIR}/.installed_blueprints"

# ==========================================
# Display SDGAMER Banner
# ==========================================
clear
cat << "EOF"
  _____  _____   _____          __  __  ______  _____  
 / ____||  __ \ / ____|   /\   |  \/  ||  ____||  __ \ 
| (___  | |  | | |  __   /  \  | \  / || |__   | |__) |
 \___ \ | |  | | | |_ | / /\ \ | |\/| ||  __|  |  _  / 
 ____) || |__| | |__| |/ ____ \| |  | || |____ | | \ \ 
|_____/ |_____/ \_____/_/    \_\_|  |_||______||_|  \_\

=======================================================
         Pterodactyl Blueprint Installer
=======================================================
EOF

# ==========================================
# Pre-flight Checks
# ==========================================
if [[ $EUID -ne 0 ]]; then
   echo -e "\e[31m[Error] This script must be run as root.\e[0m" 
   exit 1
fi

if [ ! -d "$PTERODACTYL_DIR" ]; then
    echo -e "\e[31m[Error] Pterodactyl directory ($PTERODACTYL_DIR) not found.\e[0m"
    exit 1
fi

# Ensure jq is installed for JSON parsing
if ! command -v jq &> /dev/null; then
    echo -e "\e[33m[Info] 'jq' is not installed. Installing it now...\e[0m"
    apt-get update -y -q && apt-get install -y jq -q
fi

# Ensure Blueprint is installed
if ! command -v blueprint &> /dev/null; then
    echo -e "\e[31m[Error] 'blueprint' command not found. Please install the Blueprint framework first.\e[0m"
    exit 1
fi

# Create tracking file if it doesn't exist
touch "$TRACKING_FILE"

# ==========================================
# Fetch Extensions
# ==========================================
echo -e "\n\e[36m[*] Fetching available extensions from GitHub...\e[0m"
FILES_JSON=$(curl -s "$API_URL")

if echo "$FILES_JSON" | grep -q '"message":'; then
    echo -e "\e[31m[Error] Failed to fetch from GitHub API. Check repo details or API limits.\e[0m"
    exit 1
fi

# Parse names and URLs
mapfile -t BLUEPRINT_NAMES < <(echo "$FILES_JSON" | jq -r '.[] | select(.name | endswith(".blueprint")) | .name')
mapfile -t BLUEPRINT_URLS < <(echo "$FILES_JSON" | jq -r '.[] | select(.name | endswith(".blueprint")) | .download_url')

if [ ${#BLUEPRINT_NAMES[@]} -eq 0 ]; then
    echo -e "\e[33m[Info] No .blueprint extensions found in the repository folder ($FOLDER_PATH).\e[0m"
    exit 1
fi

# ==========================================
# Display List
# ==========================================
echo -e "\n----------------------------------------"
echo -e " \e[1mAvailable Blueprint Extensions:\e[0m"
echo "----------------------------------------"
for i in "${!BLUEPRINT_NAMES[@]}"; do
    status="\e[37m[ ]\e[0m" # Default state
    # Check if installed
    if grep -Fxq "${BLUEPRINT_NAMES[$i]}" "$TRACKING_FILE"; then
        status="\e[32m[Installed]\e[0m" # Installed state (Green)
    fi
    echo -e "$((i+1)). $status ${BLUEPRINT_NAMES[$i]}"
done
echo "----------------------------------------"

# ==========================================
# Get User Input
# ==========================================
echo -e "\n\e[1mInstallation Options:\e[0m"
echo "Case 1: Type a single number (e.g., 1) to install only that specific extension."
echo "Case 2: Type comma-separated numbers (e.g., 1,2,3) to install multiple extensions at once."
echo "Case 3: Type 'all' to install every available extension."
echo ""
read -p "Enter your choice: " choice

# ==========================================
# Process Selection
# ==========================================
to_install=()

if [[ "${choice,,}" == "all" ]]; then
    for i in "${!BLUEPRINT_NAMES[@]}"; do
        to_install+=("$i")
    done
else
    # Parse comma separated values
    IFS=',' read -ra ADDR <<< "$choice"
    for i in "${ADDR[@]}"; do
        i=$(echo "$i" | xargs) # trim whitespace
        if [[ "$i" =~ ^[0-9]+$ ]] && [ "$i" -ge 1 ] && [ "$i" -le "${#BLUEPRINT_NAMES[@]}" ]; then
            to_install+=("$((i-1))")
        else
            echo -e "\e[31m[Warning] Invalid input: $i. Skipping.\e[0m"
        fi
    done
fi

if [ ${#to_install[@]} -eq 0 ]; then
    echo -e "\e[33m[Info] No valid extensions selected. Exiting.\e[0m"
    exit 0
fi

# ==========================================
# Installation Loop
# ==========================================
cd "$PTERODACTYL_DIR" || exit 1
installed_count=0

for index in "${to_install[@]}"; do
    name="${BLUEPRINT_NAMES[$index]}"
    url="${BLUEPRINT_URLS[$index]}"

    # Crucial: Skip if already installed
    if grep -Fxq "$name" "$TRACKING_FILE"; then
        echo -e "\n\e[33m[Skip] Extension '$name' is already installed.\e[0m"
        continue
    fi

    echo -e "\n----------------------------------------"
    echo -e "\e[36m[*] Downloading $name...\e[0m"
    wget -qO "$name" "$url"
    
    if [ $? -eq 0 ]; then
        echo -e "\e[36m[*] Installing $name via Blueprint...\e[0m"
        
        # Run standard blueprint installation
        blueprint -install "$name"
        
        if [ $? -eq 0 ]; then
            echo -e "\e[32m[Success] Installed $name.\e[0m"
            # Log as installed
            echo "$name" >> "$TRACKING_FILE"
            installed_count=$((installed_count+1))
        else
            echo -e "\e[31m[Error] Blueprint installation failed for $name.\e[0m"
        fi
        
        # Clean up downloaded zip/.blueprint file after install
        rm -f "$name"
    else
        echo -e "\e[31m[Error] Failed to download $name.\e[0m"
    fi
done

# ==========================================
# Post-Installation
# ==========================================
if [ "$installed_count" -gt 0 ]; then
    echo -e "\n======================================================="
    echo -e "\e[32m Successfully installed $installed_count new extension(s)!\e[0m"
    echo "======================================================="
    echo -e "\e[33mTo apply these changes to your panel, Blueprint needs to rebuild.\e[0m"
    read -p "Do you want to run 'blueprint -build' now? (y/n): " build_choice
    
    if [[ "${build_choice,,}" == "y" ]]; then
        echo -e "\e[36m[*] Running blueprint -build...\e[0m"
        blueprint -build
    fi
else
    echo -e "\n\e[33m[Info] No new extensions were installed.\e[0m"
fi
