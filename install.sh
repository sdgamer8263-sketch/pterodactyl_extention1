#!/bin/bash

# ==========================================
# Configuration
# ==========================================
GITHUB_REPO="sdgamer8263-sketch/pterodactyl_extention1"
BRANCH="main"
FOLDER_PATH="ex"
API_URL="https://api.github.com/repos/${GITHUB_REPO}/contents/${FOLDER_PATH}?ref=${BRANCH}"
PTERODACTYL_DIR="/var/www/pterodactyl"

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

if ! command -v jq &> /dev/null; then
    echo -e "\e[33m[Info] 'jq' is not installed. Installing it now...\e[0m"
    apt-get update -y -q && apt-get install -y jq -q
fi

# ==========================================
# Function: Fetch & Prepare List
# ==========================================
fetch_and_prepare_list() {
    echo -e "\n\e[36m[*] Fetching available extensions from GitHub...\e[0m"
    FILES_JSON=$(curl -s "$API_URL")

    if echo "$FILES_JSON" | grep -q '"message":'; then
        echo -e "\e[31m[Error] Failed to fetch from GitHub API. Check repo details or API limits.\e[0m"
        sleep 2
        return
    fi

    # Reset Arrays
    ALL_OPTIONS=()
    SORTED_OPTIONS=()

    # 1. Add Custom Script Options
    ALL_OPTIONS+=("Plugin Manager Addon|script|bash <(curl -s 'https://raw.githubusercontent.com/sdgamer8263-sketch/EXD/main/Plugin%20Manager%20Addon.sh')|none")
    ALL_OPTIONS+=("Pterodactyl Region|script|bash <(curl -s https://exeyarikus.info/pterodactyl-region/install)|none")
    ALL_OPTIONS+=("SFTP Alias|script|bash <(curl -s https://raw.githubusercontent.com/sdgamer8263-sketch/EXD/main/sftp/sftp.sh)|none")

    # 2. Fetch and format .blueprint files
    mapfile -t BLUEPRINT_NAMES < <(echo "$FILES_JSON" | jq -r '.[] | select(.name | endswith(".blueprint")) | .name')
    mapfile -t BLUEPRINT_URLS < <(echo "$FILES_JSON" | jq -r '.[] | select(.name | endswith(".blueprint")) | .download_url')

    for i in "${!BLUEPRINT_NAMES[@]}"; do
        raw_name="${BLUEPRINT_NAMES[$i]}"
        url="${BLUEPRINT_URLS[$i]}"
        
        # Remove .blueprint extension & Capitalize first letter
        clean_name="${raw_name%.blueprint}"
        clean_name="${clean_name^}"
        
        ALL_OPTIONS+=("$clean_name|blueprint|$url|$raw_name")
    done

    # 3. Sort options alphabetically (A-Z)
    IFS=$'\n' SORTED_OPTIONS=($(sort <<<"${ALL_OPTIONS[*]}"))
    unset IFS
}

# Initial Fetch
fetch_and_prepare_list

# ==========================================
# Interactive Menu Loop
# ==========================================
while true; do
    clear
    cat << "EOF"
  _____  _____   _____          __  __  ______  _____  
 / ____||  __ \ / ____|   /\   |  \/  ||  ____||  __ \ 
| (___  | |  | | |  __   /  \  | \  / || |__   | |__) |
 \___ \ | |  | | | |_ | / /\ \ | |\/| ||  __|  |  _  / 
 ____) || |__| | |__| |/ ____ \| |  | || |____ | | \ \ 
|_____/ |_____/ \_____/_/    \_\_|  |_||______||_|  \_\

=======================================================
         Pterodactyl Addon & Blueprint Installer
=======================================================
EOF

    echo -e "\n----------------------------------------"
    echo -e " \e[1mAvailable Options (A-Z):\e[0m"
    echo "----------------------------------------"
    
    # Display Options
    count=1
    for opt in "${SORTED_OPTIONS[@]}"; do
        disp_name=$(echo "$opt" | cut -d'|' -f1)
        echo -e "\e[32m$count.\e[0m $disp_name"
        ((count++))
    done
    echo "----------------------------------------"
    echo -e "\e[33mR.\e[0m Refresh List (Fetch New Extensions)"
    echo -e "\e[31m0.\e[0m Exit"
    echo "----------------------------------------"

    read -p "Enter your choice: " choice

    # Exit Option
    if [[ "$choice" == "0" ]]; then
        echo -e "\n\e[36mExiting... Have a great day!\e[0m"
        exit 0
    fi

    # Refresh Option
    if [[ "${choice,,}" == "r" ]]; then
        fetch_and_prepare_list
        continue
    fi

    # Validation: Check if input is a valid number
    if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -ge "$count" ]; then
        echo -e "\n\e[31m[Invalid Input] Please enter a valid number or 'R' to refresh.\e[0m"
        sleep 2
        continue
    fi

    # Process Selection
    selected_index=$((choice-1))
    selected_data="${SORTED_OPTIONS[$selected_index]}"
    
    # Extract data from the selected string
    opt_name=$(echo "$selected_data" | cut -d'|' -f1)
    opt_type=$(echo "$selected_data" | cut -d'|' -f2)
    opt_target=$(echo "$selected_data" | cut -d'|' -f3)
    opt_filename=$(echo "$selected_data" | cut -d'|' -f4)

    echo -e "\n\e[36m[*] You selected: $opt_name\e[0m"
    echo "========================================"

    if [[ "$opt_type" == "script" ]]; then
        # Run standard bash script
        eval "$opt_target"
        
    elif [[ "$opt_type" == "blueprint" ]]; then
        # Install Blueprint
        cd "$PTERODACTYL_DIR" || exit 1
        echo -e "\e[36m[*] Downloading $opt_filename...\e[0m"
        wget -qO "$opt_filename" "$opt_target"
        
        if [ $? -eq 0 ]; then
            echo -e "\e[36m[*] Installing $opt_filename via Blueprint...\e[0m"
            blueprint -install "$opt_filename"
            
            # Clean up the downloaded file
            rm -f "$opt_filename"
            echo -e "\n\e[32m[Success] $opt_name installed successfully.\e[0m"
        else
            echo -e "\e[31m[Error] Failed to download $opt_filename.\e[0m"
        fi
    fi

    echo "========================================"
    read -p "Press Enter to return to the menu..." 
done

