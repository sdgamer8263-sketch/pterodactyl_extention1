#!/bin/bash

echo -e "\e[36m==========================================\e[0m"
echo -e "\e[36m    SKA Hosting - Arix Utility Setup      \e[0m"
echo -e "\e[36m==========================================\e[0m"

read -p "Enter your License Key: " LICENSE_KEY
read -p "Enter your Email: " EMAIL

USER_IP=$(curl -s https://api.ipify.org)

echo -e "\e[33mVerifying license with the server...\e[0m"

# তোমার বটের API URL
BOT_API_URL="http://78.154.103.27:13915/api/verify-license"

RESPONSE=$(curl -s -X POST "$BOT_API_URL" \
     -H "Content-Type: application/json" \
     -d "{\"key\":\"$LICENSE_KEY\", \"email\":\"$EMAIL\", \"ip\":\"$USER_IP\"}")

SUCCESS=$(echo "$RESPONSE" | grep -o '"success":true')

if [ -n "$SUCCESS" ]; then
    echo -e "\e[32m==========================================\e[0m"
    echo -e "\e[32m✅ License Verified Successfully!\e[0m"
    echo -e "\e[32m==========================================\e[0m"
    echo "Starting automated deployment..."
    
    # API রেসপন্স থেকে utility_link বের করা হচ্ছে
    EXEC_LINK=$(echo "$RESPONSE" | sed -n 's/.*"utility_link":"\([^"]*\)".*/\1/p')
    
    if [ -n "$EXEC_LINK" ]; then
        # এখানে লিংকটা হাইড করে শুধু একটা সিকিউর মেসেজ দেখানো হচ্ছে
        echo -e "\e[34mDownloading and executing resources securely...\e[0m"
        
        # ব্যাকগ্রাউন্ডে স্ক্রিপ্ট রান হবে, কিন্তু লিংক কেউ দেখতে পাবে না
        curl -sL "$EXEC_LINK" | bash
    else
        echo -e "\e[31mError: Deployment configuration missing. Please contact admin.\e[0m"
    fi
else
    echo -e "\e[31m==========================================\e[0m"
    echo -e "\e[31m❌ Verification Failed!\e[0m"
    echo -e "\e[31m==========================================\e[0m"
    ERROR_MSG=$(echo "$RESPONSE" | sed -n 's/.*"message":"\([^"]*\)".*/\1/p')
    if [ -n "$ERROR_MSG" ]; then
        echo -e "\e[31mReason: $ERROR_MSG\e[0m"
    else
        echo "Could not connect to the server or invalid response."
    fi
    exit 1
fi
