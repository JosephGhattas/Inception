FROM debian:bullseye

RUN apt-get update && apt-get install -y \
    mariadb-server \
    bash \
    && rm -rf /var/lib/apt/lists/*

# Create log directory that myconfig.cnf references
RUN mkdir -p /var/log/mysql && chown mysql:mysql /var/log/mysql

COPY conf/myconfig.cnf /etc/mysql/mariadb.conf.d/
COPY tools/setup.sh /setup.sh
RUN chmod +x /setup.sh

EXPOSE 3306
ENTRYPOINT ["/setup.sh"]
