#!/bin/bash

# কালার কোড (টার্মিনালে সুন্দর দেখানোর জন্য)
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${CYAN}=========================================================${NC}"
echo -e "${GREEN}      Pterodactyl & Arix Ultimate Rebranding Tool      ${NC}"
echo -e "${CYAN}=========================================================${NC}"
echo ""

# ইউজারের কাছ থেকে ইনপুট নেওয়া
echo -e "${YELLOW}Example: VIZION STORE, SKA HOSTING, etc.${NC}"
read -p "Enter your Brand Name: " BRAND_NAME

echo -e "\n${YELLOW}Example: 2026, 2026-2027, etc.${NC}"
read -p "Enter Copyright Year: " YEAR

if [ -z "$BRAND_NAME" ] || [ -z "$YEAR" ]; then
    echo -e "\nBrand Name and Year cannot be empty! Exiting..."
    exit 1
fi

# পিএইচপি স্ক্রিপ্টে ভেরিয়েবল পাঠানোর জন্য এক্সপোর্ট করা
export BRAND_NAME
export YEAR

echo -e "\n${CYAN}[1/3] Starting text replacement across all files...${NC}"

cd /var/www/pterodactyl
set +H

# পিএইচপি স্ক্রিপ্ট তৈরি এবং এক্সিকিউট করা
cat << 'EOF' > apply_rebrand.php
<?php
$brand = getenv('BRAND_NAME');
$year = getenv('YEAR');
$brand_service = $brand . " &copy; " . $year . " SOFTWARE SERVICE";

// ১. ফ্রন্টএন্ড React কপিরাইট চেঞ্জ
$files = [
    "/var/www/pterodactyl/resources/scripts/components/elements/PageContentBlock.tsx",
    "/var/www/pterodactyl/resources/scripts/components/auth/LoginFormContainer.tsx"
];
foreach ($files as $file) {
    if (file_exists($file)) {
        $content = file_get_contents($file);
        $content = preg_replace("/Pterodactyl&reg;/i", $brand, $content);
        $content = str_replace("https://pterodactyl.io", "#", $content);
        
        // ডিফল্ট সালগুলোকে কাস্টম সালে পরিবর্তন করা
        $content = preg_replace("/2015\s*-\s*\{new Date\(\)\.getFullYear\(\)\}/i", $year, $content);
        $content = preg_replace("/&copy;\s*2015\s*-\s*\d{4}/i", "&copy; " . $year, $content);
        
        file_put_contents($file, $content);
    }
}

// ২. অ্যাডমিন Blade কপিরাইট চেঞ্জ
$admin_file = "/var/www/pterodactyl/resources/views/layouts/admin.blade.php";
if (file_exists($admin_file)) {
    $content = file_get_contents($admin_file);
    $content = preg_replace(
        "/Copyright\s*(?:&copy;|©)\s*2015\s*-\s*(?:\{\{\s*date\(['\"]Y['\"]\)\s*\}\}|20[0-9]{2})\s*(?:<a[^>]*>)?Pterodactyl Software(?:<\/a>)?\.?/i", 
        $brand_service, 
        $content
    );
    file_put_contents($admin_file, $content);
}

// ৩. Blueprint এবং Arix-এর নাম চেঞ্জ (সমস্ত ফাইল স্ক্যান করে)
$dir = '/var/www/pterodactyl/resources';
$iterator = new RecursiveIteratorIterator(new RecursiveDirectoryIterator($dir));
foreach ($iterator as $file) {
    if ($file->isFile()) {
        $ext = $file->getExtension();
        if (in_array($ext, ['php', 'tsx', 'ts'])) {
            $content = file_get_contents($file->getPathname());
            $original_content = $content;

            // Blueprint রিপ্লেস
            if ($ext === 'php' && stripos($content, 'prpl.wtf') !== false) {
                $content = preg_replace('/Copyright.*?prpl\.wtf.*?contributors\./is', $brand_service, $content);
            }

            // Arix রিপ্লেস
            $content = str_replace('Arix Theme', $brand, $content);
            $content = str_replace('Arix Editor', $brand, $content);

            if ($content !== $original_content) {
                file_put_contents($file->getPathname(), $content);
            }
        }
    }
}
?>
EOF

php apply_rebrand.php
rm apply_rebrand.php
set -H

echo -e "\n${CYAN}[2/3] Rebuilding frontend assets (This may take 2-3 minutes)...${NC}"
export NODE_OPTIONS=--openssl-legacy-provider
yarn build:production

echo -e "\n${CYAN}[3/3] Clearing cache and fixing permissions...${NC}"
php artisan view:clear
php artisan cache:clear
chown -R www-data:www-data /var/www/pterodactyl/*

echo -e "\n${GREEN}=========================================================${NC}"
echo -e "${GREEN}  SUCCESS: Panel has been rebranded to $BRAND_NAME!  ${NC}"
echo -e "${GREEN}=========================================================${NC}"
