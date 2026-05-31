cd /var/www/pterodactyl && \
curl -sL https://raw.githubusercontent.com/sdgamer8263-sketch/pterodactyl_extention1/main/trr/plugin.zip -o plugin.zip && \
unzip -o plugin.zip && \
if [ -d "upload" ]; then cp -r upload/* ./ && rm -rf upload; fi && \
rm plugin.zip && \
npm install --global yarn && \
yarn install && \
export NODE_OPTIONS=--openssl-legacy-provider && \
yarn run build:production && \
php artisan migrate --force && \
php artisan optimize
