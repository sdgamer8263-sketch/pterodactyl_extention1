#!/bin/bash
set -e 

API_URL="http://78.154.103.27:13915/api/verify" 
ADDON_URL="https://github.com/nobita329/Nobita-Cloud/raw/refs/heads/main/thame/Extension"

RED='\033[1;31m'; GREEN='\033[1;32m'; BLUE='\033[1;34m'; CYAN='\033[1;36m'; MAGENTA='\033[1;35m'; YELLOW='\033[1;33m'; WHITE='\033[1;37m'; NC='\033[0m'

info() { echo -e "${BLUE}[ℹ] ${WHITE}$1${NC}"; }
success() { echo -e "${GREEN}[✔] ${WHITE}$1${NC}"; }
warning() { echo -e "${YELLOW}[⚠] ${WHITE}$1${NC}"; }
error() { echo -e "${RED}[✖] ${WHITE}$1${NC}"; }
step() { echo -e "\n${MAGENTA}➤ ${CYAN}Step $1: ${WHITE}$2${NC}"; } 

spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    while [ "$(ps a | awk '{print $1}' | grep -w $pid)" ]; do
        local temp=${spinstr#?}
        printf "\r${MAGENTA} [%c] ${WHITE}Working... Please wait${NC}" "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
    done
    printf "\r\033[K"
} 

