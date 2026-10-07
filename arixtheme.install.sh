#!/bin/bash

echo "=========================================="
echo "    SKA Hosting - Arix Utility Setup      "
echo "=========================================="

read -p "Enter your License Key: " LICENSE_KEY
read -p "Enter your Email: " EMAIL

USER_IP=$(curl -s https://api.ipify.org)

echo "Verifying license with the server..."

BOT_API_URL="http://78.154.103.49:11440/api/verify-license"

RESPONSE=$(curl -s -X POST "$BOT_API_URL" \
     -H "Content-Type: application/json" \
     -d "{\"key\":\"$LICENSE_KEY\", \"email\":\"$EMAIL\", \"ip\":\"$USER_IP\"}")

SUCCESS=$(echo "$RESPONSE" | grep -o '"success":true')

if [ -n "$SUCCESS" ]; then
    echo "=========================================="
    echo "✅ License Verified Successfully!"
    echo "=========================================="
    echo "Running further installation steps..."
else
    echo "=========================================="
    echo "❌ Verification Failed!"
    echo "=========================================="
    echo "$RESPONSE"
    exit 1
fi
