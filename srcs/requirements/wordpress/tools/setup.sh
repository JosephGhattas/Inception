#!/bin/bash

set -e

mkdir -p /var/www/html

cd /var/www/html

if [ ! -f wp-config.php ]
then
	echo "Installing WordPress..."

	wp core download --allow-root

	wp config create \
		--allow-root \
		--dbname=$MYSQL_DATABASE \
		--dbuser=$MYSQL_USER \
		--dbpass=$MYSQL_PASSWORD \
		--dbhost=mariadb:3306

	wp core install \
		--allow-root \
		--url=$DOMAIN_NAME \
		--title=$WP_TITLE \
		--admin_user=$WP_ADMIN_USER \
		--admin_password=$WP_ADMIN_PASSWORD \
		--admin_email=$WP_ADMIN_EMAIL

	wp user create \
		$WP_USER \
		$WP_USER_EMAIL \
		--user_pass=$WP_USER_PASSWORD \
		--allow-root
fi

mkdir -p /run/php

exec /usr/sbin/php-fpm7.4 -F
