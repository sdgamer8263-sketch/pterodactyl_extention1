#!/bin/bash

# -----------------------------------------------------
#  Blueprint Auto Installer
#  Clean UI • Animations • Stable Spinner • ASCII Art
# -----------------------------------------------------


# --- Colors for formatting ---
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# --- Function: SDGAMER Banner ---
show_banner() {
    clear
    echo -e "${CYAN}"
    echo "  ____  _____   ____    _    __  __ _____ ____  "
    echo " / ___||  _  \ / ___|  / \  |  \/  | ____|  _ \ "
    echo " \___ \| | | || |  _  / _ \ | |\/| |  _| | |_) |"
    echo "  ___) | |_| || |_| |/ ___ \| |  | | |___|  _ < "
    echo " |____/|_____/ \____/_/   \_\_|  |_|_____|_| \_\\"
    echo -e "${NC}"
    echo -e "${YELLOW}       Welcome to SDGAMER Panel Manager${NC}"
    echo "=================================================="
}
# Spinner Animation
spinner() {
    local pid=$1
    local delay=0.1
    local spin=(⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏)

    while kill -0 "$pid" 2>/dev/null; do
        for frame in "${spin[@]}"; do
            printf "\r${MAGENTA}Installing... ${frame}${RESET}"
            sleep $delay
        done
    done

    printf "\r${GREEN}✓ Done!${RESET}        \n"
}

# Run Banner
banner

echo -e "${YELLOW}🔍 Searching for .blueprint files...${RESET}"
sleep 1

# Detect blueprint files
mapfile -t FILES < <(ls *.blueprint 2>/dev/null)

if (( ${#FILES[@]} == 0 )); then
    echo -e "${RED}❌ No .blueprint files found!${RESET}"
    exit 1
fi

echo -e "${GREEN}✓ Found ${#FILES[@]} blueprint file(s):${RESET}"
echo ""

i=1
for file in "${FILES[@]}"; do
    echo -e "  ${CYAN}$i.${RESET} $file"
    ((i++))
done
echo ""

read -rp "$(echo -e ${YELLOW}'Do you want to install all blueprints? (y/n): '${RESET})" confirm

if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    echo -e "${RED}Cancelled.${RESET}"
    exit 0
fi

echo ""
echo -e "${BLUE}⚡ Starting installation...${RESET}"
echo ""

# Install loop
for f in "${FILES[@]}"; do
    echo -e "${CYAN}➡ Installing: ${MAGENTA}$f${RESET}"

    ( blueprint -install "$f" ) &
    installer_pid=$!

    spinner $installer_pid

    echo ""
done

echo -e "${GREEN}🎉 All blueprints installed successfully!${RESET}"
echo ""
echo -e "${BLUE}✨ Thank you for using Blueprint Installer!${RESET}"
echo ""
