# dnd-mapp-stack

Docker Compose orchestration for the complete D&D Mapp platform. Spin up the entire ecosystem — frontend, backend services, and database — with a single command, or bring up only the parts you need for local development.

## What is D&D Mapp?

D&D Mapp is a web platform for Dungeons & Dragons players and dungeon masters. This repository contains no application code; it is purely the infrastructure layer that wires the individual services together.

## Services

| Service              | Image                                                                     | Port | Purpose                                            |
|----------------------|---------------------------------------------------------------------------|------|----------------------------------------------------|
| `dnd-mapp`           | [`dndmapp/dnd-mapp`](https://hub.docker.com/r/dndmapp/dnd-mapp)           | 4200 | Angular frontend                                   |
| `auth-server`        | [`dndmapp/auth-server`](https://hub.docker.com/r/dndmapp/auth-server)     | 4350 | Authentication & authorisation API                 |
| `auth-db-migration`  | `dndmapp/auth-server`                                                     | —    | One-shot Prisma migration runner for auth-server   |
| `email-service`      | [`dndmapp/email-service`](https://hub.docker.com/r/dndmapp/email-service) | 4450 | Transactional email API                            |
| `email-db-migration` | `dndmapp/email-service`                                                   | —    | One-shot Prisma migration runner for email-service |
| `mariadb-server`     | `mariadb`                                                                 | 3306 | MariaDB relational database                        |
| `dbeaver`            | `dbeaver/cloudbeaver`                                                     | 8978 | Web-based database admin UI (CloudBeaver)          |

## Repository contents

```
dnd-mapp-stack/
├── compose.yaml                  # Docker Compose service definitions
├── .env.template                 # Environment variable template → copy to .env
├── mariadb-init-template.sql     # Database init template → copy to mariadb-init.sql
├── secrets/
│   └── mariadb/
│       └── root.txt              # MariaDB root password (create manually, git-ignored)
└── data/                         # Persistent volume data (git-ignored)
    ├── mariadb/
    └── dbeaver/
```

## Prerequisites

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) (or Docker Engine + Compose plugin)

## Setup

### 1. Environment variables

```bash
cp .env.template .env
```

Open `.env` and replace every `change-me` placeholder with real values.

### 2. Database root password (Docker secret)

```bash
mkdir -p secrets/mariadb
echo "your-root-password" > secrets/mariadb/root.txt
```

The file must not end with a trailing newline if you echo with `-n`, or just use a text editor. This file is git-ignored.

### 3. Database initialization script

```bash
cp mariadb-init-template.sql mariadb-init.sql
```

Open `mariadb-init.sql` and replace each `<PLACEHOLDER>` token with the matching value from your `.env` file. This file is git-ignored.

> [!TIP]
> The init script runs only once when the MariaDB data directory is empty. To re-run it, remove `./data/mariadb` and recreate the container.

## Starting the stack

### Full stack (all services)

```bash
docker compose --profile full up -d
```

### Database only

Starts `mariadb-server` and `dbeaver` (no profile flag needed — they always start):

```bash
docker compose up -d
```

Then open CloudBeaver at http://localhost:8978.

### Individual services

Each backend service can be started independently alongside the database.

| Goal                       | Command                                               |
|----------------------------|-------------------------------------------------------|
| Database + DBeaver only    | `docker compose up -d`                                |
| Auth service               | `docker compose --profile auth up -d`                 |
| Email service              | `docker compose --profile email up -d`                |
| Auth + email (no frontend) | `docker compose --profile auth --profile email up -d` |
| Full stack                 | `docker compose --profile full up -d`                 |

> [!NOTE]
> `mariadb-server` has no profile and is always started regardless of which profiles are active. The `*-db-migration` containers run once and exit; they are included automatically with their parent service's profile.

## Database layout

The init script creates one schema and one shadow schema (for Prisma) per service, plus a dedicated runtime user for each service and a shared migration user:

| Schema     | Owner service | Shadow schema     |
|------------|---------------|-------------------|
| `auth_db`  | auth-server   | `auth_db_shadow`  |
| `email_db` | email-service | `email_db_shadow` |

Runtime users (`AUTH_SERVER_DB_USER`, `EMAIL_SERVICE_DB_USER`) have DML-only permissions (`SELECT`, `INSERT`, `UPDATE`, `DELETE`) on their own schema. The Prisma migration user (`PRISMA_DB_USER`) has full DDL rights across all four schemas.

## Stopping the stack

```bash
docker compose --profile full down
```

Add `-v` to also remove named volumes (this will **delete all database data**).
