#!/bin/bash

# ==========================================
# Arix Installer — with License Verification
# ==========================================
# Replace this URL with your deployed Replit domain:
API_BASE="https://73f321e9-f115-437b-bf40-e886bdbac313-00-370t6wnuyqhmw.pike.replit.dev/api"

set -e

GREEN='\033[0;32m'
CYAN='\033[0;36m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
BLUE='\033[0;34m'
NC='\033[0m'

DOWNLOAD_URL=""
INSTALL_TYPE=""
USER_EMAIL=""
USER_LICENSE=""

# ==========================================
# BANNER FUNCTION
# ==========================================
show_banner() {
    clear
    echo -e "${CYAN}"
    echo '    _       ____   _____  __  __  '
    echo '   / \     |  _ \ |_ _|  \ \/ /  '
    echo '  / _ \    | |_) | | |    \  /   '
    echo ' / ___ \   |  _ <  | |    /  \   '
    echo '/_/   \_\  |_| \_\|___|  /_/\_\  '
    echo -e "${NC}"
    echo -e " ${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "  ${YELLOW}⚡ Arix Theme Installer${NC} ${CYAN}v2.1.0${NC}"
    echo -e " ${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

# ==========================================
# LICENSE VERIFICATION FUNCTION
# ==========================================
verify_license() {
    local install_type="$1"
    INSTALL_TYPE="$install_type"

    echo ""
    echo -e " ${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "  ${YELLOW}🔑 License Verification Required${NC}"
    echo -e " ${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    # Step 1: Ask for email
    read -p "  📧 Enter your registered Email: " USER_EMAIL

    if [ -z "$USER_EMAIL" ]; then
        echo -e "\n  ${RED}❌ Email cannot be empty. Exiting.${NC}\n"
        exit 1
    fi

    echo ""
    echo -e "  ${CYAN}⏳ Checking your email...${NC}"

    # Call API to check email
    EMAIL_RESPONSE=$(curl -s -X POST "${API_BASE}/licenses/check-email" \
        -H "Content-Type: application/json" \
        -d "{\"email\":\"${USER_EMAIL}\"}" \
        2>/dev/null)

    if [ $? -ne 0 ] || [ -z "$EMAIL_RESPONSE" ]; then
        echo -e "\n  ${RED}❌ Unable to reach the license server. Please check your internet connection.${NC}\n"
        exit 1
    fi

    # Parse response
    EMAIL_VALID=$(echo "$EMAIL_RESPONSE" | grep -o '"valid":[^,}]*' | cut -d: -f2 | tr -d ' "')
    EMAIL_BANNED=$(echo "$EMAIL_RESPONSE" | grep -o '"banned":[^,}]*' | cut -d: -f2 | tr -d ' "')
    EMAIL_MSG=$(echo "$EMAIL_RESPONSE" | grep -o '"message":"[^"]*"' | cut -d'"' -f4)
    LICENSE_TYPE=$(echo "$EMAIL_RESPONSE" | grep -o '"licenseType":"[^"]*"' | cut -d'"' -f4)

    # Check if banned
    if [ "$EMAIL_BANNED" = "true" ]; then
        echo ""
        echo -e " ${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "  ${RED}🚫 Your email is banned!${NC}"
        echo -e "  ${RED}${EMAIL_MSG}${NC}"
        echo -e " ${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""
        exit 1
    fi

    # Check if valid
    if [ "$EMAIL_VALID" != "true" ]; then
        echo ""
        echo -e "  ${RED}❌ ${EMAIL_MSG}${NC}"
        echo ""
        exit 1
    fi

    echo -e "  ${GREEN}✅ Email verified!${NC}"

    # Step 2: Ask for license key
    echo ""
    read -p "  🗝️  Enter your License Key (ARIX-XXXX-XXXX-XXXX-XXXX): " USER_LICENSE

    if [ -z "$USER_LICENSE" ]; then
        echo -e "\n  ${RED}❌ License key cannot be empty. Exiting.${NC}\n"
        exit 1
    fi

    echo ""
    echo -e "  ${CYAN}⏳ Verifying your license key...${NC}"

    # Call API to verify license
    VERIFY_RESPONSE=$(curl -s -X POST "${API_BASE}/licenses/verify" \
        -H "Content-Type: application/json" \
        -d "{\"email\":\"${USER_EMAIL}\",\"licenseKey\":\"${USER_LICENSE}\",\"installType\":\"${install_type}\"}" \
        2>/dev/null)

    if [ $? -ne 0 ] || [ -z "$VERIFY_RESPONSE" ]; then
        echo -e "\n  ${RED}❌ Unable to reach the license server.${NC}\n"
        exit 1
    fi

    VERIFY_VALID=$(echo "$VERIFY_RESPONSE" | grep -o '"valid":[^,}]*' | cut -d: -f2 | tr -d ' "')
    VERIFY_MSG=$(echo "$VERIFY_RESPONSE" | grep -o '"message":"[^"]*"' | cut -d'"' -f4)
    EXPIRES_AT=$(echo "$VERIFY_RESPONSE" | grep -o '"expiresAt":"[^"]*"' | cut -d'"' -f4)

    if [ "$VERIFY_VALID" != "true" ]; then
        echo ""
        echo -e " ${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "  ${RED}❌ License verification failed!${NC}"
        echo -e "  ${RED}${VERIFY_MSG}${NC}"
        echo -e " ${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""
        exit 1
    fi

    echo -e "  ${GREEN}✅ License verified!${NC}"
    if [ -n "$EXPIRES_AT" ] && [ "$EXPIRES_AT" != "null" ]; then
        echo -e "  ${YELLOW}⏳ Expires: ${EXPIRES_AT}${NC}"
    else
        echo -e "  ${PURPLE}♾️  Lifetime License${NC}"
    fi
    echo ""
}

# ==========================================
# LOG INSTALLATION TO BOT
# ==========================================
log_installation() {
    local install_type="$1"
    local version="$2"

    # Get public IP
    USER_IP=$(curl -s https://api.ipify.org 2>/dev/null || echo "unknown")

    curl -s -X POST "${API_BASE}/licenses/log-install" \
        -H "Content-Type: application/json" \
        -d "{\"email\":\"${USER_EMAIL}\",\"ip\":\"${USER_IP}\",\"installType\":\"${install_type}\",\"version\":\"${version}\"}" \
        > /dev/null 2>&1 || true
}

# ==========================================
# MENU FUNCTIONS
# ==========================================
non_blueprint_menu() {
    while true; do
        show_banner
        echo -e " ${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "  ${GREEN}📦 Arix — Non-Blueprint Version${NC}"
        echo -e " ${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""
        echo "  1) 🟢 Arix v2.1.0"
        echo "  2) 🔙 Back to Main Menu"
        echo ""
        read -p "  Select an option [1-2]: " nb_choice

        case $nb_choice in
            1)
                DOWNLOAD_URL="https://raw.githubusercontent.com/sdgamer8263-sketch/pterodactyl_extention1/main/sd/v210/pterodactyl.zip"
                NB_VERSION="v2.1.0"

                # License verification
                verify_license "non-blueprint"

                # Log installation
                log_installation "non-blueprint" "$NB_VERSION"

                break 2
                ;;
            2)
                break
                ;;
            *)
                echo -e "\n  ${RED}❌ Invalid option! Please try again.${NC}"
                sleep 1
                ;;
        esac
    done
}

