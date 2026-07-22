#!/bin/bash

# Memastikan direktori tujuan ada
mkdir -p /srv/nextcloud-app/apps/savarez_theme/

# Menyalin seluruh isi folder app/ ke direktori tujuan
cp -r /home/anandaanugrah/savarez-cloud/app/* /srv/nextcloud-app/apps/savarez_theme/

echo "Deployment of savarez_theme completed to /srv/nextcloud-app/apps/savarez_theme/"
