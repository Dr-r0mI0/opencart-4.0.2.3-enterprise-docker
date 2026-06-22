# 🛒 OpenCart Enterprise Docker Blueprint

A highly optimized, secure, and fully portable Docker environment for OpenCart 4.x Enterprise deployments.

![OpenCart Docker](https://img.shields.io/badge/OpenCart-4.0.2.3-blue)
![Docker](https://img.shields.io/badge/Docker-Ready-blue)
![PHP](https://img.shields.io/badge/PHP-8.2-indigo)

## 🌟 Overview
This project implements a **Stateless Container & Stateful Data** architecture. It completely separates the configuration from the codebase by dynamically generating OpenCart configurations based on Environment Variables (`.env`). This allows the same exact image to be used safely across development, staging, and production environments without modifying any code.

## 🚀 Key Features
- **Config & Code Separation:** Uses `getenv()` dynamically in `config.php` and `admin/config.php`.
- **Bulletproof PHP Image:** Built on `php:8.2-apache` with essential and advanced extensions built-in (`gd`, `imagick`, `mysqli`, `redis`, `memcached`, `sockets`, `pcntl`, `bz2`, `gmp`, `opcache`).
- **Auto-Installation:** A smart `entrypoint.sh` automatically populates the database and cleans up the `install/` directory on the very first run.
- **Dynamic Admin Credentials:** Pass admin username/password via environment variables.

---

## 🛠️ Prerequisites
- Docker
- Docker Compose

## 📦 Installation & Setup

1. **Clone the repository:**
   ```bash
   git clone https://github.com/Dr-r0mI0/opencart-4.0.2.3-enterprise-docker.git
   cd opencart-4.0.2.3-enterprise-docker
   ```

2. **Configure Environment Variables:**
   Copy the example file and update it with your actual credentials:
   ```bash
   cp .env.example .env
   ```

3. **Start the Environment:**
   Run the following command to build the image and start the container:
   ```bash
   docker compose up -d --build
   ```

4. **Access your Store:**
   - Storefront: `http://localhost:8081`
   - Admin Panel: `http://localhost:8081/admin`

---

## ⚙️ Environment Variables (`.env`)

| Variable | Description | Default / Example |
|---|---|---|
| `CONTAINER_NAME` | Name of the Docker container | `opencart-enterprise-prod` |
| `HOST_PORT` | Port exposed to your host machine | `8081` |
| `DB_HOST` | Database host (e.g., MariaDB container name) | `mariadb-store` |
| `DB_PORT` | Database port | `3306` |
| `DB_NAME` | Database name | `opencart_db` |
| `DB_USER` | Database username | `opencart_admin` |
| `DB_PASSWORD` | Database password | `your_secure_password` |
| `OC_ADMIN_USER` | OpenCart Admin Username (on first install) | `admin` |
| `OC_ADMIN_PASS` | OpenCart Admin Password (on first install) | `admin` |
| `OC_ADMIN_EMAIL`| OpenCart Admin Email (on first install) | `admin@localhost.com` |

---

## 🏗️ Directory Structure
```text
opencart-enterprise/
├── .env.example             # Example environment variables (committed)
├── .env                     # Actual secret environment variables (ignored in git)
├── docker-compose.yml       # Docker Compose setup
├── Dockerfile               # Custom PHP-Apache image for OpenCart
├── config/                  # PHP Configuration
│   ├── php.ini              # Production-optimized PHP limits
│   └── opcache.ini          # OPcache performance settings
└── scripts/
    └── entrypoint.sh        # Smart entrypoint for auto-install & dynamic config
```

## 🌍 Running Multiple Stores (Global Scalability)
Since the architecture is fully stateless, you can spin up a completely new store instantly without touching the codebase. Just use the built image with a different port, database, and volumes:

```bash
docker run -d \
  --name opencart-enterprise-2 \
  --restart always \
  -p 9082:80 \
  -e DB_HOST=mariadb-store \
  -e DB_NAME=opencart_db_2 \
  -e DB_USER=opencart_admin_2 \
  -e DB_PASSWORD=securepass_2 \
  -e OC_ADMIN_USER=admin_store2 \
  -e OC_ADMIN_PASS=adminpass123 \
  -v opencart_images_2:/var/www/html/image \
  -v opencart_storage_2:/var/www/storage \
  rami/opencart-enterprise:latest
```

---
*Architected for Enterprise Performance & Security.*
