#!/bin/bash
set -e

mkdir -p /var/www/html
cd /var/www/html

# Wait for MariaDB to actually be ready to accept connections
# (depends_on only waits for the container, not the service inside)
echo "Waiting for MariaDB..."
until mysqladmin ping -h mariadb -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" --silent 2>/dev/null; do
    echo "MariaDB not ready yet, retrying in 2s..."
    sleep 2
done
echo "MariaDB is ready."

if [ ! -f wp-config.php ]; then
    echo "Installing WordPress..."

    # Check for core files separately from config —
    # on a crash/restart, files may exist but config may not
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