blueprint_menu() {
    while true; do
        show_banner
        echo -e " ${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "  ${BLUE}🔵 Arix — Blueprint Supported Version${NC}"
        echo -e " ${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""
        echo "  1) 🔵 Arix v2.1.0 [with Translation Pack]"
        echo "  2) 🔙 Back to Main Menu"
        echo ""
        read -p "  Select an option [1-2]: " b_choice

        case $b_choice in
            1)
                DOWNLOAD_URL="https://raw.githubusercontent.com/sdgamer8263-sketch/pterodactyl_extention1/main/pterodactyl.zip"
                BP_VERSION="v2.1.0-blueprint"

                # License verification
                verify_license "blueprint"

                # Log installation
                log_installation "blueprint" "$BP_VERSION"

                break 2
                ;;
            2)
                break
                ;;
            *)
                echo -e "\n  ${RED}❌ Invalid option! Please try again.${NC}"
                sleep 1
                ;;
        esac
    done
}

# ==========================================
# MAIN MENU
# ==========================================
while true; do
    show_banner
    echo -e " ${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "  ${YELLOW}📂 Choose Installation Type${NC}"
    echo -e " ${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "  a) 🟢 Arix Non-Blueprint Version"
    echo "  b) 🔵 Arix Blueprint Supported Version"
    echo "  q) 🚪 Quit Installer"
    echo ""
    read -p "  Select an option [a/b/q]: " main_choice

    case $main_choice in
        a|A)
            non_blueprint_menu
            ;;
        b|B)
            blueprint_menu
            ;;
        q|Q)
            echo -e "\n  ${YELLOW}👋 Exiting Installer...${NC}\n"
            exit 0
            ;;
        *)
            echo -e "\n  ${RED}❌ Invalid option! Please try again.${NC}"
            sleep 1
            ;;
    esac

    if [ -n "$DOWNLOAD_URL" ]; then
        break
    fi
