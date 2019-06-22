#!/usr/bin/env bash

# Laravel homestead original provisioning script
# https://github.com/laravel/settler

# Update Package List
apt-get update
apt-get upgrade -y

# Force Locale
apt-get install -y locales
echo "LC_ALL=en_US.UTF-8" >> /etc/default/locale
locale-gen en_US.UTF-8
export LANG=en_US.UTF-8

# Basic packages
apt-get install -y sudo software-properties-common curl \
build-essential dos2unix gcc git git-flow libpcre3-dev apt-utils \
make python2.7-dev python-pip re2c supervisor unattended-upgrades whois vim zip unzip

# PPA
apt-add-repository ppa:ondrej/php -y

# Update Package Lists
apt-get update

# Timezone
ln -sf /usr/share/zoneinfo/UTC /etc/localtime

# PHP
apt-get install -y php7.2-cli php7.2-dev \
php7.2-mysql php7.2-pgsql php7.2-sqlite3 php7.2-soap \
php7.2-json php7.2-curl php7.2-gd \
php7.2-gmp php7.2-imap php-xdebug \
php7.2-mbstring php7.2-zip \
php-pear php-apcu php-memcached php-redis \
php7.2-dom

# Nginx & PHP-FPM
apt-get install -y nginx php7.2-fpm

# Install Composer
curl -sS https://getcomposer.org/installer | php
mv composer.phar /usr/local/bin/composer

# Set Some PHP CLI Settings
sed -i "s/error_reporting = .*/error_reporting = E_ALL/" /etc/php/7.2/cli/php.ini
sed -i "s/display_errors = .*/display_errors = On/" /etc/php/7.2/cli/php.ini
sed -i "s/memory_limit = .*/memory_limit = 512M/" /etc/php/7.2/cli/php.ini
sed -i "s/;date.timezone.*/date.timezone = UTC/" /etc/php/7.2/cli/php.ini

sed -i "s/.*daemonize.*/daemonize = no/" /etc/php/7.2/fpm/php-fpm.conf
sed -i "s/error_reporting = .*/error_reporting = E_ALL/" /etc/php/7.2/fpm/php.ini
sed -i "s/display_errors = .*/display_errors = On/" /etc/php/7.2/fpm/php.ini
sed -i "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/" /etc/php/7.2/fpm/php.ini
sed -i "s/memory_limit = .*/memory_limit = 512M/" /etc/php/7.2/fpm/php.ini
sed -i "s/;date.timezone.*/date.timezone = UTC/" /etc/php/7.2/fpm/php.ini

# Enable Remote xdebug
echo "xdebug.remote_enable = 1" >> /etc/php/7.2/fpm/conf.d/20-xdebug.ini
echo "xdebug.remote_connect_back = 1" >> /etc/php/7.2/fpm/conf.d/20-xdebug.ini
echo "xdebug.remote_port = 9000" >> /etc/php/7.2/fpm/conf.d/20-xdebug.ini
echo "xdebug.var_display_max_depth = -1" >> /etc/php/7.2/fpm/conf.d/20-xdebug.ini
echo "xdebug.var_display_max_children = -1" >> /etc/php/7.2/fpm/conf.d/20-xdebug.ini
echo "xdebug.var_display_max_data = -1" >> /etc/php/7.2/fpm/conf.d/20-xdebug.ini
echo "xdebug.max_nesting_level = 500" >> /etc/php/7.2/fpm/conf.d/20-xdebug.ini

# Not xdebug when on cli
phpdismod -s cli xdebug

# Set The Nginx & PHP-FPM User
sed -i '1 idaemon off;' /etc/nginx/nginx.conf
sed -i "s/user www-data;/" /etc/nginx/nginx.conf
sed -i "s/# server_names_hash_bucket_size.*/server_names_hash_bucket_size 64;/" /etc/nginx/nginx.conf

mkdir -p /run/php
touch /run/php/php7.2-fpm.sock
sed -i "s/user = www-data/" /etc/php/7.2/fpm/pool.d/www.conf
sed -i "s/group = www-data/" /etc/php/7.2/fpm/pool.d/www.conf
sed -i "s/;listen\.owner.*/" /etc/php/7.2/fpm/pool.d/www.conf
sed -i "s/;listen\.group.*/" /etc/php/7.2/fpm/pool.d/www.conf
sed -i "s/;listen\.mode.*/listen.mode = 0666/" /etc/php/7.2/fpm/pool.d/www.conf

# Install Node
curl --silent --location https://deb.nodesource.com/setup_8.x | bash -
apt-get install -y nodejs

# Install Yarn
curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
sudo apt-get update && sudo apt-get install yarn

# Install SQLite
apt-get install -y sqlite3 libsqlite3-dev

# Memcached
apt-get install -y memcached

# Beanstalkd
apt-get install -y beanstalkd
sed -i "s/#START=yes/START=yes/" /etc/default/beanstalkd

# Redis
apt-get install -y redis-server
sed -i "s/daemonize yes/daemonize no/" /etc/redis/redis.conf

# Configure default nginx site
block="server {
    listen 80;
    server_name localhost;
    root /var/www/html;

    index index.html index.htm index.php index.nginx-debian.html;

    charset utf-8;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location = /favicon.ico { access_log off; log_not_found off; }
    location = /robots.txt  { access_log off; log_not_found off; }

    access_log off;
    error_log  /var/log/nginx/localhost-error.log error;

    error_page 404 /index.php;

    sendfile off;

    location ~ \.php$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass unix:/run/php/php7.2-fpm.sock;
        fastcgi_index index.php;
        # include fastcgi_params;
        include fastcgi.conf;
    }

    location ~ /\.ht {
        deny all;
    }
}
"

rm /etc/nginx/sites-enabled/default
rm /etc/nginx/sites-available/default

echo "$block" > "/etc/nginx/sites-available/default"
ln -fs "/etc/nginx/sites-available/default" "/etc/nginx/sites-enabled/default"
supervisorctl restart nginx
