#!/bin/bash
set -e

mkdir -p /run/mysqld
chown -R mysql:mysql /run/mysqld
chown -R mysql:mysql /var/lib/mysql

if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "[mariadb] Initializing system tables..."
    mysql_install_db --user=mysql --datadir=/var/lib/mysql > /dev/null
    echo "[mariadb] System tables done."
fi

echo "[mariadb] Starting temporary server..."
mysqld_safe --skip-networking &
MYSQL_PID=$!

echo "[mariadb] Waiting for server..."
until mysql -u root -e "SELECT 1;" > /dev/null 2>&1 || \
      mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "SELECT 1;" > /dev/null 2>&1; do
    sleep 1
done
echo "[mariadb] Server ready."

if mysql -u root -e "SELECT 1;" > /dev/null 2>&1; then
    ROOT="mysql -u root"
    ADMIN="mysqladmin -u root"
else
    ROOT="mysql -u root -p${MYSQL_ROOT_PASSWORD}"
    ADMIN="mysqladmin -u root -p${MYSQL_ROOT_PASSWORD}"
fi

USER_EXISTS=$(${ROOT} -e "SELECT COUNT(*) FROM mysql.user WHERE User='${MYSQL_USER}' AND Host='%';" 2>/dev/null | tail -1)
echo "[mariadb] User '${MYSQL_USER}' exists: ${USER_EXISTS}"

if [ "${USER_EXISTS}" = "0" ]; then
    echo "[mariadb] Creating database and user..."
    ${ROOT} <<EOF
DELETE FROM mysql.user WHERE User='';
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

${ADMIN} shutdown 2>/dev/null || true
wait $MYSQL_PID || true
echo "[mariadb] Temporary server stopped."

# Clean up socket and pid from temp server so real startup isn't blocked
rm -f /run/mysqld/mysqld.sock
rm -f /run/mysqld/mysqld.pid

echo "[mariadb] Starting MariaDB in foreground..."
exec mysqld --user=mysql