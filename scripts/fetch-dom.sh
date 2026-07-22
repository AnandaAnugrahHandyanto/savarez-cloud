#!/bin/bash

# Script untuk mengambil snapshot DOM dari server produksi Nextcloud.
# Ini HANYA untuk tujuan development dan membutuhkan akses SSH ke server.

SERVER="$1"
USERNAME="$2"

if [ -z "$SERVER" ] || [ -z "$USERNAME" ]; then
    echo "Usage: $0 <SERVER_IP_OR_HOSTNAME> <USERNAME>"
    echo "Example: $0 example.com savarez"
    exit 1
fi

SSH_TARGET="${USERNAME}@${SERVER}"
SNAPSHOTS_DIR="/home/anandaanugrah/savarez-cloud/snapshots"

echo "Fetching DOM snapshots from ${SSH_TARGET}..."

# --- Login Page ---
echo "  Fetching login page..."
ssh "$SSH_TARGET" "curl -s http://localhost/login" > "${SNAPSHOTS_DIR}/login/login.html"

# --- Dashboard Page ---
echo "  Fetching dashboard page..."
# Untuk halaman yang membutuhkan login, kita akan asumsikan curl dijalankan dari dalam server
# setelah autentikasi (misalnya dengan 'ssh -t' dan kemudian menjalankan curl).
# Atau, dengan mengakses file lokal jika memungkinkan.
# Untuk kesederhanaan, saat ini kita akan berasumsi ini bisa diakses, atau instruksi akan diperbarui.
ssh "$SSH_TARGET" "sudo -u www-data php /srv/nextcloud-app/occ app:status files" # Contoh untuk memastikan Nextcloud tersedia, bisa diganti dengan command untuk dump HTML
ssh "$SSH_TARGET" "curl -s --cookie-jar /tmp/cookies.txt --cookie /tmp/cookies.txt -L 'http://localhost/login' -d 'user=${USERNAME}&password=YOUR_PASSWORD'" > /dev/null
ssh "$SSH_TARGET" "curl -s --cookie /tmp/cookies.txt http://localhost/index.php/apps/dashboard" > "${SNAPSHOTS_DIR}/dashboard/dashboard.html"

# --- Files Page ---
echo "  Fetching files page..."
ssh "$SSH_TARGET" "curl -s --cookie /tmp/cookies.txt http://localhost/index.php/apps/files" > "${SNAPSHOTS_DIR}/files/files.html"

# --- Settings Page ---
echo "  Fetching settings page..."
ssh "$SSH_TARGET" "curl -s --cookie /tmp/cookies.txt http://localhost/index.php/settings/user" > "${SNAPSHOTS_DIR}/settings/settings.html"

# --- Activity Page ---
echo "  Fetching activity page..."
ssh "$SSH_TARGET" "curl -s --cookie /tmp/cookies.txt http://localhost/index.php/apps/activity" > "${SNAPSHOTS_DIR}/activity/activity.html"

echo "DOM snapshot fetching completed."

# Membersihkan cookie sementara di remote server
ssh "$SSH_TARGET" "rm /tmp/cookies.txt"
