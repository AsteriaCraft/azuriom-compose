#!/bin/sh
set -e

echo "Starting Azuriom container..."

###############################################################################
# 1. Download Azuriom if it is not already present
###############################################################################
if [ ! -f "/var/www/html/artisan" ]; then
    echo "Azuriom not found. Downloading the latest installer…"

    cd /tmp
    curl -fsSL -o azuriom.zip \
        "https://github.com/Azuriom/AzuriomInstaller/releases/latest/download/AzuriomInstaller.zip"

    echo "Unpacking…"
    # -o: overwrite existing files; -q: quiet
    unzip -oq azuriom.zip -d /var/www/html

    rm azuriom.zip
    echo "Azuriom downloaded and unpacked successfully!"
else
    echo "Azuriom already installed."
fi

###############################################################################
# 2. Permissions
###############################################################################
chown -R www-data:www-data /var/www/html
chmod -R 775 /var/www/html

###############################################################################
# 3. Composer dependencies (if composer.json exists)
###############################################################################
if [ -f "/var/www/html/composer.json" ]; then
    echo "Installing Composer dependencies…"
    cd /var/www/html
    gosu www-data composer install \
        --no-dev --optimize-autoloader --no-interaction
fi

###############################################################################
# 4. Wait for the database (only if DB_HOST is defined)
###############################################################################
# if [ -n "$DB_HOST" ]; then
#     echo "Waiting for database ${DB_HOST}:${DB_PORT:-3306}…"
#     timeout=30
#     while ! nc -z "$DB_HOST" "${DB_PORT:-3306}" 2>/dev/null; do
#         sleep 1
#         timeout=$((timeout - 1))
#         [ $timeout -eq 0 ] && { echo "Unable to reach DB!"; exit 1; }
#     done
#     echo "Database is reachable!"
# fi

###############################################################################
# 5. Register the cron entry for Laravel scheduler
###############################################################################
echo "* * * * * cd /var/www/html && php artisan schedule:run >> /dev/null 2>&1" \
    > /tmp/crontab
crontab /tmp/crontab
rm /tmp/crontab

###############################################################################
# 6. Launch Supervisor (manages PHP‑FPM, Nginx, Cron)
###############################################################################
echo "Launching services under Supervisor…"
exec /usr/bin/supervisord -c /etc/supervisord.conf
