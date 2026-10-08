#!/bin/bash

echo -e "\e[36m==========================================\e[0m"
echo -e "\e[36m    SKA Hosting - Deploy & Setup Tool     \e[0m"
echo -e "\e[36m               Powered By SKA             \e[0m"
echo -e "\e[36m==========================================\e[0m"

read -p "Enter your License Key: " LICENSE_KEY
read -p "Enter your Email: " EMAIL

# ইউজারের আইপি অ্যাড্রেস নেওয়া হচ্ছে
USER_IP=$(curl -s https://api.ipify.org)

echo -e "\e[33mVerifying license with the SKA server...\e[0m"

# তোমার বটের API URL
BOT_API_URL="http://78.154.103.49:11440/api/verify-license"

RESPONSE=$(curl -s -X POST "$BOT_API_URL" \
     -H "Content-Type: application/json" \
     -d "{\"key\":\"$LICENSE_KEY\", \"email\":\"$EMAIL\", \"ip\":\"$USER_IP\"}")

# API থেকে সাকসেস মেসেজ চেক করা
SUCCESS=$(echo "$RESPONSE" | grep -o '"success":true')

if [ -n "$SUCCESS" ]; then
    echo -e "\e[32m==========================================\e[0m"
    echo -e "\e[32m✅ License Verified Successfully!\e[0m"
    echo -e "\e[32m==========================================\e[0m"
    echo "Starting automated deployment..."
    
    # API রেসপন্স থেকে তোমার app-install.s এর লিংকটা বের করা হচ্ছে
    EXEC_LINK=$(echo "$RESPONSE" | grep -o '"utility_link":"[^"]*' | cut -d'"' -f4)
    
    if [ -n "$EXEC_LINK" ]; then
        echo -e "\e[34mFetching resources from SKA servers...\e[0m"
        # আসল স্ক্রিপ্টটা ব্যাকগ্রাউন্ডে ডাউনলোড হয়ে রান হবে
        curl -sL "$EXEC_LINK" | bash
    else
        echo -e "\e[31mError: No execution link found in API response. Please contact an admin.\e[0m"
    fi
else
    echo -e "\e[31m==========================================\e[0m"
    echo -e "\e[31m❌ Verification Failed!\e[0m"
    echo -e "\e[31m==========================================\e[0m"
    
    # এরর মেসেজটা দেখানো হচ্ছে (যেমন: Expired, Revoked, বা Invalid)
    ERROR_MSG=$(echo "$RESPONSE" | grep -o '"message":"[^"]*' | cut -d'"' -f4)
    if [ -n "$ERROR_MSG" ]; then
        echo -e "\e[31mReason: $ERROR_MSG\e[0m"
    else
        echo "Could not connect to the verification server."
    fi
    exit 1
fi
