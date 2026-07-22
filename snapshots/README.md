# DOM Snapshots

This directory contains HTML snapshots of various Nextcloud pages from a production server.

**Important Notes:**

- **Do NOT edit these files manually.** They are intended to be read-only references.
- These snapshots are generated directly from the production Nextcloud environment using `scripts/fetch-dom.sh`.
- The purpose of these snapshots is to provide an accurate HTML structure and class names for CSS development, especially when working on the `savarez_theme`.
- They help in targeting the correct DOM elements without needing a local Nextcloud installation.

Always ensure your CSS changes are compatible with the HTML structure found in these snapshots.
