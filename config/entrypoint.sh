#!/bin/sh

set -e

directory_empty() {
    [ -z "$(ls -A "$1/")" ]
}
if  directory_empty "/var/www/html"; then
        if [ "$(id -u)" = 0 ]; then
            rsync_options="-rlDog --chown www-data:www-data"
        else
            rsync_options="-rlD"
        fi
        echo "FilePress is downloading ..."
        
        curl -fsSL -o FilePress.zip "https://codeload.github.com/zyx0814/FilePress/zip/refs/heads/master"
        export GNUPGHOME="$(mktemp -d)"
        unzip FilePress.zip -d /usr/src/
        gpgconf --kill all
        rm FilePress.zip
        rm -rf "$GNUPGHOME"
        echo "FilePress is installing ..."
        rsync $rsync_options --delete /usr/src/FilePress-master/ /var/www/html/
else
        echo "FilePress has been configured!"
fi
# 检查证书是否存在，并动态切换 Nginx 配置
if [ -f "/etc/nginx/ssl/server.crt" ] && [ -f "/etc/nginx/ssl/server.key" ]; then
    echo "Found SSL certificates. Enabling HTTPS config."
    cp /etc/nginx/templates/nginx-https.conf /etc/nginx/conf.d/default.conf
else
    echo "SSL certificates not found. Using HTTP config."
    cp /etc/nginx/templates/nginx-http.conf /etc/nginx/conf.d/default.conf
fi

# 启动 cron 服务
service cron start

# 启动 PHP-FPM
php-fpm -D

# 启动 Nginx (在前台运行以防止容器退出)
nginx -g "daemon off;"
