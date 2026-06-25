# USER_DOC — Inception User Documentation

## What services does this stack provide?

The Inception stack runs three services:

| Service | Description | Internal Port |
|---|---|---|
| **NGINX** | Web server and sole entry point into the infrastructure. Handles HTTPS and forwards PHP requests to WordPress. | 443 (exposed to host) |
| **WordPress + PHP-FPM** | The WordPress application with PHP processing. Serves the website and admin panel. | 9000 (internal only) |
| **MariaDB** | The relational database storing all WordPress content, users, and settings. | 3306 (internal only) |

All traffic enters through NGINX on port 443. No other ports are accessible from outside.

---

## Starting and stopping the project

### Start

```bash
make
```

This builds the images if needed and starts all three containers in the background.

### Stop (keep data)

```bash
make down
```

Stops all containers. Data in volumes is preserved.

### Stop and remove volumes (wipe data)

```bash
make clean
```

Stops containers and removes the Docker named volumes. Host data files at `/home/jghattas/data/` are kept.

### Full reset (wipe everything)

```bash
make fclean
```

Stops containers, removes volumes, removes Docker images and cache, and deletes all data from `/home/jghattas/data/`. Use this for a completely fresh start.

---

## Accessing the website and administration panel

Before accessing the site, ensure your `/etc/hosts` file contains:

```
127.0.0.1   jghattas.42.fr
```

| URL | Description |
|---|---|
| `https://jghattas.42.fr` | WordPress website (frontend) |
| `https://jghattas.42.fr/wp-admin` | WordPress administration panel |

Your browser will warn about an untrusted certificate — this is expected because the SSL certificate is self-signed. Accept the exception to proceed.

### Admin login

| Field | Value |
|---|---|
| Username | `manager` |
| Password | See `secrets/credentials.txt` (first line) |

### Regular user login

| Field | Value |
|---|---|
| Username | `user` |
| Password | See `secrets/credentials.txt` (second line) |

---

## Locating and managing credentials

All credentials are stored in the `secrets/` directory at the root of the project. This directory is never committed to git.

| File | Contains |
|---|---|
| `secrets/db_password.txt` | MariaDB password for the WordPress user (`jghattas`) |
| `secrets/db_root_password.txt` | MariaDB root password |
| `secrets/credentials.txt` | WordPress admin password (line 1) and regular user password (line 2) |

To change a password, edit the relevant file and do a full rebuild:

```bash
make fclean
make
```

---

## Checking that services are running correctly

### Quick status check

```bash
make ps
```

All three containers (`mariadb`, `wordpress`, `nginx`) must show status `Up` with no `Restarting` in the output.

### Check individual container logs

```bash
docker logs mariadb
docker logs wordpress
docker logs nginx
```

MariaDB should end with a line confirming it is listening. WordPress should show `WordPress installed successfully` on first boot, then `WordPress already configured` on subsequent starts.

### Test the website is reachable

```bash
curl -k -I https://jghattas.42.fr
```

Expected response starts with `HTTP/1.1 200 OK`.

### Test database connectivity

```bash
docker exec wordpress mysql -h mariadb -u jghattas -p"$(cat secrets/db_password.txt)" -e "SHOW TABLES FROM wordpress;"
```

Expected: a list of WordPress tables (`wp_posts`, `wp_users`, etc.).

### Verify data persistence after restart

```bash
make down
make up
curl -k -s -o /dev/null -w "%{http_code}" https://jghattas.42.fr
```

Expected: `200` — the site loads correctly after restart with all data intact.
