#!/bin/bash
# User Data Script for AWS EC2 Launch Template
# Ubuntu 24.04 (Noble)
# Author: @itsgitz

set -euo pipefail

DOMAIN_NAME="modul1.kotakserver.my.id"
DOCUMENT_ROOT="/var/www/html"
NGINX_CONFIGURATION_DIR="/etc/nginx"
GIST_URL="https://gist.githubusercontent.com/itsgitz/d062c142d94eba2381eca6e1a6d9c0ed/raw"

echo "=== [1/7] Updating OS and installing dependencies..."
apt-get update -y
apt-get install -y software-properties-common curl wget gnupg lsb-release

echo "=== [2/7] Adding PPA Ondrej untuk PHP 8.3..."
add-apt-repository -y ppa:ondrej/php
apt-get update -y

echo "=== [3/7] Installing Nginx dan PHP 8.3..."
apt-get install -y nginx php8.3 php8.3-cli php8.3-fpm

echo "=== [4/7] Removing default Nginx files..."
rm -f "$DOCUMENT_ROOT/index.html" \
      "$DOCUMENT_ROOT/index.nginx-debian.html"
rm -f "$NGINX_CONFIGURATION_DIR/sites-available/default" \
      "$NGINX_CONFIGURATION_DIR/sites-enabled/default"

echo "=== [5/7] Downloading index.php from Gist..."
wget -q "$GIST_URL" -O "$DOCUMENT_ROOT/index.php"

echo "=== [6/7] Setting permissions..."
chown www-data:www-data "$DOCUMENT_ROOT/index.php"
chmod 775 "$DOCUMENT_ROOT/index.php"

echo "=== [7/7] Creating Nginx configuration for $DOMAIN_NAME..."
cat <<EOF > "$NGINX_CONFIGURATION_DIR/sites-available/$DOMAIN_NAME"
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    root $DOCUMENT_ROOT;
    index index.php;

    access_log /var/log/nginx/$DOMAIN_NAME-access.log;
    error_log /var/log/nginx/$DOMAIN_NAME-error.log;

    server_name $DOMAIN_NAME;

    location / {
        try_files \$uri \$uri/ =404;
    }

    location ~ \.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php8.3-fpm.sock;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF

ln -sf "$NGINX_CONFIGURATION_DIR/sites-available/$DOMAIN_NAME" \
       "$NGINX_CONFIGURATION_DIR/sites-enabled/"

echo "=== Validating Nginx configuration..."
nginx -t

echo "=== Restarting Nginx..."
systemctl restart nginx

echo "=== DONE! Server $DOMAIN_NAME is ready at http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)"
