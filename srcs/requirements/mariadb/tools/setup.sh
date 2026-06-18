#!/bin/bash
set -e

mkdir -p /run/mysqld
chown -R mysql:mysql /run/mysqld
chown -R mysql:mysql /var/lib/mysql

# Initialize system tables only if truly missing
if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "[mariadb] Initializing system tables..."
    mysql_install_db --user=mysql --datadir=/var/lib/mysql > /dev/null
    echo "[mariadb] System tables done."
fi

# Always start temporary server — we need it to check/create our user
echo "[mariadb] Starting temporary server..."
mysqld_safe --skip-networking &
MYSQL_PID=$!

# Wait — root may or may not have a password depending on previous partial runs
echo "[mariadb] Waiting for server..."
until mysql -u root -e "SELECT 1;" > /dev/null 2>&1 || \
      mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "SELECT 1;" > /dev/null 2>&1; do
    sleep 1
done
echo "[mariadb] Server ready."

# Detect whether root already has a password
if mysql -u root -e "SELECT 1;" > /dev/null 2>&1; then
    ROOT="mysql -u root"
    ADMIN="mysqladmin -u root"
else
    ROOT="mysql -u root -p${MYSQL_ROOT_PASSWORD}"
    ADMIN="mysqladmin -u root -p${MYSQL_ROOT_PASSWORD}"
fi

# Check if OUR user exists — this is the real condition, not the directory
USER_EXISTS=$(${ROOT} -e "SELECT COUNT(*) FROM mysql.user WHERE User='${MYSQL_USER}' AND Host='%';" 2>/dev/null | tail -1)
echo "[mariadb] User '${MYSQL_USER}' exists: ${USER_EXISTS}"

if [ "${USER_EXISTS}" = "0" ]; then
    echo "[mariadb] Creating database and user..."
    ${ROOT} <<EOF
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
FLUSH PRIVILEGES;
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
FLUSH PRIVILEGES;
EOF
    echo "[mariadb] Done. Verifying:"
    mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "SELECT User, Host FROM mysql.user;"
else
    echo "[mariadb] User already exists, skipping setup."
fi

# Shutdown temporary server
${ADMIN} shutdown 2>/dev/null || true
wait $MYSQL_PID
echo "[mariadb] Temporary server stopped."

echo "[mariadb] Starting MariaDB in foreground..."
exec mysqld_safe --datadir=/var/lib/mysql
