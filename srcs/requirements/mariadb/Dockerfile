FROM debian:bullseye

RUN apt-get update && apt-get install -y \
    mariadb-server \
    bash \
    && rm -rf /var/lib/apt/lists/*

# Remove data initialized by apt postinstall script
# so our setup.sh init block always runs on first real boot
RUN rm -rf /var/lib/mysql/*

RUN mkdir -p /var/log/mysql && chown -R mysql:mysql /var/log/mysql

COPY conf/myconfig.cnf /etc/mysql/mariadb.conf.d/
COPY tools/setup.sh /setup.sh
RUN chmod +x /setup.sh

EXPOSE 3306
ENTRYPOINT ["/setup.sh"]
