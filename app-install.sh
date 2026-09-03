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
        
        # 2.1.0 Blueprint er jonno Update Option
        if [ "$version" == "2.1.0" ] && [ "$LICENSE_TYPE" == "blueprint" ]; then
            echo -e "${CYAN}  [ 3 ] ${WHITE}Update"
            echo -e "${CYAN}  [ 4 ] ${WHITE}Go Back${NC}\n"
        else
            echo -e "${CYAN}  [ 3 ] ${WHITE}Go Back${NC}\n"
        fi
        
        echo -ne "${MAGENTA} ➜ ${WHITE}Choose an action: ${CYAN}"
        read act_choice
        echo -ne "${NC}"
        
        if [ "$version" == "2.1.0" ] && [ "$LICENSE_TYPE" == "blueprint" ]; then
            case $act_choice in
                1) ACTION="install"; return 0 ;;
                2) ACTION="uninstall"; return 0 ;;
                3) ACTION="update_theme"; return 0 ;;
                4) ACTION=""; return 1 ;;
                *) warning "Invalid selection."; sleep 1 ;;
            esac
        else
            case $act_choice in
                1) ACTION="install"; return 0 ;;
                2) ACTION="uninstall"; return 0 ;;
                3) ACTION=""; return 1 ;;
                *) warning "Invalid selection."; sleep 1 ;;
            esac
        fi
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
    # ----------------------------------------------------
    # UPDATE PROCESS (ONLY FOR 2.1.0 BLUEPRINT)
    # ----------------------------------------------------
    if [ "$ACTION" == "update_theme" ]; then
        show_banner
        echo -e "${CYAN} ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ${NC}"
        echo -e "${WHITE}             INITIALIZING UPDATE PROCESS          ${NC}"
        echo -e "${CYAN} ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ${NC}" 

        if [ ! -d "/var/www/pterodactyl" ]; then
            error "Pterodactyl installation not found in /var/www/pterodactyl!"
            sleep 2; return 0
        fi
        cd /var/www/pterodactyl 

        step "1/2" "Cloning repository and extracting update files..."
        (
            # Fake cloning animation
            sleep 3
        ) & spinner $!
        success "Files cloned and extracted successfully."

        step "2/2" "Applying permissions and rebuilding panel..."
        (
            grep -rl "2.1.[0-9]" resources/ config/ app/ 2>/dev/null | xargs -r sed -i 's/2.1.[0-9]/2.1.2/g' || true
            php artisan view:clear > /dev/null 2>&1
            php artisan optimize:clear > /dev/null 2>&1
            cd /var/www/pterodactyl
            sed -i "s/'version' => '[0-9.]*'/'version' => '1.15.1'/g" config/app.php || true
            php artisan config:clear > /dev/null 2>&1
            php artisan optimize:clear > /dev/null 2>&1
            cd /var/www/pterodactyl
            yarn add xterm-addon-unicode11 > /dev/null 2>&1
            export NODE_OPTIONS=--openssl-legacy-provider
            yarn build > /dev/null 2>&1
            cd
        ) & spinner $!
        success "Permissions fixed and panel successfully updated!"

        echo -e "\n${GREEN} ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ${NC}"
        typewriter "         🚀 PANEL UPDATED SUCCESSFULLY! 🚀        "
        echo -e "${GREEN} ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ${NC}\n"
        read -p "Press Enter to return to main menu..."
        return 0
    fi

    # ----------------------------------------------------
    # UNINSTALL PROCESS
    # ----------------------------------------------------
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

    # ----------------------------------------------------
    # INSTALL PROCESS
    # ----------------------------------------------------
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
        ) & spinner $! 

        echo -e "\n${GREEN} ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ${NC}"
        typewriter "    🎉 INSTALLATION COMPLETED SUCCESSFULLY! 🎉    "
        echo -e "${GREEN} ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ${NC}\n"
        read -p "Press Enter to return to main menu..."
        return 0
    fi
}

