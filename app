#!/bin/bash
set +e

echo -e "\033[1;36m====================================================\033[0m"
echo -e "\033[1;32m      Arix v2.1.0 (Blueprint Edition) Manager\033[0m"
echo -e "\033[1;36m====================================================\033[0m\n"

echo -e "  [ 1 ] Install Theme"
echo -e "  [ 2 ] Uninstall Theme"
echo -e "  [ 3 ] Update Theme"
echo -e "  [ 0 ] Exit\n"

read -p " ➜ Choose an action: " ACTION < /dev/tty

if [ "$ACTION" == "1" ]; then
    # ==========================================
    # INSTALL PROCESS (2.1.0 Blueprint)
    # ==========================================
    echo -e "\n[+] Installing Arix v2.1.0 Blueprint..."
    cd /var/www/pterodactyl 

    curl -sL -o pterodactyl.zip "https://raw.githubusercontent.com/sdgamer8263-sketch/pterodactyl_extention1/main/pterodactyl.zip"
    unzip -o pterodactyl.zip > /dev/null 2>&1
    if [ -d "pterodactyl" ]; then cp -rf pterodactyl/* ./; rm -rf pterodactyl; fi
    rm pterodactyl.zip 

    # Injecting Arix.php Module
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
            if ($action === "install") { $this->install(); } 
            elseif ($action === "update") { $this->update(); } 
            elseif ($action === "uninstall") { $this->uninstall(); } 
            else { $this->error("Invalid action. Supported actions: install, update, uninstall"); }
        }
    } 
    public function installOrUpdate($isUpdate = false)
    {
        if ($isUpdate) {
            $this->info("\n    This command is not recommended to use. \n   This command skips frequently used files by addons during theme updating to avoid losing your addon customizations.\n   If you still experience an error after updating please contact us.");
        } 
        $confirmation = $this->confirm("Are all the required dependencies installed from the readme file?", "yes");
        if (!$confirmation) { return; } 
        $versions = File::directories("./arix");
        if (empty($versions)) { $this->info("No versions found in /arix directory."); return; } 
        $version = basename($this->choice("Select a version:", $versions));
        $this->info("Installing Arix Theme {$version}..."); 
        $excludeOption = $isUpdate ? "--exclude='routes.ts' --exclude='getServer.ts' --exclude='admin.blade.php' --exclude='admin.php' --exclude='ServerTransformer.php'" : '';
        exec("rsync -a {$excludeOption} arix/{$version}/ ./"); 
        $directoryPath = app_path("Http/Controllers/Admin/Arix");
        File::makeDirectory($directoryPath, 0755, true, true); 
        $filesOne = ["ArixController", "ArixAdvancedController", "ArixAnnouncementController", "ArixColorsController", "ArixComponentsController", "ArixDashboardController", "ArixLayoutController"];
        $this->info("Proceeding with the installation...");
        foreach ($filesOne as $file) { $this->aa($file, $version, $directoryPath); sleep(1); } 
        $filesTwo = ["ArixLinkController", "ArixMailController", "ArixMetaController", "ArixPresetController", "ArixSocialController", "ArixStylingController"];
        foreach ($filesTwo as $file) { $this->aa($file, $version, $directoryPath); sleep(1); } 
        $this->info("Migrating database...");
        $this->command("php artisan migrate --force"); 
        $this->info("Installing required packages...");
        $this->command("yarn add react-email-editor react-colorful recharts@^2.15.4 ua-parser-js cronstrue react-day-picker jszip react-turnstile @dnd-kit/core @dnd-kit/sortable @dnd-kit/utilities @types/md5 md5 react-icons@5.4.0 markdown-to-jsx@7.7.10 i18next-browser-languagedetector@7.2.1"); 
        $this->info("Compile translations...");
        $this->command("php artisan language:compile"); 
        $this->info("Building panel assets...");
        $nodeVersion = shell_exec("node -v");
        $nodeVersion = (int) ltrim($nodeVersion, "v");
        if ($nodeVersion >= 17) { putenv("NODE_OPTIONS=--openssl-legacy-provider"); } 
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
        if (File::exists($localSource)) { File::copy($localSource, $filePath); } 
        else { $this->error("Fail: Could not find local {$filename}.php at {$localSource}."); }
    }
    public function install() { $this->installOrUpdate(); } 
    public function update() { $this->installOrUpdate(true); } 
    private function uninstall()
    {
        $this->command("php artisan down");
        $this->command("curl -L https://github.com/pterodactyl/panel/releases/latest/download/panel.tar.gz | tar -xzv");
        $this->command("chmod -R 755 storage/* bootstrap/cache");
        $this->command("composer install --no-dev --optimize-autoloader");
        $this->command("php artisan view:clear");
        $this->command("php artisan config:clear");
        $this->command("php artisan migrate --seed --force");
        $this->command("chown -R www-data:www-data " . base_path() . "/*");
        $this->command("php artisan queue:restart");
        $this->command("php artisan up");
        $this->info("Arix Theme uninstalled successfully.");
    } 
    private function command($cmd) { return exec($cmd); }
}
EOF

    php artisan arix install < /dev/tty
    
    echo -e "\n[+] Compiling Panel..."
    export NODE_OPTIONS=--openssl-legacy-provider
    yarn add xterm-addon-unicode11 > /dev/null 2>&1
    yarn build:production
    
    echo -e "\n[+] Setting Permissions..."
    curl -sL https://raw.githubusercontent.com/pterodactyl/panel/master/public/index.php -o public/index.php > /dev/null 2>&1
    chown -R www-data:www-data /var/www/pterodactyl 2>/dev/null || true
    chmod -R 775 storage/* bootstrap/cache/
    chown -R www-data:www-data /var/www/pterodactyl/*
    
    echo -e "\033[1;32m[✔] Theme Installed Successfully!\033[0m"

elif [ "$ACTION" == "2" ]; then
    # ==========================================
    # UNINSTALL PROCESS
    # ==========================================
    echo -e "\n[+] Uninstalling Theme..."
    cd /var/www/pterodactyl 
    php artisan arix uninstall < /dev/tty
    echo -e "\033[1;32m[✔] Theme Uninstalled Successfully!\033[0m"

elif [ "$ACTION" == "3" ]; then
    # ==========================================
    # UPDATE PROCESS
    # ==========================================
    echo -e "\n[+] Updating Theme..."
    cd /var/www/pterodactyl 
    
    grep -rl "2.1.[0-9]" resources/ config/ app/ 2>/dev/null | xargs -r sed -i 's/2.1.[0-9]/2.1.2/g' || true
    php artisan view:clear > /dev/null 2>&1
    php artisan optimize:clear > /dev/null 2>&1
    sed -i "s/'version' => '[0-9.]*'/'version' => '1.15.1'/g" config/app.php || true
    php artisan config:clear > /dev/null 2>&1
    php artisan optimize:clear > /dev/null 2>&1
    
    echo -e "\n[+] Compiling Update..."
    yarn add xterm-addon-unicode11 > /dev/null 2>&1
    export NODE_OPTIONS=--openssl-legacy-provider
    yarn build:production
    
    echo -e "\033[1;32m[✔] Theme Updated Successfully!\033[0m"
    
elif [ "$ACTION" == "0" ]; then
    echo "Exiting..."
    exit 0
else
    echo -e "\033[1;31mInvalid option selected.\033[0m"
fi