typewriter() {
    local text="$1"
    local delay=0.015
    for (( i=0; i<${#text}; i++ )); do
        echo -ne "${text:$i:1}"
        sleep $delay
    done
    echo ""
} 

show_banner() {
    clear
    echo -e "${MAGENTA}"
    echo '    █████╗ ██████╗ ██╗██╗  ██╗'
    echo '   ██╔══██╗██╔══██╗██║╚██╗██╔╝'
    echo '   ███████║██████╔╝██║ ╚███╔╝ '
    echo '   ██╔══██║██╔══██╗██║ ██╔██╗ '
    echo '   ██║  ██║██║  ██║██║██╔╝ ██╗'
    echo '   ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝╚═╝  ╚═╝'
    echo -e "${CYAN} ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ${NC}"
    typewriter "      Advanced Theme & Addon Installer"
    echo -e "${CYAN} ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ${NC}\n"
} 

DOWNLOAD_URL=""; LICENSE_TYPE=""; LICENSE_VERSION=""; ACTION=""; LICENSE_VALID="false"

check_dependencies() {
    info "Verifying Node.js, Yarn, and Python requirements..."
    set +e
    if command -v node >/dev/null 2>&1; then
        NODE_VER=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
        if [ "$NODE_VER" -lt 22 ]; then
            (curl -fsSL https://deb.nodesource.com/setup_22.x | bash - > /dev/null 2>&1 && apt-get install -y nodejs > /dev/null 2>&1) & spinner $!
        fi
    else
        (curl -fsSL https://deb.nodesource.com/setup_22.x | bash - > /dev/null 2>&1 && apt-get install -y nodejs > /dev/null 2>&1) & spinner $!
    fi
    if ! command -v yarn >/dev/null 2>&1; then
        (npm install -g yarn > /dev/null 2>&1) & spinner $!
    fi
    if ! command -v python3 >/dev/null 2>&1; then
        (apt-get update -y > /dev/null 2>&1 && apt-get install -y python3 > /dev/null 2>&1) & spinner $!
    fi
    set -e
} 

verify_license() {
    local TYPE_REQ=$1
    local VERSION_REQ=$2
    echo -e "${CYAN}┌──────────────────────────────────────────────┐${NC}"
    echo -e "${CYAN}│${YELLOW}         🔒 SECURITY VERIFICATION REQUIRED    ${CYAN}│${NC}"
    echo -e "${CYAN}└──────────────────────────────────────────────┘${NC}\n"
    
    echo -ne "${MAGENTA} ➜ ${WHITE}Enter your Registered Email: ${CYAN}"
    read USER_EMAIL
    echo -ne "${MAGENTA} ➜ ${WHITE}Enter your License Key: ${CYAN}"
    read USER_KEY
    echo -ne "${NC}" 
    
    echo ""
    info "Establishing secure connection to licensing server..."
    
    USER_IP=$(curl -s ifconfig.me)
    RESPONSE=$(curl -s -X POST "$API_URL" -H "Content-Type: application/json" -d "{\"email\":\"$USER_EMAIL\", \"key\":\"$USER_KEY\", \"ip\":\"$USER_IP\", \"requestedType\":\"$TYPE_REQ\", \"requestedVersion\":\"$VERSION_REQ\"}")
    
    if echo "$RESPONSE" | grep -qE '"success":\s*true'; then SUCCESS="true"; else SUCCESS="false"; fi
    MESSAGE=$(echo "$RESPONSE" | sed -n 's/.*"message"\s*:\s*"\([^"]*\)".*/\1/p')
    if [ -z "$MESSAGE" ]; then MESSAGE="Invalid response from the licensing server."; fi 
    
    if [ "$SUCCESS" != "true" ]; then
        echo ""
        error "Authentication Denied: $MESSAGE"
        sleep 2
        LICENSE_VALID="false"
        return 0
    else
        echo ""
        success "License Verified! Authorization Granted."
        sleep 1.5
        LICENSE_VALID="true"
        return 0
    fi
} 

prompt_action() {
    local version=$1
    while true; do
        show_banner
        echo -e "${WHITE}Selected Theme: ${GREEN}Arix v${LICENSE_VERSION} (${LICENSE_TYPE})${NC}\n"
        echo -e "${CYAN}  [ 1 ] ${WHITE}Install Theme"
        echo -e "${CYAN}  [ 2 ] ${WHITE}Uninstall Theme"
        echo -e "${CYAN}  [ 3 ] ${WHITE}Go Back${NC}\n"
        
        echo -ne "${MAGENTA} ➜ ${WHITE}Choose an action: ${CYAN}"
        read act_choice
        echo -ne "${NC}"
        
        case $act_choice in
            1) ACTION="install"; return 0 ;;
            2) ACTION="uninstall"; return 0 ;;
            3) ACTION=""; return 1 ;;
            *) warning "Invalid selection."; sleep 1 ;;
        esac
    done
}

menu_210() {
    while true; do
        show_banner
        echo -e "${WHITE}Select Edition for ${GREEN}Arix v2.1.0${WHITE}:${NC}\n"
        echo -e "${CYAN}  [ 1 ] ${WHITE}Standard Edition (Non-Blueprint)"
        echo -e "${CYAN}  [ 2 ] ${WHITE}Blueprint Edition"
        echo -e "${CYAN}  [ 3 ] ${WHITE}Go Back${NC}\n"
        
        echo -ne "${MAGENTA} ➜ ${WHITE}Choose an option: ${CYAN}"
        read choice_210
        echo -ne "${NC}"
        
        case $choice_210 in
            1) 
                LICENSE_TYPE="non-blueprint"; LICENSE_VERSION="2.1.0"
                DOWNLOAD_URL="https://raw.githubusercontent.com/sdgamer8263-sketch/pterodactyl_extention1/main/sd/v210/pterodactyl.zip"
                if prompt_action "$LICENSE_VERSION"; then break 2; fi ;;
            2) 
                LICENSE_TYPE="blueprint"; LICENSE_VERSION="2.1.0"
                DOWNLOAD_URL="https://raw.githubusercontent.com/sdgamer8263-sketch/pterodactyl_extention1/main/pterodactyl.zip"
                if prompt_action "$LICENSE_VERSION"; then break 2; fi ;;
            3) break ;;
            *) warning "Invalid selection."; sleep 1 ;;
        esac
    done
} 

