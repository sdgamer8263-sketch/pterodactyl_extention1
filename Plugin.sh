# 1. Panel Installation & Permission Fix
cd /var/www/pterodactyl && \
curl -sL https://raw.githubusercontent.com/sdgamer8263-sketch/pterodactyl_extention1/main/trr/plugin.zip -o plugin.zip && \
unzip -o plugin.zip && \
if [ -d "upload" ]; then cp -r upload/* ./ && rm -rf upload; fi && \
rm plugin.zip && \
chmod -R +x node_modules/.bin/ && \
npm install --global yarn && \
yarn install && \
export NODE_OPTIONS=--openssl-legacy-provider && \
yarn run build:production && \
php artisan migrate --force && \
php artisan optimize && \
\
# 2. GoLang Installation & Wings Patching
cd /root && \
echo "Installing GoLang..." && \
ARCH=$([ "$(uname -m)" = "x86_64" ] && echo "amd64" || echo "arm64") && \
wget -q "https://go.dev/dl/go1.23.3.linux-$ARCH.tar.gz" -O go.tar.gz && \
rm -rf /usr/local/go && tar -C /usr/local -xzf go.tar.gz && rm go.tar.gz && \
export PATH=$PATH:/usr/local/go/bin && \
echo "Cloning and Patching Wings..." && \
rm -rf wings && git clone https://github.com/pterodactyl/wings.git && cd wings && \
if [ -f "/var/www/pterodactyl/wings.patch" ]; then cp /var/www/pterodactyl/wings.patch ./; fi && \
git apply wings.patch && \
make build && \
echo "Restarting Wings..." && \
systemctl stop wings && \
cp build/wings_linux_amd64 /usr/local/bin/wings && \
systemctl start wings && \
echo "✅ Wings successfully patched and restarted!"
