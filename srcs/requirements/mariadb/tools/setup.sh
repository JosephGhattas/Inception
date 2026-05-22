#!/bin/bash

set -e

# MariaDB runtime directory
mkdir -p /run/mysqld
chown -R mysql:mysql /run/mysqld
chown -R mysql:mysql /var/lib/mysql

# Initialize DB only once
if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "Initializing MariaDB..."

    mysql_install_db --user=mysql --datadir=/var/lib/mysql > /dev/null

    # Start temporary server
    mysqld_safe --datadir=/var/lib/mysql &
    sleep 5

    # Run initialization SQL
    mysql < /init.sql

    # Stop temporary server
    mysqladmin -u root shutdown
fi

# Start MariaDB in foreground (Docker requirement)
exec mysqld_safe --datadir=/var/lib/mysql