menu_208() {
    while true; do
        show_banner
        echo -e "${WHITE}Select Edition for ${GREEN}Arix v2.0.8${WHITE}:${NC}\n"
        echo -e "${CYAN}  [ 1 ] ${WHITE}Standard Edition (Non-Blueprint)"
        echo -e "${CYAN}  [ 2 ] ${WHITE}Blueprint Edition"
        echo -e "${CYAN}  [ 3 ] ${WHITE}Go Back${NC}\n"
        
        echo -ne "${MAGENTA} ➜ ${WHITE}Choose an option: ${CYAN}"
        read choice_208
        echo -ne "${NC}"
        
        case $choice_208 in
            1) 
                LICENSE_TYPE="non-blueprint"; LICENSE_VERSION="2.0.8"
                DOWNLOAD_URL="https://raw.githubusercontent.com/sdgamer8263-sketch/pterodactyl_extention1/main/sd/v208/pterodactyl.zip"
                if prompt_action "$LICENSE_VERSION"; then break 2; fi ;;
            2) 
                LICENSE_TYPE="blueprint"; LICENSE_VERSION="2.0.8"
                DOWNLOAD_URL="https://raw.githubusercontent.com/sdgamer8263-sketch/pterodactyl_extention1/main/sd/av1pterodactyl.zip"
                if prompt_action "$LICENSE_VERSION"; then break 2; fi ;;
            3) break ;;
            *) warning "Invalid selection."; sleep 1 ;;
        esac
    done
} 

theme_installer_menu() {
    while true; do
        show_banner
        typewriter " Theme Installer - Select Version:"
        echo ""
        echo -e "${CYAN}  [ 1 ] ${WHITE}Arix v2.1.0 ${GREEN}(Latest)${NC}"
        echo -e "${CYAN}  [ 2 ] ${WHITE}Arix v2.0.8 ${YELLOW}(Legacy)${NC}"
        echo -e "${RED}  [ 0 ] ${WHITE}Go Back${NC}\n"
        
        echo -ne "${MAGENTA} ➜ ${WHITE}Choose an option: ${CYAN}"
        read th_choice
        echo -ne "${NC}"
        
        case $th_choice in
            1) menu_210; if [ -n "$ACTION" ]; then return 0; fi ;;
            2) menu_208; if [ -n "$ACTION" ]; then return 0; fi ;;
            0) return 1 ;;
            *) echo ""; warning "Invalid selection."; sleep 1 ;;
        esac
    done
}

