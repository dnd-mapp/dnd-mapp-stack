#!/bin/bash
set -e

# Resolve _FILE env vars (Docker secrets) for application user passwords.
# Only resolves if the _FILE variant is set, the file exists, and the base variable is not already set.
for secret in AUTH_SERVER_DB_PASSWORD EMAIL_SERVICE_DB_PASSWORD PRISMA_DB_PASSWORD; do
    file_var="${secret}_FILE"
    file_path="$(printenv "$file_var" 2>/dev/null || true)"

    if [ -n "$file_path" ] && [ -f "$file_path" ] && [ -z "$(printenv "$secret" 2>/dev/null || true)" ]; then
        export "$secret=$(tr -d '\r' < "$file_path")"
    fi
done

AUTH_SERVER_DB_SHADOW="${AUTH_SERVER_DB_SCHEMA}_shadow"
EMAIL_SERVICE_DB_SHADOW="${EMAIL_SERVICE_DB_SCHEMA}_shadow"

mariadb --user=root --password="${MARIADB_ROOT_PASSWORD}" <<-EOSQL
    -- ============================================================
    -- 1. Auth-server schemas
    -- ============================================================

    CREATE DATABASE IF NOT EXISTS \`${AUTH_SERVER_DB_SCHEMA}\`
        CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

    CREATE DATABASE IF NOT EXISTS \`${AUTH_SERVER_DB_SHADOW}\`
        CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

    -- ============================================================
    -- 2. Email-service schemas
    -- ============================================================

    CREATE DATABASE IF NOT EXISTS \`${EMAIL_SERVICE_DB_SCHEMA}\`
        CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

    CREATE DATABASE IF NOT EXISTS \`${EMAIL_SERVICE_DB_SHADOW}\`
        CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

    -- ============================================================
    -- 3. Database users
    -- ============================================================

    -- Runtime user for auth-server (DML only)
    CREATE USER IF NOT EXISTS '${AUTH_SERVER_DB_USER}'@'%' IDENTIFIED BY '${AUTH_SERVER_DB_PASSWORD}';

    -- Runtime user for email-service (DML only)
    CREATE USER IF NOT EXISTS '${EMAIL_SERVICE_DB_USER}'@'%' IDENTIFIED BY '${EMAIL_SERVICE_DB_PASSWORD}';

    -- Prisma migration user (DDL access across all schemas)
    CREATE USER IF NOT EXISTS '${PRISMA_DB_USER}'@'%' IDENTIFIED BY '${PRISMA_DB_PASSWORD}';

    -- ============================================================
    -- 4. Grants
    -- ============================================================

    GRANT SELECT, INSERT, UPDATE, DELETE ON \`${AUTH_SERVER_DB_SCHEMA}\`.*  TO '${AUTH_SERVER_DB_USER}'@'%';
    GRANT SELECT, INSERT, UPDATE, DELETE ON \`${EMAIL_SERVICE_DB_SCHEMA}\`.* TO '${EMAIL_SERVICE_DB_USER}'@'%';

    GRANT ALL PRIVILEGES ON \`${AUTH_SERVER_DB_SCHEMA}\`.*   TO '${PRISMA_DB_USER}'@'%';
    GRANT ALL PRIVILEGES ON \`${AUTH_SERVER_DB_SHADOW}\`.*   TO '${PRISMA_DB_USER}'@'%';
    GRANT ALL PRIVILEGES ON \`${EMAIL_SERVICE_DB_SCHEMA}\`.*  TO '${PRISMA_DB_USER}'@'%';
    GRANT ALL PRIVILEGES ON \`${EMAIL_SERVICE_DB_SHADOW}\`.*  TO '${PRISMA_DB_USER}'@'%';

    FLUSH PRIVILEGES;
EOSQL
