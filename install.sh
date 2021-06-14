#!/bin/bash

# Colors variables
YELLOW="\033[1;33m"
GREEN="\033[0;32m"
NC='\033[0m' # No Color

mkdir pt-project
git clone https://github.com/AlexDz27/pt-project.git pt-project/

cd pt-project/

printf "\n"
echo "Installing database... Enter your MySQL root user password."
mysql -u root -p < ../db-data/db-dump.sql
echo "Database installed."
printf "\n"

printf "\n"
printf "${YELLOW}Enter your sudo password to apply proper permissions for Laravel and to perform other operations:${NC}"
printf "\n"
sudo chgrp -R www-data storage/

npm install
composer install

npm run build:dev

cat > .env <<'end'
APP_NAME=Laravel
APP_ENV=local
APP_KEY=base64:0n3lj54/HJoDXlKARYeUSvnYv6M7w80IsQtZpwS50aY=
APP_DEBUG=true
APP_URL=http://pt-project.tst.au
APP_API_URL=http://pt-project.tst.au/api

DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=pt-project-tst
DB_USERNAME=root
DB_PASSWORD=root

GOOGLE_CLIENT_ID=361807096841-32gv09eniekmf839kqm2bq6lv8ojd47v.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=AIzaSyBnNLOQdvLFnK81RYRa4E2loATRcCDCxeg
GOOGLE_REDIRECT=http://pt-project.tst.au/auth/oauth/google
end

mkdir public/css/images
cp .openstreemaps-icons/* public/css/images

# Setting up server -----------------------------------------------------------------------------------------------------

cd /etc
sudo cp hosts hosts.backup
echo "127.0.0.1 pt-project.tst.au" | sudo tee -a hosts > /dev/null

cd /etc/nginx/sites-available
# Remember to change root afterwards
sudo tee pt-project.tst.au.conf > /dev/null <<'end'
server {
    listen 80;
    server_name pt-project.tst.au;
    root /home/aliaksei/Projects/Yulia/install-pt-project-script/pt-project/public;

    add_header X-Frame-Options "SAMEORIGIN";
    add_header X-XSS-Protection "1; mode=block";
    add_header X-Content-Type-Options "nosniff";

    index index.php;

    charset utf-8;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location = /favicon.ico { access_log off; log_not_found off; }
    location = /robots.txt  { access_log off; log_not_found off; }

    error_page 404 /index.php;

    location ~ \.php$ {
        fastcgi_pass unix:/var/run/php/php8.0-fpm.sock;
        fastcgi_param SCRIPT_FILENAME $realpath_root$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~ /\.(?!well-known).* {
        deny all;
    }
}
end

cd ../sites-enabled
sudo ln -s ../sites-available/pt-project.tst.au.conf

sudo nginx -s reload

printf "${GREEN}\nInstallation complete. \U2728${NC}\n"
google-chrome http://pt-project.tst.au