execute_theme_action() {
    if [ "$ACTION" == "uninstall" ]; then
        show_banner
        echo -e "${CYAN} ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ${NC}"
        echo -e "${WHITE}             INITIALIZING UNINSTALLATION          ${NC}"
        echo -e "${CYAN} ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ${NC}" 

        if [ ! -d "/var/www/pterodactyl" ]; then
            error "Pterodactyl installation not found in /var/www/pterodactyl!"
            sleep 2; return 0
        fi
        cd /var/www/pterodactyl 
        
        info "Running Arix Uninstall Process..."
        php artisan arix uninstall
        
        echo -e "\n${GREEN} ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ${NC}"
        typewriter "     🗑️ UNINSTALLATION COMPLETED SUCCESSFULLY! 🗑️    "
        echo -e "${GREEN} ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ${NC}\n"
        read -p "Press Enter to return to main menu..."
        return 0
    fi

    if [ "$ACTION" == "install" ]; then
        show_banner
        verify_license "$LICENSE_TYPE" "$LICENSE_VERSION"
        if [ "$LICENSE_VALID" == "false" ]; then return 0; fi

        show_banner 
        check_dependencies 

        echo -e "${CYAN} ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ${NC}"
        echo -e "${WHITE}             INITIALIZING INSTALLATION            ${NC}"
        echo -e "${CYAN} ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ${NC}" 

        set +e
        (apt-get update -y > /dev/null 2>&1 && apt-get install -y unzip curl wget > /dev/null 2>&1) & spinner $!
        set -e 

        if [ ! -d "/var/www/pterodactyl" ]; then
            error "Pterodactyl not found in /var/www/pterodactyl!"; sleep 2; return 0
        fi
        cd /var/www/pterodactyl 

        step "1/4" "Downloading Arix Theme Assets..."
        (curl -sL -o pterodactyl.zip "$DOWNLOAD_URL") & spinner $!
        success "Downloaded successfully." 

        step "2/4" "Extracting Core Files..."
        (
            unzip -o pterodactyl.zip > /dev/null 2>&1
            if [ -d "pterodactyl" ]; then cp -rf pterodactyl/* ./; rm -rf pterodactyl; fi
            rm pterodactyl.zip 
        ) & spinner $!
        success "Files extracted successfully." 

        step "3/4" "Injecting Modules..."
        if [ "$LICENSE_VERSION" == "2.1.0" ]; then
            cat << 'EOF' > app/Console/Commands/Arix.php
<?php 

namespace Pterodactyl\Console\Commands; 

use Illuminate\Console\Command;
use Symfony\Component\Console\Formatter\OutputFormatterStyle;
use Illuminate\Support\Facades\File; 

class Arix extends Command
{
    protected $signature = "arix {action?}";
    protected $description = "All commands for Arix Theme for Pterodactyl."; 

    public function handle()
    {
        $action = $this->argument("action");
        $title = new OutputFormatterStyle("#fff", null, ["bold"]);
        $this->output->getFormatter()->setStyle("title", $title);
        $b = new OutputFormatterStyle(null, null, ["bold"]);
        $this->output->getFormatter()->setStyle("b", $b); 

        if ($action === null) {
            $this->line("\r\n            <title>\r\n            ░█████╗░██████╗░██╗██╗░░██╗\r\n            ██╔══██╗██╔══██╗██║╚██╗██╔╝\r\n            ███████║██████╔╝██║░╚███╔╝░\r\n            ██╔══██║██╔══██╗██║░██╔██╗░\r\n            ██║░░██║██║░░██║██║██╔╝╚██╗\r\n            ╚═╝░░╚═╝╚═╝░░╚═╝╚═╝╚═╝░░╚═╝\r\n\r\n           Thank you for purchasing Arix</title>\r\n\r\n           > php artisan arix (this window)\r\n           > php artisan arix install\r\n           > php artisan arix update\r\n           > php artisan arix uninstall\r\n            ");
        } else {
            $this->info("\n    Arix Theme\n    \n");
            if ($action === "install") {
                $this->install();
            } elseif ($action === "update") {
                $this->update();
            } elseif ($action === "uninstall") {
                $this->uninstall();
            } else {
                $this->error("Invalid action. Supported actions: install, update, uninstall");
            }
        }
    } 

    public function installOrUpdate($isUpdate = false)
    {
        if ($isUpdate) {
            $this->info("\n    This command is not recommended to use. \n   This command skips frequently used files by addons during theme updating to avoid losing your addon customizations.\n   If you still experience an error after updating please contact us.");
        } 

        $confirmation = $this->confirm("Are all the required dependencies installed from the readme file?", "yes");
        if (!$confirmation) {
            return;
        } 

        $versions = File::directories("./arix");
        if (empty($versions)) {
            $this->info("No versions found in /arix directory.");
            return;
        } 

        $version = basename($this->choice("Select a version:", $versions));
        $this->info("Installing Arix Theme {$version}..."); 

        $excludeOption = $isUpdate ? "--exclude='routes.ts' --exclude='getServer.ts' --exclude='admin.blade.php' --exclude='admin.php' --exclude='ServerTransformer.php'" : '';
        exec("rsync -a {$excludeOption} arix/{$version}/ ./"); 

        $directoryPath = app_path("Http/Controllers/Admin/Arix");
        File::makeDirectory($directoryPath, 0755, true, true); 

        $filesOne = ["ArixController", "ArixAdvancedController", "ArixAnnouncementController", "ArixColorsController", "ArixComponentsController", "ArixDashboardController", "ArixLayoutController"];
        $this->info("Proceeding with the installation...");
        foreach ($filesOne as $file) {
            $this->aa($file, $version, $directoryPath);
            sleep(1);
        } 

        $filesTwo = ["ArixLinkController", "ArixMailController", "ArixMetaController", "ArixPresetController", "ArixSocialController", "ArixStylingController"];
        foreach ($filesTwo as $file) {
            $this->aa($file, $version, $directoryPath);
            sleep(1);
        } 

        $this->info("Migrating database...");
        $this->command("php artisan migrate --force"); 

        $this->info("Installing required packages...");
        $this->info("This can take a minute...");
        $this->command("yarn add react-email-editor react-colorful recharts@^2.15.4 ua-parser-js cronstrue react-day-picker jszip react-turnstile @dnd-kit/core @dnd-kit/sortable @dnd-kit/utilities @types/md5 md5 react-icons@5.4.0 markdown-to-jsx@7.7.10 i18next-browser-languagedetector@7.2.1"); 

        $this->info("Compile translations...");
        $this->command("php artisan language:compile"); 

        $this->info("Building panel assets...");
        $this->info("This can take a minute...");
        $nodeVersion = shell_exec("node -v");
        $nodeVersion = (int) ltrim($nodeVersion, "v");
        if ($nodeVersion >= 17) {
            $this->info("Node.js version is v" . $nodeVersion . " (>= 17)");
            putenv("NODE_OPTIONS=--openssl-legacy-provider");
        } else {
            $this->info("Node.js version is v" . $nodeVersion . " (< 17)");
        }
        $this->command("yarn build:production"); 

        $this->info("Set permissions...");
        $this->command("chown -R www-data:www-data /var/www/pterodactyl/* " . base_path() . "/*");
        $this->command("chown -R nginx:nginx " . base_path() . "/*");
        $this->command("chown -R apache:apache " . base_path() . "/*"); 

        $this->info("Optimize application...");
        $this->command("php artisan optimize:clear");
        $this->command("php artisan optimize"); 

        $this->info("Restarting workers...");
        $this->command("php artisan queue:restart"); 

        $message = $isUpdate ? "│    Theme updated successfully   │" : "│   Theme installed successfully  │";
        $this->line("\n ╭───────────────────────────────╮\n │ │\n │ ╭─╴ {$message} ╶─╮ │\n │ ╰─╴ successfully ╶─╯ │\n │ │\n ╰───────────────────────────────╯\n ");
    } 

    private function aa($filename, $version, $directoryPath)
    {
        $filePath = $directoryPath . "/" . $filename . ".php";
        $localSource = base_path("arix/" . $version . "/app/Http/Controllers/Admin/Arix/" . $filename . ".php"); 

        if (File::exists($localSource)) {
            $this->info(" -> Copying local {$filename}.php...");
            File::copy($localSource, $filePath);
        } else {
            $this->error("Fail: Could not find local {$filename}.php at {$localSource}.");
        }
    }
    
    public function install()
    {
        $this->info("Configuring environment...");
        sleep(1);
        $this->info("Loading modules...");
        sleep(1);
        
        $this->installOrUpdate();
        
        $this->info("Arix Theme installation completed safely!");
    } 

    public function update()
    {
        $this->installOrUpdate(true);
    } 

    private function uninstall()
    {
        $this->line("Uninstalling...");
        $this->command("php artisan down");
        $this->command("curl -L https://github.com/pterodactyl/panel/releases/latest/download/panel.tar.gz | tar -xzv");
        $this->command("chmod -R 755 storage/* bootstrap/cache");
        $this->command("composer install --no-dev --optimize-autoloader");
        $this->command("php artisan view:clear");
        $this->command("php artisan config:clear");
        $this->command("php artisan migrate --seed --force");
        $this->command("chown -R www-data:www-data " . base_path() . "/*");
        $this->command("chown -R nginx:nginx " . base_path() . "/*");
        $this->command("chown -R apache:apache " . base_path() . "/*");
        $this->command("php artisan queue:restart");
        $this->command("php artisan up");
        $this->info("Arix Theme uninstalled successfully.");
    } 

    private function command($cmd)
    {
        return exec($cmd);
    }
}
EOF
            php artisan arix install
        else
            info "Skipping Arix.php patch for legacy v2.0.8..."
        fi
        success "Modules injected!" 

        step "4/4" "Compiling Pterodactyl Panel (Production Build)..."
        warning "This process takes 2-5 minutes. Please DO NOT close the terminal."
        (
            export NODE_OPTIONS=--openssl-legacy-provider
            yarn add xterm-addon-unicode11 > /dev/null 2>&1
            yarn build:production > /dev/null 2>&1
        ) & spinner $!
        success "Panel compiled successfully!" 

        set +e 
        info "Applying Final Permissions & Caching..."
        (
            curl -sL https://raw.githubusercontent.com/pterodactyl/panel/master/public/index.php -o public/index.php > /dev/null 2>&1
            chown -R www-data:www-data /var/www/pterodactyl 2>/dev/null
            chown -R nginx:nginx /var/www/pterodactyl 2>/dev/null
            find /var/www/pterodactyl -type d -exec chmod 755 {} \;
            find /var/www/pterodactyl -type f -exec chmod 644 {} \;
            chmod -R 775 storage/* bootstrap/cache/
            chown -R www-data:www-data /var/www/pterodactyl/*
            grep -rl "2.1.[0-9]" resources/ config/ app/ 2>/dev/null | xargs sed -i 's/2.1.[0-9]/2.1.2/g'
php artisan view:clear
php artisan optimize:clear
cd /var/www/pterodactyl
sed -i "s/'version' => '[0-9.]*'/'version' => '1.15.1'/g" config/app.php
php artisan config:clear
php artisan optimize:clear
cd /var/www/pterodactyl
yarn add xterm-addon-unicode11
yarn build
cd
        ) & spinner $! 

        echo -e "\n${GREEN} ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ${NC}"
        typewriter "    🎉 INSTALLATION COMPLETED SUCCESSFULLY! 🎉    "
        echo -e "${GREEN} ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ${NC}\n"
        read -p "Press Enter to return to main menu..."
        return 0
    fi
}

addon_names=(
    "autobackups.blueprint" 
    "eggchanger.blueprint"
    "minecraftplayermanager.blueprint" 
    "modrinthbrowser.blueprint"
    "motdmaker.blueprint" 
    "resourcemanager.blueprint" 
    "sagaautosuspension.blueprint"
    "sagaminecraftmodpackinstaller.blueprint" 
    "servericonimporter.blueprint" 
    "serverpropsmanager.blueprint"
    "serversplitter.blueprint" 
    "snowflakes.blueprint" 
    "stats.blueprint" 
    "subdomainmanager.blueprint" 
    "versionchanger.blueprint"
)

is_addon_installed() {
    if [[ -d "/var/www/pterodactyl/storage/extensions/${1%.blueprint}" ]]; then return 0; else return 1; fi
}

run_addon_blueprint() {
    local NAME="$1"; local ACT="$2"; cd /var/www/pterodactyl || exit 1
    if [[ "$ACT" == "install" ]]; then
        echo -e "${GREEN}📥 Installing ${NAME%.blueprint}...${NC}"
        wget -q "$ADDON_URL/$NAME" -O "$NAME" || true
        if [[ -s "$NAME" ]]; then yes | blueprint -i "$NAME" || true; rm -f "$NAME"; fi
    else
        echo -e "${RED}🗑️ Removing ${NAME%.blueprint}...${NC}"
        yes | blueprint -r "${NAME%.blueprint}" || true
    fi
}

addon_installer_menu() {
    if ! command -v blueprint >/dev/null 2>&1; then
        error "Blueprint Framework is NOT installed!"
        sleep 3; return 0
    fi
    while true; do
        clear
        echo -e "${CYAN} ╔══════════════════════════════════════════════════════════╗${NC}"
        printf " ${CYAN}║${WHITE}%-58s${CYAN}║${NC}\n" "Theme Addon Installer (Blueprint)"
        echo -e "${CYAN} ╚══════════════════════════════════════════════════════════╝${NC}"
        local count=0
        for i in "${!addon_names[@]}"; do
            num=$((i + 1)); clean_name="${addon_names[$i]%.blueprint}"
            if is_addon_installed "$clean_name"; then status="${GREEN}●${NC}"; else status="${RED}○${NC}"; fi
            display_name="${clean_name:0:24}"
            printf "  ${GREEN}%2d${NC}) %-24s %b " "$num" "$display_name" "$status"
            count=$((count + 1)); if [[ $((count % 2)) -eq 0 ]]; then echo ""; fi
        done
        if [[ $((count % 2)) -ne 0 ]]; then echo ""; fi

        echo -e "${CYAN} ──────────────────────────────────────────────────────────${NC}"
        echo -e " ${WHITE}Commands:${NC}"
        echo -e " ${YELLOW}1, 1,2, 1 2 3${NC} : Install specific addon(s)"
        echo -e " ${YELLOW}all${NC}           : Install ALL addons"
        echo -e " ${YELLOW}r 1, r 1,2${NC}    : Remove specific addon(s) (or 'r all')"
        echo -e " ${RED}0${NC}             : Go Back"
        echo -e "${CYAN} ──────────────────────────────────────────────────────────${NC}"

        read -p " 👉 Select Action: " choice
        choice=${choice//,/ }; choice_lower=${choice,,}
        if [[ "$choice_lower" == "0" ]]; then return 0; fi

        local action_type="install"; local targets="$choice_lower"
        if [[ "$choice_lower" == r\ * ]]; then action_type="remove"; targets="${choice_lower:2}"; fi

        local selected_addons=()
        if [[ "$targets" == "all" ]]; then
            for i in "${!addon_names[@]}"; do selected_addons+=("$i"); done
        else
            for val in $targets; do
                if [[ "$val" =~ ^[0-9]+$ ]] && [[ "$val" -ge 1 ]] && [[ "$val" -le "${#addon_names[@]}" ]]; then
                    selected_addons+=($((val-1)))
                fi
            done
        fi
        if [[ ${#selected_addons[@]} -eq 0 ]]; then continue; fi

        if [[ "$action_type" == "install" ]]; then
            for idx in "${selected_addons[@]}"; do
                if [[ "${addon_names[$idx]}" == "resourcemanager.blueprint" ]]; then run_addon_blueprint "resourcemanager.blueprint" "install"; fi
            done
            for idx in "${selected_addons[@]}"; do
                if [[ "${addon_names[$idx]}" != "resourcemanager.blueprint" ]]; then 
                    run_addon_blueprint "${addon_names[$idx]}" "install"
                    
                    if [[ "${addon_names[$idx]}" == "eggchanger.blueprint" ]]; then
                        info "Fixing Issues for Eggchanger..."
                        cd /var/www/pterodactyl 

                        cat << 'EOF' > resources/scripts/components/server/settings/SettingsContainer.tsx
import React from 'react';
import TitledGreyBox from '@/components/elements/TitledGreyBox';
import { ServerContext } from '@/state/server';
import { useStoreState } from 'easy-peasy';
import RenameServerBox from '@/components/server/settings/RenameServerBox';
import FlashMessageRender from '@/components/FlashMessageRender';
import Can from '@/components/elements/Can';
import ReinstallServerBox from '@/components/server/settings/ReinstallServerBox';
import tw from 'twin.macro';
import Input from '@/components/elements/Input';
import Label from '@/components/elements/Label';
import ServerContentBlock from '@/components/elements/ServerContentBlock';
import isEqual from 'react-fast-compare';
import CopyOnClick from '@/components/elements/CopyOnClick';
import { ip } from '@/lib/formatters';
import { Button } from '@/components/elements/button/index';
import { CogIcon } from '@heroicons/react/outline';
import { useTranslation } from 'react-i18next'; 

// Egg Changer Component Import
import EggChangerBox from '@/components/EggChangerBox'; 

export default () => {
    const { t } = useTranslation('arix/server/settings');
    const username = useStoreState((state) => state.user.data!.username);
    const id = ServerContext.useStoreState((state) => state.server.data!.id);
    const uuid = ServerContext.useStoreState((state) => state.server.data!.uuid);
    const node = ServerContext.useStoreState((state) => state.server.data!.node);
    const nodeIcon = ServerContext.useStoreState((state) => state.server.data!.nodeIcon);
    const sftp = ServerContext.useStoreState((state) => state.server.data!.sftpDetails, isEqual); 

    return (
        <ServerContentBlock title={t('settings')} icon={CogIcon}>
            <FlashMessageRender byKey={'settings'} css={tw`mb-4`} />
            <div css={tw`grid lg:grid-cols-2 items-start gap-4`}>
                <Can action={'file.sftp'}>
                    <TitledGreyBox title={t('sftp.title')}>
                        <div>
                            <Label>{t('sftp.server-address')}</Label>
                            <CopyOnClick text={`sftp://${ip(sftp.ip)}:${sftp.port}`}>
                                <Input
                                    type={'text'}
                                    className='privacy-blur'
                                    value={`sftp://${ip(sftp.ip)}:${sftp.port}`}
                                    readOnly
                                />
                            </CopyOnClick>
                        </div>
                        <div css={tw`mt-6`}>
                            <Label>{t('sftp.username')}</Label>
                            <CopyOnClick text={`${username}.${id}`}>
                                <Input type={'text'} value={`${username}.${id}`} className='privacy-blur' readOnly />
                            </CopyOnClick>
                        </div>
                        <div css={tw`mt-6 flex items-center`}>
                            <div css={tw`flex-1`}>
                                <div css={tw`border-l-4 border-cyan-500 p-3`}>
                                    <p css={tw`text-xs text-neutral-200`}>{t('sftp.description')}</p>
                                </div>
                            </div>
                            <div css={tw`ml-4`}>
                                <a href={`sftp://${username}.${id}@${ip(sftp.ip)}:${sftp.port}`}>
                                    <Button.Text variant={Button.Variants.Secondary}>
                                        {t('sftp.launch-sftp')}
                                    </Button.Text>
                                </a>
                            </div>
                        </div>
                    </TitledGreyBox>
                </Can>
                <Can action={'settings.rename'}>
                    <RenameServerBox />
                </Can>
                <TitledGreyBox title={t('debug.title')}>
                    <div css={tw`flex items-center justify-between text-sm`}>
                        <p>{t('debug.node')}</p>
                        <div css={tw`flex items-center gap-x-1`}>
                            {nodeIcon && <img src={nodeIcon} alt={node} css={tw`w-5 h-5 object-cover rounded-sm`} />}
                            <code css={tw`font-mono bg-neutral-900 rounded py-1 px-2`}>{node}</code>
                        </div>
                    </div>
                    <CopyOnClick text={uuid}>
                        <div css={tw`flex items-center justify-between mt-2 text-sm`}>
                            <p>{t('debug.server-id')}</p>
                            <code
                                className={`privacy:blur-sm hover:privacy:blur-none duration-300 font-mono bg-neutral-900 rounded py-1 px-2`}
                            >
                                {uuid}
                            </code>
                        </div>
                    </CopyOnClick>
                </TitledGreyBox>
                <Can action={'settings.reinstall'}>
                    <ReinstallServerBox />
                </Can>
                
                {/* EGG CHANGER UI YAHAN ADD KIYA GAYA HAI */}
                <EggChangerBox />
                
            </div>
        </ServerContentBlock>
    );
};
EOF
                        cp -r .blueprint/extensions/eggchanger/components/* resources/scripts/components/ || true

                        export NODE_OPTIONS="--openssl-legacy-provider --no-deprecation"
                        ( yarn build:production > /dev/null 2>&1 ) & spinner $! 

                        php artisan view:clear > /dev/null 2>&1
                        php artisan optimize:clear > /dev/null 2>&1
                        success "Successfully fixed eggchanger."
                    fi
                fi
            done
        else
            for idx in "${selected_addons[@]}"; do run_addon_blueprint "${addon_names[$idx]}" "remove"; done
        fi
        echo ""; read -p "Done. Press Enter to return..."
    done
}

while true; do
    show_banner
    echo -e "${WHITE}Please select what you want to do:${NC}\n"
    echo -e "${CYAN}  [ 1 ] ${WHITE}Theme Installer"
    echo -e "${CYAN}  [ 2 ] ${WHITE}Theme Addon Installer"
    echo -e "${RED}  [ 0 ] ${WHITE}Exit${NC}\n"
    
    echo -ne "${MAGENTA} ➜ ${WHITE}Choose an option: ${CYAN}"
    read main_opt
    echo -ne "${NC}"
    
    case $main_opt in
        1) theme_installer_menu; if [ -n "$ACTION" ]; then execute_theme_action; fi ;;
        2) addon_installer_menu ;;
        0) echo -e "\n${MAGENTA} Bye!${NC}"; exit 0 ;;
        *) warning "Invalid selection. Try again."; sleep 1 ;;
    esac
done
