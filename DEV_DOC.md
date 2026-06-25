# DEV_DOC — Inception Developer Documentation

## Setting up the environment from scratch

### Prerequisites

- A Virtual Machine running Debian/Ubuntu
- Docker Engine installed:
  ```bash
  sudo apt-get update
  sudo apt-get install -y docker.io docker-compose-plugin
  sudo usermod -aG docker $USER
  # Log out and back in for group change to take effect
  ```
- `sudo` access (required for data directory cleanup in `fclean`)
- Domain pointing to localhost — add to `/etc/hosts`:
  ```bash
  echo "127.0.0.1 jghattas.42.fr" | sudo tee -a /etc/hosts
  ```

### Repository structure

```
.
├── Makefile
├── README.md
├── USER_DOC.md
├── DEV_DOC.md
├── .gitignore
├── secrets/                        ← never committed to git
│   ├── credentials.txt
│   ├── db_password.txt
│   └── db_root_password.txt
└── srcs/
    ├── .env                        ← non-sensitive vars only
    ├── docker-compose.yml
    └── requirements/
        ├── mariadb/
        │   ├── Dockerfile
        │   ├── .dockerignore
        │   ├── conf/myconfig.cnf
        │   └── tools/setup.sh
        ├── nginx/
        │   ├── Dockerfile
        │   ├── .dockerignore
        │   └── conf/nginx.conf
        └── wordpress/
            ├── Dockerfile
            ├── .dockerignore
            ├── conf/www.conf
            └── tools/setup.sh
```

### Configuration files

**`srcs/.env`** — non-sensitive environment variables passed to all containers:
```
MYSQL_DATABASE=wordpress
MYSQL_USER=jghattas
WP_TITLE=Inception
WP_ADMIN_USER=manager
WP_ADMIN_EMAIL=manager@jghattas.42.fr
WP_USER=user
WP_USER_EMAIL=user@jghattas.42.fr
DOMAIN_NAME=jghattas.42.fr
```

**`srcs/docker-compose.yml`** — defines all services, volumes, network, and secret references.

**`srcs/requirements/mariadb/conf/myconfig.cnf`** — MariaDB server config: sets `bind-address = 0.0.0.0` so other containers can connect, sets port 3306, character set utf8mb4.

**`srcs/requirements/nginx/conf/nginx.conf`** — NGINX server block: listens on 443 with `ssl_protocols TLSv1.2 TLSv1.3`, proxies PHP to `wordpress:9000` via FastCGI.

**`srcs/requirements/wordpress/conf/www.conf`** — PHP-FPM pool config: listens on port 9000, sets `clear_env = no` so container env vars are visible to PHP.

### Creating secrets

Create the secrets directory and populate it — these must never be committed:

```bash
mkdir -p secrets
echo "your_db_password"        > secrets/db_password.txt
echo "your_root_password"      > secrets/db_root_password.txt
printf "admin_pass\nuser_pass" > secrets/credentials.txt
```

Ensure `secrets/` is in `.gitignore`:
```
secrets/
```

Docker Compose mounts secrets as read-only files inside `/run/secrets/` in each container that declares them. Scripts read them with:
```bash
MYSQL_PASSWORD=$(cat /run/secrets/db_password)
```

---

## Building and launching with Makefile and Docker Compose

### Makefile targets

| Target | Action |
|---|---|
| `make` or `make all` | Creates data directories, builds images, starts containers |
| `make up` | Builds and starts containers |
| `make down` | Stops containers, preserves volumes and data |
| `make clean` | Stops containers and removes Docker named volumes |
| `make fclean` | Full reset: prunes Docker system, deletes host data directories |
| `make re` | `fclean` then `up` — full clean rebuild |
| `make ps` | Shows running containers |

### Build process

```bash
make fclean          # ensure clean state
make                 # build all images and start
docker logs -f mariadb    # watch MariaDB initialization
docker logs -f wordpress  # watch WordPress installation
```

On first boot, MariaDB initializes the database and creates the `jghattas` user, then WordPress downloads core files and installs. On subsequent boots both skip setup and go straight to running their services.

### How each service starts

**MariaDB** (`setup.sh`):
1. Creates `/run/mysqld/` directory with correct ownership
2. Runs `mysql_install_db` if `/var/lib/mysql/mysql` doesn't exist
3. Starts a temporary local-only server via Unix socket
4. Creates the database, user, and sets root password using env vars and secrets
5. Shuts down the temporary server cleanly
6. Starts the real `mysqld` process as PID 1

**WordPress** (`setup.sh`):
1. Waits for MariaDB to accept connections (retry loop)
2. If `wp-config.php` doesn't exist: downloads WordPress core, creates config, installs WordPress, creates the second user
3. Starts `php-fpm7.4` in foreground as PID 1

**NGINX** (Dockerfile `CMD`):
1. SSL certificate and key are generated at image build time with OpenSSL
2. Starts `nginx` with `daemon off` as PID 1

---

## Managing containers and volumes

### Useful commands

```bash
# View all containers
docker ps -a

# Follow logs of a specific container
docker logs -f mariadb
docker logs -f wordpress
docker logs -f nginx

# Open a shell inside a container
docker exec -it mariadb bash
docker exec -it wordpress bash
docker exec -it nginx bash

# Check MariaDB users
docker exec mariadb mysql -u root -p"$(cat secrets/db_root_password.txt)" \
    -e "SELECT User, Host FROM mysql.user;"

# Check WordPress tables exist
docker exec wordpress mysql -h mariadb -u jghattas \
    -p"$(cat secrets/db_password.txt)" \
    -e "SHOW TABLES FROM wordpress;"

# Check WordPress users
docker exec wordpress wp user list --allow-root --path=/var/www/html

# Check listening ports inside containers
docker exec mariadb ss -tlnp
docker exec wordpress ss -tlnp
docker exec nginx ss -tlnp

# Inspect the Docker network
docker network inspect srcs_inception

# List named volumes
docker volume ls
```

---

## Where data is stored and how it persists

### Named volumes

Two Docker named volumes are defined in `docker-compose.yml`:

| Volume name | Mounted at (container) | Host path |
|---|---|---|
| `mariadb_data` | `/var/lib/mysql` | `/home/jghattas/data/mariadb/` |
| `wordpress_data` | `/var/www/html` | `/home/jghattas/data/wordpress/` |

The volumes use the local driver with `type: none, o: bind` options, which causes Docker to store data at the specified host path while still registering them as named volumes.

### Persistence behavior

- `make down` / `make up` — data survives, containers resume from existing state
- `make clean` — removes Docker volume references but host files remain at `/home/jghattas/data/`
- `make fclean` — deletes host data directories entirely, next `make` starts fresh

### Verifying data on the host

```bash
sudo ls /home/jghattas/data/mariadb/   # MariaDB files: ibdata1, mysql/, wordpress/
sudo ls /home/jghattas/data/wordpress/ # WordPress files: wp-config.php, wp-content/, etc.
```
