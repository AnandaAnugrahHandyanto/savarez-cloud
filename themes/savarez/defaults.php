<?php

/**
 * Savarez Cloud — Theme Identity v3
 *
 * OC_Theme class for the Savarez Cloud instance.
 * Provides all metadata Nextcloud uses for branding.
 *
 * IMPORTANT:
 *   - This is the ONLY file that defines theme behavior.
 *   - Visual customization happens via CSS (css/theming.css).
 *   - Never modify Nextcloud core files.
 */

class OC_Theme {

    public function getName() {
        return 'savarez';
    }

    public function getTitle() {
        return 'Savarez Cloud';
    }

    public function getShortName() {
        return 'Savarez';
    }

    public function getTitleSuffix() {
        return ' — Savarez Cloud';
    }

    public function getSlogan() {
        return 'Private Cloud. Powered by You.';
    }

    public function getLongSlogan() {
        return 'Savarez Cloud — a self-hosted private cloud platform for file storage, synchronization, and collaboration.';
    }

    public function getFolder() {
        return 'folder';
    }

    public function getFile() {
        return 'file';
    }

    public function getSVGFolderIcon() {
        return '';
    }

    public function getSVGFileIcon() {
        return '';
    }

    public function getLogo() {
        return 'img/logo.svg';
    }

    public function getLogoMail() {
        return 'img/logo-mail.svg';
    }

    public function getFavicon() {
        return 'img/favicon.svg';
    }

    public function getFaviconType() {
        return 'image/svg+xml';
    }

    public function mimetypeIconMapping() {
        return [];
    }
}