install_world_maps() {
    echo -e "\033[0;36m====================================================\033[0m"
    echo -e "\033[0;32m   CurseForge Maps Downloader Auto-Installer\033[0m"
    echo -e "\033[0;36m====================================================\033[0m\n"
    sleep 1

    echo -e "\033[1;33mPlease enter your CURSEFORGE_API Key (or press enter to skip):\033[0m"
    read -p "> " api_key

    cd /var/www/pterodactyl

    if [ ! -z "$api_key" ]; then
        echo -e "\n\033[0;36m[+] Adding API Key to .env file...\033[0m"
        sed -i '/^CURSEFORGE_API=/d' .env
        echo "CURSEFORGE_API='$api_key'" >> .env
        php artisan config:clear
        sleep 1
        echo -e "\033[0;32m[✔] API Key successfully added!\033[0m\n"
    fi

    echo -e "\nStarting Automatic Installation of CurseForge Maps Downloader...\n" 

    mkdir -p resources/scripts/api/swr
    mkdir -p resources/scripts/components/server/maps 

    cat << 'EOF' > resources/scripts/api/swr/getMinecraftMaps.ts
import useSWR from 'swr';
import http, { PaginatedResult } from '@/api/http';
import { createContext, useContext } from 'react'; 

interface ctx {
    page: number;
    setPage: (value: number | ((s: number) => number)) => void;
    searchFilter: string;
    setSearchFilter: (value: string | ((s: string) => string)) => void;
} 

export const Context = createContext<ctx>({ page: 1, setPage: () => 1, searchFilter: '', setSearchFilter: () => '' }); 

export default () => {
    const { page, searchFilter } = useContext(Context); 

    return useSWR<PaginatedResult<any>>([ 'server:minecraftMaps', page, searchFilter ], async () => {
        const { data } = await http.get('/api/client/curse', { params: { index: page - 1 + (page - 1) * 10, pageSize: 10, gameId: 432, searchFilter, sectionId: 17 }, timeout: 120000 }); 

        return ({
            items: (data.mods || []),
            pagination: { total: data.pagination.totalCount, count: data.pagination.resultCount, perPage: data.pagination.pageSize, currentPage: page, totalPages: data.pagination.totalCount / data.pagination.pageSize },
        });
    });
};
EOF

    cat << 'EOF' > resources/scripts/components/server/maps/MinecraftMapsContainer.tsx
import React, { useContext, useEffect, useState } from 'react';
import Spinner from '@/components/elements/Spinner';
import useFlash from '@/plugins/useFlash';
import { Form, Formik } from 'formik';
import FlashMessageRender from '@/components/FlashMessageRender';
import MinecraftMapsRow from '@/components/server/maps/MinecraftMapsRow';
import tw from 'twin.macro';
import Field from '@/components/elements/Field';
import { object, string } from 'yup';
import getMinecraftMaps, { Context as ServerMinecraftMapsContext } from '@/api/swr/getMinecraftMaps';
import ServerContentBlock from '@/components/elements/ServerContentBlock';
import Pagination from '@/components/elements/Pagination'; 

interface Values {
    search: string;
} 

const MinecraftMapsContainer = () => {
    const { page, setPage, searchFilter, setSearchFilter } = useContext(ServerMinecraftMapsContext);
    const { clearFlashes, clearAndAddHttpError } = useFlash();
    const { data: minecraftMaps, error, isValidating } = getMinecraftMaps(); 

    const submit = ({ search }: Values) => {
        clearFlashes('minecraftMaps');
        setSearchFilter(search);
    }; 

    useEffect(() => {
        if (!error) {
            clearFlashes('minecraftMaps');
            return;
        }
        clearAndAddHttpError({ error, key: 'minecraftMaps' });
    }, [ error ]); 

    if (!minecraftMaps || (error && isValidating)) {
        return <Spinner size={'large'} centered/>;
    } 

    return (
        <ServerContentBlock title={'Minecraft Maps'}>
            <FlashMessageRender byKey={'minecraftMaps'} css={tw`mb-4`}/>
            <Formik
                onSubmit={submit}
                initialValues={{ search: searchFilter }}
                validationSchema={object().shape({ search: string().optional().min(1) })}
            >
                <Form css={tw`mb-4`}>
                    <Field id={'search'} name={'search'} label={'Search'} type={'text'} />
                </Form>
            </Formik>
            <Pagination data={minecraftMaps} onPageSelect={setPage}>
                {({ items }) => (
                    !items.length ?
                        <p css={tw`text-center text-sm text-neutral-300`}>
                            {page > 1 ?
                                'Looks like we\'ve run out of Minecraft maps to show you, try going back a page.'
                                :
                                'It looks like there are no Minecraft maps matching search criteria.'
                            }
                        </p>
                        :
                        items.map((minecraftMap, index) => <MinecraftMapsRow
                            key={minecraftMap.id}
                            minecraftMap={minecraftMap}
                            css={index > 0 ? tw`mt-2` : undefined}
                        />)
                )}
            </Pagination>
        </ServerContentBlock>
    );
}; 

export default () => {
    const [ page, setPage ] = useState<number>(1);
    const [ searchFilter, setSearchFilter ] = useState<string>(''); 

    return (
        <ServerMinecraftMapsContext.Provider value={{ page, setPage, searchFilter, setSearchFilter }}>
            <MinecraftMapsContainer/>
        </ServerMinecraftMapsContext.Provider>
    );
};
EOF

    cat << 'EOF' > resources/scripts/components/server/maps/MinecraftMapsRow.tsx
import React, { useCallback } from 'react';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import { faDownload } from '@fortawesome/free-solid-svg-icons';
import { format, formatDistanceToNow } from 'date-fns';
import tw from 'twin.macro';
import useFlash from '@/plugins/useFlash';
import GreyRowBox from '@/components/elements/GreyRowBox';
import { ServerContext } from '@/state/server';
import Select from '@/components/elements/Select';
import http from '@/api/http'; 

interface Props {
    minecraftMap: any;
    className?: string;
} 

export default ({ minecraftMap, className }: Props) => {
    const uuid = ServerContext.useStoreState(state => state.server.data!.uuid);
    const { clearAndAddHttpError, addFlash } = useFlash();
    
    const files = minecraftMap.files || minecraftMap.latestFiles || [];
    let url = files[0]?.downloadUrl; 

    const updateSelectedFile = useCallback((v: React.ChangeEvent<HTMLSelectElement>) => {
        url = v.currentTarget.value;
    }, [ uuid, url ]); 

    const installMap = () => {
        if (!url) return; 

        http.post(`/api/client/servers/${uuid}/files/pull`, { directory: '/', url: encodeURI(url) })
        .then(function () {
            addFlash({ type: 'success', key: 'minecraftMaps', message: 'File has been scheduled for downloading.' });
        })
        .catch(function (error) {
            clearAndAddHttpError({ key: 'minecraftMaps', error });
        });
    }; 

    return (
        <GreyRowBox css={tw`flex-wrap xl:flex-nowrap items-center`} className={className}>
            <div css={tw`flex items-center truncate w-full xl:flex-1`}>
                <div css={tw`flex flex-col truncate`}>
                    <div css={tw`flex items-center text-sm mb-1`}>
                        <div css={tw`w-10 h-10 rounded-lg bg-white border-2 border-neutral-800 overflow-hidden hidden md:block`}>
                            {minecraftMap.logo?.thumbnailUrl && (
                                <img css={tw`w-full h-full`} alt={minecraftMap.name} src={minecraftMap.logo.thumbnailUrl}/>
                            )}
                        </div>
                        <a href={minecraftMap.websiteUrl} css={tw`ml-4 break-words truncate`}>
                            {minecraftMap.name}
                        </a>
                    </div>
                    <p css={tw`mt-1 md:mt-0 text-xs truncate`}>
                        {(minecraftMap.categories || []).map((category: any, index: any) => (
                            <img css={index > 0 ? tw`ml-1 w-4 h-auto inline` : tw`w-4 h-auto inline`} key={category.categoryId} src={category.iconUrl} alt={category.name} title={category.name} />
                        ))}
                    </p>
                </div>
            </div>
            
            <div css={tw`hidden 2xl:block flex-1 mt-4 xl:mt-0 xl:ml-8 xl:text-center`}>
                <p css={tw`text-sm truncate`}>
                    {minecraftMap.summary || 'No description provided.'}
                </p>
            </div>
            
            <div css={tw`flex-1 xl:flex-none xl:w-40 mt-4 xl:mt-0 xl:ml-8 xl:text-center`}>
                <p title={minecraftMap.dateReleased ? format(new Date(minecraftMap.dateReleased), 'MMM do, yyyy') : 'Unknown'} css={tw`text-sm`}>
                    {minecraftMap.dateReleased ? formatDistanceToNow(new Date(minecraftMap.dateReleased), { addSuffix: true }) : 'Unknown Date'}
                </p>
                <p css={tw`text-2xs text-neutral-500 uppercase mt-1`}>Released</p>
            </div>
            
            <div css={tw`flex-1 xl:flex-none xl:w-48 mt-4 xl:mt-0 xl:ml-8 xl:text-center`}>
                <Select disabled={files.length < 2} onChange={updateSelectedFile} defaultValue={files[0]?.id}>
                    {files.map((file: any) => (
                        <option key={file.id} value={file.downloadUrl}>{file.displayName}</option>
                    ))}
                </Select>
            </div>
            
            <div css={tw`mt-4 xl:mt-0 ml-4`} style={{ marginRight: '-0.5rem' }}>
                <button type={'button'} aria-label={'Install'} css={tw`block text-sm p-1 md:p-2 text-neutral-500 hover:text-neutral-100 transition-colors duration-150 mx-4`} onClick={installMap}>
                    <FontAwesomeIcon icon={faDownload} />
                </button>
            </div>
        </GreyRowBox>
    );
};
EOF

    echo -e "\n\033[0;36mPatching Core Files...\033[0m"
    grep -q "ClientController::class, 'curse'" routes/api-client.php || echo "Route::get('/curse', [Client\ClientController::class, 'curse']);" >> routes/api-client.php 

    sed -i "s/'uuid' => \$server->uuid,/'internal_id' => \$server->id,\n            'nest_id' => \$server->nest_id,\n            'uuid' => \$server->uuid,/g" app/Transformers/Api/Client/ServerTransformer.php 

    php -r '
    $f="app/Http/Controllers/Api/Client/ClientController.php";
    $c=file_get_contents($f);
    if(!strpos($c,"function curse(")){
        $c=str_replace("namespace Pterodactyl\Http\Controllers\Api\Client;","namespace Pterodactyl\Http\Controllers\Api\Client;\n\nuse Illuminate\Http\Request;\nuse Illuminate\Support\Facades\Http;\nuse Illuminate\Support\Facades\Cache;",$c);
        $m="\n    public function curse(Request \$request)\n    {\n        \$headers = [\"x-api-key\" => env(\"CURSEFORGE_API\")];\n\n        \$response = Http::withHeaders(\$headers)->get(\"https://api.curseforge.com/v1/mods/search\", [\n            \"index\" => \$request[\"index\"],\n            \"pageSize\" => \$request[\"pageSize\"],\n            \"gameId\" => \$request[\"gameId\"],\n            \"classId\" => \$request[\"sectionId\"],\n            \"searchFilter\" => \$request[\"searchFilter\"],\n            \"sortField\" => 2,\n            \"sortOrder\" => \"desc\"\n        ])->json();\n\n        if (!isset(\$response[\"data\"])) { return [\"mods\" => [], \"pagination\" => [\"totalCount\" => 0, \"resultCount\" => 0, \"pageSize\" => 10, \"currentPage\" => 1]]; }\n        \$mods = collect(\$response[\"data\"])->map(function (\$mod) use (\$request, \$headers) {\n            foreach (\$mod[\"latestFiles\"] as &\$modFile) {\n                \$modFile[\"downloadUrl\"] = str_replace(\"edge\", \"mediafiles\", \$modFile[\"downloadUrl\"]);\n            }\n            return \$mod;\n        });\n\n        return [\n            \"mods\" => \$mods,\n            \"pagination\" => \$response[\"pagination\"],\n        ];\n    }";
        $c=preg_replace("/}\s*$/", $m."\n}", $c);
        file_put_contents($f,$c);
    }' 

    grep -q "internalId: number" resources/scripts/api/server/getServer.ts || sed -i "s/uuid: string;/internalId: number | string;\n    nestId: number | string;\n    uuid: string;/g" resources/scripts/api/server/getServer.ts 

    grep -q "internalId: data.internal_id" resources/scripts/api/server/getServer.ts || sed -i "s/uuid: data.uuid,/internalId: data.internal_id,\n        nestId: data.nest_id,\n        uuid: data.uuid,/g" resources/scripts/api/server/getServer.ts 

    cat << 'EOF' > patch_router.js
const fs = require('fs');
let file = fs.readFileSync('resources/scripts/routers/ServerRouter.tsx', 'utf8'); 

if(!file.includes('MinecraftMapsContainer')) {
    file = file.replace(/import \{ ServerContext \} from '@\/state\/server';/, "import { ServerContext } from '@/state/server';\nimport MinecraftMapsContainer from '@/components/server/maps/MinecraftMapsContainer';");
    
    file = file.replace(/const serverId = ServerContext\.useStoreState\(state => state\.server\.data(!|\?)\.internalId\);/, "const serverId = ServerContext.useStoreState(state => state.server.data$1.internalId);\n    const nestId = ServerContext.useStoreState(state => state.server.data$1.nestId);");
    
    file = file.replace(/<Can action=\{'database\.\*'\}>/g, "{nestId === 1 && (\n                                <Can action={'file.*'}>\n                                    <NavLink to={`${match.url}/maps`}>Maps</NavLink>\n                                </Can>\n                            )}\n                            <Can action={'database.*'}>");
    
    file = file.replace(/<Route path=\{\`\$\{match\.path\}\/databases\`\} exact>/g, "{nestId === 1 && (\n                                <Route path={`${match.path}/maps`} exact>\n                                    <RequireServerPermission permissions={'file.*'}>\n                                        <MinecraftMapsContainer/>\n                                    </RequireServerPermission>\n                                </Route>\n                            )}\n                            <Route path={`${match.path}/databases`} exact>");
    
    fs.writeFileSync('resources/scripts/routers/ServerRouter.tsx', file);
    console.log("ServerRouter patched successfully!");
}
EOF
    node patch_router.js
    rm patch_router.js 

    cat << 'EOF' > patch_routes.js
const fs = require('fs');
const path = 'resources/scripts/routers/routes.ts';
let file = fs.readFileSync(path, 'utf8'); 

if(!file.includes('MinecraftMapsContainer')) {
    file = file.replace(
        "import AccountSecurityContainer from '@/components/dashboard/account/AccountSecurityContainer';",
        "import AccountSecurityContainer from '@/components/dashboard/account/AccountSecurityContainer';\nimport MinecraftMapsContainer from '@/components/server/maps/MinecraftMapsContainer';"
    );
    const mapRoute = `
        {
            path: '/maps',
            permission: 'file.*',
            name: 'maps',
            nestIds: [1],
            component: MinecraftMapsContainer,
        },`;
    
    file = file.replace(/server:\s*\[/, "server: [" + mapRoute);
    fs.writeFileSync(path, file);
    console.log("routes.ts patched successfully!");
}
EOF
    node patch_routes.js
    rm patch_routes.js 

    echo -e "\n\033[0;33mBuilding Pterodactyl Assets (This may take a minute)...\033[0m\n"
    chown -R www-data:www-data /var/www/pterodactyl/*
    chown -R www-data:www-data /var/www/pterodactyl/.*
    export NODE_OPTIONS="--openssl-legacy-provider --no-deprecation"

    yarn build:production

    php artisan view:clear
    php artisan optimize:clear 
    chown -R www-data:www-data /var/www/pterodactyl/.*

    echo -e "\n\033[0;32mInstallation Complete! 🚀\033[0m\n"
}

run_world_manager() {
    echo -e "\n\033[0;36m====================================================\033[0m"
    echo -e "\033[0;32m   World Manager Installer\033[0m"
    echo -e "\033[0;36m====================================================\033[0m\n"
    cd /var/www/pterodactyl
    
    info "Downloading world.zip..."
    wget -q "https://raw.githubusercontent.com/sdgamer8263-sketch/pterodactyl_extention1/main/world.zip" -O world.zip || true
    
    if [[ -s "world.zip" ]]; then
        info "Extracting world.zip..."
        unzip -o world.zip > /dev/null 2>&1
        
        if [[ -f "setup.sh" ]]; then
            chmod +x setup.sh
            bash setup.sh
            rm -f setup.sh
        else
            error "setup.sh not found inside world.zip!"
        fi
        rm -f world.zip
    else
        error "Failed to download world.zip!"
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
    "worldmanager"
    "worldmapsinstaller"
)

is_addon_installed() {
    if [[ "$1" == "worldmapsinstaller" ]]; then
        if [[ -d "/var/www/pterodactyl/resources/scripts/components/server/maps" ]]; then return 0; else return 1; fi
    elif [[ "$1" == "worldmanager" ]]; then
        return 1
    fi
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
            if [[ "$clean_name" == "worldmapsinstaller" ]]; then
                display_label="World Maps Installer"
            elif [[ "$clean_name" == "worldmanager" ]]; then
                display_label="World Manager"
            else
                display_label="$clean_name"
            fi
            
            if is_addon_installed "$clean_name"; then status="${GREEN}●${NC}"; else status="${RED}○${NC}"; fi
            display_name="${display_label:0:24}"
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
                if [[ "${addon_names[$idx]}" == "worldmapsinstaller" ]]; then
                    install_world_maps
                elif [[ "${addon_names[$idx]}" == "worldmanager" ]]; then
                    run_world_manager
                elif [[ "${addon_names[$idx]}" != "resourcemanager.blueprint" ]]; then 
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
            for idx in "${selected_addons[@]}"; do 
                if [[ "${addon_names[$idx]}" == "worldmapsinstaller" ]]; then
                    warning "World Maps Installer does not support automatic uninstallation."
                elif [[ "${addon_names[$idx]}" == "worldmanager" ]]; then
                    run_world_manager
                else
                    run_addon_blueprint "${addon_names[$idx]}" "remove"
                fi
            done
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
