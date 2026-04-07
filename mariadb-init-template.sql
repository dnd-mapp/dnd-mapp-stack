-- ============================================================
-- D&D Mapp — MariaDB initialisation template
--
-- Copy this file to mariadb-init.sql and replace every
-- placeholder (angle-bracket tokens) with real values before
-- starting the stack.
--
-- Placeholder reference
--   <AUTH_SERVER_DB_USER>     runtime user for auth-server
--   <AUTH_SERVER_DB_PASSWORD> password for the auth-server user
--   <EMAIL_SERVICE_DB_USER>   runtime user for email-service
--   <EMAIL_SERVICE_DB_PASSWORD> password for the email-service user
--   <PRISMA_DB_USER>          migration user (needs full access)
--   <PRISMA_DB_PASSWORD>      password for the prisma user
-- ============================================================


-- ============================================================
-- 1. Create database users
-- ============================================================

-- Runtime user for auth-server (least-privilege)
CREATE USER IF NOT EXISTS '<AUTH_SERVER_DB_USER>'@'%'
    IDENTIFIED BY '<AUTH_SERVER_DB_PASSWORD>';

-- Runtime user for email-service (least-privilege)
CREATE USER IF NOT EXISTS '<EMAIL_SERVICE_DB_USER>'@'%'
    IDENTIFIED BY '<EMAIL_SERVICE_DB_PASSWORD>';

-- Prisma migration user (needs DDL rights across all schemas)
CREATE USER IF NOT EXISTS '<PRISMA_DB_USER>'@'%'
    IDENTIFIED BY '<PRISMA_DB_PASSWORD>';


-- ============================================================
-- 2. Auth-server schemas
-- ============================================================

CREATE DATABASE IF NOT EXISTS `auth_db`
    CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE DATABASE IF NOT EXISTS `auth_db_shadow`
    CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- auth-server runtime user: DML only on the production schema
GRANT SELECT, INSERT, UPDATE, DELETE ON `auth_db`.*
    TO '<AUTH_SERVER_DB_USER>'@'%';

-- prisma user: full access to both auth schemas (migrations + shadow)
GRANT ALL PRIVILEGES ON `auth_db`.*        TO '<PRISMA_DB_USER>'@'%';
GRANT ALL PRIVILEGES ON `auth_db_shadow`.* TO '<PRISMA_DB_USER>'@'%';


-- ============================================================
-- 3. Email-service schemas
-- ============================================================

CREATE DATABASE IF NOT EXISTS `email_db`
    CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE DATABASE IF NOT EXISTS `email_db_shadow`
    CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- email-service runtime user: DML only on the production schema
GRANT SELECT, INSERT, UPDATE, DELETE ON `email_db`.*
    TO '<EMAIL_SERVICE_DB_USER>'@'%';

-- prisma user: full access to both email schemas (migrations + shadow)
GRANT ALL PRIVILEGES ON `email_db`.*        TO '<PRISMA_DB_USER>'@'%';
GRANT ALL PRIVILEGES ON `email_db_shadow`.* TO '<PRISMA_DB_USER>'@'%';


-- ============================================================
-- 4. Apply privilege changes
-- ============================================================

FLUSH PRIVILEGES;
