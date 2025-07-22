# syntax=docker/dockerfile:1
########################################################################
# 1. Базовий образ – Debian 12 slim
########################################################################
FROM debian:12-slim

ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=Europe/Kyiv

########################################################################
# 2. Базові утиліти (curl, gnupg, supervisor, nginx, тощо)
########################################################################
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        gnupg2 \
        lsb-release \
        unzip \
        supervisor \
        nginx \
        cron \
        mariadb-client \
        wget \
        gosu \
        tzdata && \
    rm -rf /var/lib/apt/lists/*

########################################################################
# 3. Підключаємо репозиторій Sury та ставимо PHP 8.3 + потрібні ext
#    (команди взято з офіційної документації Azuriom)
########################################################################
RUN curl -fsSL https://packages.sury.org/php/apt.gpg \
        | tee  /etc/apt/trusted.gpg.d/php.gpg >/dev/null && \
    echo "deb https://packages.sury.org/php/ $(lsb_release -cs) main" \
        > /etc/apt/sources.list.d/php.list && \
    \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        php8.3 \
        php8.3-fpm \
        php8.3-mysql \
        php8.3-pgsql \
        php8.3-sqlite3 \
        php8.3-bcmath \
        php8.3-mbstring \
        php8.3-xml \
        php8.3-curl \
        php8.3-zip \
        php8.3-gd && \
    rm -rf /var/lib/apt/lists/*

########################################################################
# 4. Composer (для встановлення залежностей Azuriom, якщо знадобиться)
########################################################################
RUN curl -sS https://getcomposer.org/installer \
        | php -- --install-dir=/usr/local/bin --filename=composer

########################################################################
# 5. Конфіги Nginx / Supervisor / Entrypoint
########################################################################
COPY nginx.conf       /etc/nginx/nginx.conf
COPY supervisord.conf /etc/supervisord.conf
COPY entrypoint.sh    /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Логи та runtime‑директорії
RUN mkdir -p /var/log/supervisor /var/log/nginx /run/php

########################################################################
# 6. Робоча директорія та права
########################################################################
WORKDIR /var/www/html
RUN chown -R www-data:www-data /var/www/html

########################################################################
# 7. Порт і запуск
########################################################################
EXPOSE 80
ENTRYPOINT ["/entrypoint.sh"]
