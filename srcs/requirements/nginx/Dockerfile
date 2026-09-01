FROM debian:bookworm

RUN sed -i 's|http://deb.debian.org/debian|http://ftp.fr.debian.org/debian|g' /etc/apt/sources.list.d/debian.sources && \
    sed -i 's|http://deb.debian.org/debian-security|http://ftp.fr.debian.org/debian-security|g' /etc/apt/sources.list.d/debian.sources && \
    apt-get update && apt-get install -y \
    nginx \
    openssl \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /etc/nginx/ssl

RUN openssl req -x509 -nodes -days 365 \
    -newkey rsa:2048 \
    -keyout /etc/nginx/ssl/inception.key \
    -out /etc/nginx/ssl/inception.crt \
    -subj "/C=LB/ST=Beirut/L=Beirut/O=42/OU=42/CN=jghattas.42.fr"

COPY conf/nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 443

CMD ["nginx", "-g", "daemon off;"]
