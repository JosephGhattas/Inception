*This project has been created as part of the 42 curriculum by jghattas.*

# Inception

## Description

Inception is a system administration project that deepens understanding of Docker and containerization. The goal is to set up a small infrastructure composed of three services — NGINX, WordPress with PHP-FPM, and MariaDB — each running in its own dedicated Docker container, orchestrated with Docker Compose inside a virtual machine.

The infrastructure is accessed exclusively through NGINX on port 443 using TLS, which proxies PHP requests to WordPress, which in turn communicates with MariaDB for database operations. Data is persisted using Docker named volumes stored on the host machine.

## Project Description

### How Docker is used

Each service runs in its own container built from a custom Dockerfile based on `debian:bookworm`. No pre-built images are pulled from DockerHub (except the base Debian image). Docker Compose orchestrates the three containers, their volumes, their network, and their environment.

### Design Choices

**Virtual Machines vs Docker**

A Virtual Machine emulates a full operating system with its own kernel, requiring significant resources (CPU, RAM, disk). Docker containers share the host kernel and isolate only the user space, making them far more lightweight and faster to start. For this project, Docker is the right tool because each service (NGINX, WordPress, MariaDB) is a single-purpose process that benefits from isolation without the overhead of a full OS.

**Secrets vs Environment Variables**

Environment variables (stored in `.env`) are suitable for non-sensitive configuration such as usernames, domain names, and database names. They are passed to containers at runtime and visible in the process environment. Docker secrets, by contrast, are mounted as files inside `/run/secrets/` inside the container and are never exposed in environment listings, image layers, or logs. Passwords and credentials are stored exclusively as Docker secrets in this project to prevent accidental exposure.

**Docker Network vs Host Network**

A Docker bridge network (`inception`) isolates inter-container communication from the host network. Containers can reach each other by service name (e.g., `mariadb`, `wordpress`) without exposing internal ports to the outside world. Host networking would share the host's network stack with the container, eliminating isolation and creating security risks. Only NGINX exposes port 443 to the outside; all other communication stays internal.

**Docker Volumes vs Bind Mounts**

Bind mounts directly map a host path into a container, tightly coupling the container to the host filesystem structure. Named volumes are managed by Docker and referenced by name, making them more portable and explicit. This project uses named volumes with local driver options to satisfy both requirements: volumes are named (`mariadb_data`, `wordpress_data`) and their data is stored at `/home/jghattas/data/` on the host.

## Instructions

### Prerequisites

- Docker and Docker Compose installed on the VM
- `sudo` access for data directory management
- `/etc/hosts` configured: `127.0.0.1 jghattas.42.fr`

### Setup

Clone the repository and create the secrets files (never commit these):

```bash
mkdir -p secrets
echo "your_db_password"      > secrets/db_password.txt
echo "your_root_password"    > secrets/db_root_password.txt
printf "admin_pass\nuser_pass" > secrets/credentials.txt
```

### Build and run

```bash
make
```

This will create the data directories, build all Docker images, and start all containers in detached mode.

### Stop

```bash
make down
```

### Full clean rebuild

```bash
make fclean
make
```

### Access

- Website: `https://jghattas.42.fr`
- Admin panel: `https://jghattas.42.fr/wp-admin`

## Resources

### Documentation

- [Docker official documentation](https://docs.docker.com/)
- [Docker Compose reference](https://docs.docker.com/compose/)
- [NGINX documentation](https://nginx.org/en/docs/)
- [WordPress CLI (WP-CLI)](https://wp-cli.org/)
- [MariaDB documentation](https://mariadb.com/kb/en/)
- [PHP-FPM configuration](https://www.php.net/manual/en/install.fpm.configuration.php)
- [Docker secrets](https://docs.docker.com/engine/swarm/secrets/)
- [PID 1 best practices in Docker](https://cloud.google.com/architecture/best-practices-for-building-containers#signal-handling)


### AI Usage

Claude (Anthropic) was used in the following parts of this project:

- **Debugging**: Identifying why MariaDB initialization was being skipped on container start (Debian package postinstall pre-initializes the data directory, requiring `RUN rm -rf /var/lib/mysql/*` in the Dockerfile).
- **Shell scripting**: Assistance structuring the MariaDB `setup.sh` init logic, including the socket-based connection approach and proper shutdown sequence.
- **Compliance checking**: Reviewing the project against the subject requirements to identify missing or incorrect elements.

All AI-generated content was reviewed, tested, and fully understood before being integrated into the project.
