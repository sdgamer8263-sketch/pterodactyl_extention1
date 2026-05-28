# ==========================================
# Function: Fetch & Prepare List
# ==========================================
fetch_and_prepare_list() {
    echo -e "\n${INFO} ${CYAN}Fetching available extensions from the cloud... ☁️${RESET}"
    
    # added &per_page=100 to get all new uploaded files
    local API_EX="${API_URL_EX}&per_page=100"
    local API_TR="${API_URL_TR}&per_page=100"

    if [ -n "$GITHUB_TOKEN" ] && [ "$GITHUB_TOKEN" != "ghp_YOUR_NEW_TOKEN_HERE" ]; then
        FILES_JSON_EX=$(curl -s -H "Authorization: token $GITHUB_TOKEN" "$API_EX")
        FILES_JSON_TR=$(curl -s -H "Authorization: token $GITHUB_TOKEN" "$API_TR")
    else
        FILES_JSON_EX=$(curl -s "$API_EX")
        FILES_JSON_TR=$(curl -s "$API_TR")
    fi

    # FIX: Changed FILES_JSON_TRR to FILES_JSON_TR
    if echo "$FILES_JSON_EX" | grep -q '"message":' || echo "$FILES_JSON_TR" | grep -q '"message":'; then
        echo -e "${ERROR} ${RED}Failed to fetch from GitHub API. Check repo details or Rate Limit. 🛑${RESET}"
        sleep 2
        return
    fi

    ALL_OPTIONS=()
    SORTED_OPTIONS=()

    # 1. Add Custom Script Options
    ALL_OPTIONS+=("Plugin Manager Addon|script|bash <(curl -s 'https://raw.githubusercontent.com/sdgamer8263-sketch/EXD/main/Plugin%20Manager%20Addon.sh')|none")
    ALL_OPTIONS+=("Pterodactyl Region|script|bash <(curl -s https://exeyarikus.info/pterodactyl-region/install)|none")
    ALL_OPTIONS+=("SAGA Auto Suspension|script|bash <(curl -s https://raw.githubusercontent.com/sdgamer8263-sketch/EXD/main/ac.sh)|none")
   
    # 2. Fetch .blueprint files
    if echo "$FILES_JSON_EX" | grep -q '"name":'; then
        while IFS= read -r line; do
            raw_name=$(echo "$line" | cut -d'|' -f1)
            url=$(echo "$line" | cut -d'|' -f2)
            clean_name="${raw_name%.blueprint}"
            clean_name="${clean_name^}"
            ALL_OPTIONS+=("$clean_name|blueprint|$url|$raw_name")
        done < <(echo "$FILES_JSON_EX" | jq -r '.[] | select(.name | endswith(".blueprint")) | "\(.name)|\(.download_url)"')
    fi

    # 3. Fetch .zip files
    if echo "$FILES_JSON_TR" | grep -q '"name":'; then
        while IFS= read -r line; do
            raw_name=$(echo "$line" | cut -d'|' -f1)
            url=$(echo "$line" | cut -d'|' -f2)
            clean_name="${raw_name%.zip}"
            clean_name="${clean_name^}"
            ALL_OPTIONS+=("$clean_name|zip|$url|$raw_name")
        done < <(echo "$FILES_JSON_TR" | jq -r '.[] | select(.name | endswith(".zip")) | "\(.name)|\(.download_url)"')
    fi

    IFS=$'\n' SORTED_OPTIONS=($(sort -f <<<"${ALL_OPTIONS[*]}"))
    unset IFS
    
    echo -e "${SUCCESS} ${GREEN}Extensions loaded successfully! 🎉${RESET}"
    sleep 1
}

