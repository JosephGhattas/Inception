#!/bin/bash
set -e

MYSQL_PASSWORD=$(cat /run/secrets/db_password)
WP_ADMIN_PASSWORD=$(cat /run/secrets/credentials | head -1)
WP_USER_PASSWORD=$(cat /run/secrets/credentials | tail -1)

mkdir -p /var/www/html
cd /var/www/html

echo "Waiting for MariaDB..."
until mysql -h mariadb -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" -e "SELECT 1;" > /dev/null 2>&1; do
    echo "MariaDB not ready yet, retrying in 2s..."
    sleep 2
done
echo "MariaDB is ready."

if [ ! -f wp-config.php ]; then
    echo "Installing WordPress..."

    if [ ! -f wp-login.php ]; then
        wp core download --allow-root
    else
        echo "Core files already present, skipping download."
    fi

    wp config create \
        --allow-root \
        --dbname="$MYSQL_DATABASE" \
        --dbuser="$MYSQL_USER" \
        --dbpass="$MYSQL_PASSWORD" \
        --dbhost=mariadb:3306

    wp core install \
        --allow-root \
        --url="$DOMAIN_NAME" \
        --title="$WP_TITLE" \
        --admin_user="$WP_ADMIN_USER" \
        --admin_password="$WP_ADMIN_PASSWORD" \
        --admin_email="$WP_ADMIN_EMAIL"

    wp user create \
        "$WP_USER" \
        "$WP_USER_EMAIL" \
        --user_pass="$WP_USER_PASSWORD" \
        --allow-root

    echo "WordPress installed successfully."
else
    echo "WordPress already configured, skipping install."
fi

mkdir -p /run/php
exec /usr/sbin/php-fpm7.4 -F