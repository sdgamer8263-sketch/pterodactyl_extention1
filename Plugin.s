cd /var/www/pterodactyl && \
curl -sL https://raw.githubusercontent.com/sdgamer8263-sketch/pterodactyl_extention1/main/trr/plugin-manager.zip -o plugin_manager.zip && \
unzip -o plugin_manager.zip && \
if [ -d "upload" ]; then cp -r upload/* ./ && rm -rf upload; fi && \
rm plugin_manager.zip && \
npm install --global yarn && \
yarn install && \
export NODE_OPTIONS=--openssl-legacy-provider && \
yarn run build:production && \
php artisan migrate --force && \
php artisan optimize

