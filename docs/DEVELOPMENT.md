# Development Workflow for Savarez Theme

This document outlines the standard development workflow for the `savarez_theme` Nextcloud application, ensuring consistency and efficient CSS development.

## Workflow Steps:

1.  **Laptop (Local Development Environment)**
    *   All development work is performed on your local machine within the Git repository (`/home/anandaanugrah/savarez-cloud`).

2.  **Git Repository (Single Source of Truth)**
    *   The Git repository is the single source of truth for the `savarez_theme` source code. This includes CSS, JavaScript, images, appinfo, scripts, documentation, and DOM snapshots.

3.  **DOM Snapshot (Reference for CSS Development)**
    *   Before starting significant CSS work, update your local DOM snapshots by running `scripts/fetch-dom.sh <SERVER_IP_OR_HOSTNAME> <USERNAME>`.
    *   These snapshots (`snapshots/` directory) provide the actual HTML structure from the production Nextcloud server. They are crucial for accurately targeting CSS selectors without needing a local Nextcloud installation.
    *   **Never edit DOM snapshot files manually.**

4.  **CSS Development (Based on Snapshots)**
    *   Develop and refine your CSS within the `app/css/` and `app/css/modules/` directories.
    *   Use the DOM snapshots as your primary reference to ensure your selectors are correct and your styles apply as intended on the production HTML.

5.  **Git Commit (Version Control)**
    *   Once your changes are complete and verified against the snapshots, commit them to the Git repository.
    *   Follow conventional commit messages (e.g., `feat(theme): add new dashboard styles`).

6.  **Deploy (To Production)**
    *   To apply your changes to the production server, execute the `scripts/deploy.sh <SERVER_IP_OR_HOSTNAME> <USERNAME>` script on the production server (or through SSH as defined in `fetch-dom.sh`).
    *   This script copies the entire `app/` directory to `/srv/nextcloud-app/apps/savarez_theme/`.

7.  **Production (Live Environment)**
    *   Verify your changes on the live Nextcloud production environment.

## Important Considerations:

-   This repository does not assume a local Nextcloud installation.
-   All interactions with the production server (fetching snapshots, deploying) are done via `ssh`, `scp`, and `curl` through the provided scripts.
-   Focus on clean, maintainable CSS, and minimize the use of `!important`.
-   Always refer to the DOM snapshots for the most accurate HTML structure.
