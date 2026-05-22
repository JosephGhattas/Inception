FROM debian:bullseye

RUN apt-get update && apt-get install -y \
    mariadb-server \
    bash \
    && rm -rf /var/lib/apt/lists/*

# Copy config
COPY conf/myconfig.cnf /etc/mysql/mariadb.conf.d/

# Copy scripts
COPY tools/setup.sh /setup.sh
COPY tools/init.sql /init.sql

RUN chmod +x /setup.sh

EXPOSE 3306

ENTRYPOINT ["/setup.sh"]
