#!/bin/bash
set -e

# Ensure runtime directory exists with correct ownership
mkdir -p /run/mysqld
chown -R mysql:mysql /run/mysqld
chown -R mysql:mysql /var/lib/mysql

# Only initialize if this is the first boot (no mysql system tables yet)
if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "[setup] First boot — initializing MariaDB..."

    mysql_install_db --user=mysql --datadir=/var/lib/mysql > /dev/null

    # Start a temporary server with no networking (safe, local only)
    mysqld_safe --skip-networking &
    MYSQL_PID=$!

    # Wait until the server is ready to accept connections
    echo "[setup] Waiting for temporary server..."
    until mysql -u root -e "SELECT 1;" > /dev/null 2>&1; do
        sleep 1
    done
    echo "[setup] Server ready."

    # Run all setup using env vars — no hardcoding
    mysql -u root <<EOF
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
FLUSH PRIVILEGES;
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
FLUSH PRIVILEGES;
EOF

    echo "[setup] Database and users created."

    # Shut down the temporary server using the root password we just set
    mysqladmin -u root -p"${MYSQL_ROOT_PASSWORD}" shutdown
    wait $MYSQL_PID
    echo "[setup] Temporary server stopped."
fi

echo "[setup] Starting MariaDB..."
exec mysqld_safe --datadir=/var/lib/mysql