done

# ==========================================
# REQUIREMENTS
# ==========================================
show_banner
echo -e " ${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "  ${YELLOW}📦 Installing Requirements...${NC}"
echo -e " ${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

apt-get update -y > /dev/null 2>&1
apt-get install -y unzip curl wget > /dev/null 2>&1
echo -e "  ${GREEN}✅ Requirements installed.${NC}"

cd /var/www/pterodactyl || { echo -e "\n  ${RED}❌ /var/www/pterodactyl not found. Is Pterodactyl installed?${NC}\n"; exit 1; }

# ==========================================
# PHASE 1: DOWNLOAD & EXTRACT ARIX THEME
# ==========================================
echo ""
echo -e " ${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "  ${YELLOW}🚀 Arix Theme Installation${NC}"
echo -e " ${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "  ${CYAN}→ Downloading Arix theme...${NC}"
curl -# -L -o pterodactyl.zip "$DOWNLOAD_URL"

echo -e "  ${CYAN}→ Extracting files...${NC}"
unzip -o pterodactyl.zip > /dev/null 2>&1

# FIX: Nested folder problem
if [ -d "pterodactyl" ]; then
    cp -rf pterodactyl/* ./
    rm -rf pterodactyl
fi
rm -f pterodactyl.zip

# ==========================================
# FIX: ARIX SYNTAX & SECURITY PATCH
# ==========================================
echo -e "  ${CYAN}→ Applying Safe Arix.php patch...${NC}"
cat << 'PHPEOF' > app/Console/Commands/Arix.php
<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Support\Facades\File;
use Symfony\Component\Console\Formatter\OutputFormatterStyle;

class Arix extends Command
{
    protected $signature = 'arix {action?}';
    protected $description = 'Arix Theme Management';

    public function handle()
    {
        $action = $this->argument("action");
        $title = new OutputFormatterStyle("#fff", null, ["bold"]);
        $this->output->getFormatter()->setStyle("title", $title);
        $b = new OutputFormatterStyle(null, null, ["bold"]);
        $this->output->getFormatter()->setStyle("b", $b);
        if ($action === null) {
            $this->line("\r\n \r\n ░█████╗░██████╗░██╗██╗░░██╗\r\n ██╔══██╗██╔══██╗██║╚██╗██╔╝\r\n ███████║██████╔╝██║░╚███╔╝░\r\n ██╔══██║██╔══██╗██║░██╔██╗░\r\n ██║░░██║██║░░██║██║██╔╝╚██╗\r\n ╚═╝░░╚═╝╚═╝░░╚═╝╚═╝╚═╝░░╚═╝\r\n\r\n Thank you for purchasing Arix\r\n\r\n > php artisan arix (this window)\r\n > php artisan arix install\r\n > php artisan arix update\r\n > php artisan arix uninstall\r\n ");
        } else {
            $this->info("\n Arix Theme\n \n");
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
            $this->info("\n This command is not recommended to use. \n This command skips frequently used files by addons during theme updating to avoid losing your addon customizations.\n If you still experience an error after updating please contact us.");
        }
        $confirmation = $this->confirm("Are all the required dependencies installed from the readme file?", "yes");
        if (!$confirmation) { return; }
        $versions = File::directories("./arix");
        if (empty($versions)) { $this->info("No versions found in /arix directory."); return; }
        $version = $this->choice("Select a version:", $versions);
        $this->info("Installing Arix Theme {$version}...");
        $excludeOption = $isUpdate ? "--exclude='routes.ts' --exclude='getServer.ts' --exclude='admin.blade.php' --exclude='admin.php' --exclude='ServerTransformer.php'" : '';
        exec("rsync -a {$excludeOption} arix/{$version}/ ./");
        $directoryPath = app_path("Http/Controllers/Admin/Arix");
        File::makeDirectory($directoryPath, 0755, true, true);
        $filesOne = ["ArixController","ArixAdvancedController","ArixAnnouncementController","ArixColorsController","ArixComponentsController","ArixDashboardController","ArixLayoutController"];
        $this->info("Proceeding with the installation...");
        foreach ($filesOne as $file) { $this->aa($file, $version, $directoryPath); sleep(1); }
        $filesTwo = ["ArixLinkController","ArixMailController","ArixMetaController","ArixPresetController","ArixSocialController","ArixStylingController"];
        foreach ($filesTwo as $file) { $this->aa($file, $version, $directoryPath); sleep(1); }
        $this->command("php artisan migrate --force");
        $this->info("This can take a minute...");
        $this->command("yarn add react-email-editor react-colorful recharts@^2.15.4 ua-parser-js cronstrue react-day-picker jszip react-turnstile @dnd-kit/core @dnd-kit/sortable @dnd-kit/utilities @types/md5 md5 react-icons@5.4.0 markdown-to-jsx@7.7.10 i18next-browser-languagedetector@7.2.1");
        $this->info("Compile translations...");
        $this->command("php artisan language:compile");
        $this->info("Building panel assets...");
        $this->info("This can take a minute...");
        $nodeVersion = shell_exec("node -v");
        $nodeVersion = (int) ltrim($nodeVersion, "v");
        if ($nodeVersion >= 17) { putenv("NODE_OPTIONS=--openssl-legacy-provider"); }
        $this->command("yarn build:production");
        $this->command("chown -R www-data:www-data /var/www/pterodactyl/* " . base_path() . "/");
        $this->command("chown -R nginx:nginx " . base_path() . "/*");
        $this->command("chown -R apache:apache " . base_path() . "/");
        $this->command("php artisan optimize:clear");
        $this->command("php artisan optimize");
        $this->command("php artisan queue:restart");
        $message = $isUpdate ? "│ Theme updated successfully │" : "│ Theme installed successfully │";
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

    public function install() { $this->info("Loading modules..."); sleep(1); $this->installOrUpdate(); $this->info("Arix Theme installation completed safely!"); }
    public function update() { $this->installOrUpdate(true); }

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
        $this->command("chown -R apache:apache " . base_path() . "/");
        $this->command("php artisan queue:restart");
        $this->command("php artisan up");
        $this->info("Arix Theme uninstalled successfully.");
    }

    private function command($cmd) { return exec($cmd); }
}
PHPEOF

echo -e "  ${CYAN}→ Running Arix installer...${NC}"
php artisan arix install

echo -e "  ${CYAN}→ Building the Pterodactyl Panel (Takes 2-5 minutes, DO NOT CLOSE)...${NC}"
yarn add xterm-addon-unicode11 > /dev/null 2>&1
yarn build

# ==========================================
# PHASE 2: PERMISSIONS & CACHE FIXES
# ==========================================
set +e
echo ""
echo -e " ${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "  ${YELLOW}🔧 Applying Permissions & Cache Fixes...${NC}"
echo -e " ${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

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

echo ""
echo -e " ${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "  ${GREEN}🎉 Arix Theme Installed Successfully!${NC}"
echo -e "  ${GREEN}✅ All done! Enjoy your Arix theme.${NC}"
echo -e " ${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
