# Savarez Cloud Developer Toolkit Documentation

This document provides an overview and usage instructions for the automation scripts within the `scripts/` directory. These scripts are designed to streamline the development, deployment, backup, restore, and verification processes for the `savarez_theme` Nextcloud application.

## Table of Contents

1.  [scripts/deploy.sh](#scriptsdeploysh)
2.  [scripts/verify.sh](#scriptsverifysh)
3.  [scripts/backup.sh](#scriptsbackupsh)
4.  [scripts/restore.sh](#scriptsrestoresh)
5.  [scripts/purge-cache.sh](#scriptspurge-cachesh)
6.  [scripts/fetch-dom.sh](#scriptsfetch-domsh)
7.  [scripts/preview.sh](#scriptspreviewsh)
8.  [scripts/lib/](#scriptslib)

---

### 1. `scripts/deploy.sh`

**Description:** Automates the deployment of the `savarez_theme` application to a production Nextcloud server. It includes validation, backup, file transfer, permission fixing, cache clearing, web server restart, and post-deployment verification with automatic rollback on failure.

**Pipeline:**

1.  Validate local source directory.
2.  Backup existing production app (unless skipped or dry run).
3.  Copy local `app/` directory to `NC_SAVAREZ_THEME_PATH` on production.
4.  Fix ownership (`WEB_USER:WEB_GROUP`) for the deployed app.
5.  Fix permissions (directories 755, files 644).
6.  Clear Nextcloud cache by disabling and re-enabling the app, and running `occ cache:clear`.
7.  Restart web service (`WEB_SERVICE_NAME`, e.g., Apache) (unless `--no-restart`).
8.  Verify deployment using `verify.sh`.
9.  (Optional) Purge Cloudflare cache (requires manual run of `purge-cache.sh`).
10. Provides a final success or failure report with automatic rollback on failure.

**Usage:**

```bash
./scripts/deploy.sh <SERVER_IP_OR_HOSTNAME> <USERNAME> [--dry-run] [--no-restart] [--skip-backup]
```

**Options:**

-   `<SERVER_IP_OR_HOSTNAME>`: IP address or hostname of the production server.
-   `<USERNAME>`: SSH username for the production server.
-   `--dry-run`: Simulate the deployment without making any actual changes.
-   `--no-restart`: Skip the web server restart step.
-   `--skip-backup`: Skip the production app backup step.

---

### 2. `scripts/verify.sh`

**Description:** Performs comprehensive checks to verify the health and correct deployment of the `savarez_theme` on a Nextcloud production server. Returns an exit code of `0` for success and `1` for failure.

**Checks Performed:**

-   Presence of `ssh`, `curl`, `jq` dependencies.
-   App directory existence (`NC_SAVAREZ_THEME_PATH`).
-   Nextcloud server reachability (`occ status`).
-   `info.xml` file validity (`xmllint`).
-   App active status via `occ app:status`.
-   HTTP 200 response for Nextcloud login page.
-   HTTP 200 response for the main theme CSS endpoint (`http://<SERVER>/apps/savarez_theme/css/style.css`).
-   Verification that the Savarez stylesheet link appears in the login page HTML.
-   Comparison of local vs. remote `style.css` file sizes.
-   HTTP 200/404 response for the main theme JS endpoint (`http://<SERVER>/apps/savarez_theme/js/main.js`).
-   Ownership and permissions check for the app directory.

**Usage:**

```bash
./scripts/verify.sh <SERVER_IP_OR_HOSTNAME> <USERNAME>
```

---

### 3. `scripts/backup.sh`

**Description:** Creates a timestamped `.tar.gz` backup of the deployed `savarez_theme` application from the production server and stores it locally in the `backups/` directory.

**Usage:**

```bash
./scripts/backup.sh <SERVER_IP_OR_HOSTNAME> <USERNAME>
```

---

### 4. `scripts/restore.sh`

**Description:** Restores a previously created backup of the `savarez_theme` to the production server. By default, it restores the latest backup. A specific backup file can also be provided.

**Usage:**

```bash
./scripts/restore.sh <SERVER_IP_OR_HOSTNAME> <USERNAME> [BACKUP_FILE]
```

**Options:**

-   `<BACKUP_FILE>` (optional): Full path to the `.tar.gz` backup file to restore. If omitted, the latest backup in `backups/` will be used.

---

### 5. `scripts/purge-cache.sh`

**Description:** Facilitates purging the Cloudflare cache for specified URLs or for the entire configured zone. Requires Cloudflare API credentials to be set as environment variables or in `scripts/lib/config.sh` (environment variables are recommended for security).

**Usage:**

```bash
./scripts/purge-cache.sh <purge_url_or_all>
```

**Options:**

-   `<purge_url_or_all>`: Specify a single URL to purge (e.g., `https://your_domain.com/apps/savarez_theme/css/style.css`) or use `all` to purge everything in the configured Cloudflare zone.

---

### 6. `scripts/fetch-dom.sh`

**Description:** Fetches HTML snapshots of various Nextcloud pages (login, dashboard, files, settings, activity) from a production server and saves them locally in the `snapshots/` directory. Each snapshot is timestamped, and metadata is updated in `snapshots/metadata.json`. Passwords are handled securely via `read -s` or environment variables.

**Usage:**

```bash
./scripts/fetch-dom.sh <SERVER_IP_OR_HOSTNAME> <USERNAME>
```

---

### 7. `scripts/preview.sh`

**Description:** Provides a local development preview of the `savarez_theme` CSS. It creates a temporary HTML file with example markup, starts a Python HTTP server, and opens the preview in your default web browser. Useful for rapid iteration on CSS without a full Nextcloud installation.

**Usage:**

```bash
./scripts/preview.sh [PORT]
```

**Options:**

-   `<PORT>` (optional): The port number for the local web server (default: 8000).

---

### 8. `scripts/lib/`

**Description:** This directory contains common shell script libraries used by all other scripts in the toolkit, ensuring code reusability and consistency.

-   **`common.sh`**: Provides logging, error handling, remote command execution, file copying, timestamp generation, and dependency checking functions.
-   **`colors.sh`**: Defines ANSI escape codes for colored terminal output.
-   **`config.sh`**: Stores global configuration variables such as production server paths, Nextcloud app names, local directories, web server details, and placeholders for Cloudflare API credentials. It is recommended to use environment variables for sensitive information rather than hardcoding in this file.
