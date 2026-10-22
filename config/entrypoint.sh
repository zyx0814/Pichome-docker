#!/bin/sh

set -e

directory_empty() {
    [ -z "$(ls -A "$1/")" ]
}

# ============================================================
# 挂载目录权限处理（解决 bind mount 下 www-data 无写权限的问题）
# Docker 以 root / 755 创建宿主机挂载目录，而 PHP-FPM、Nginx 默认以
# www-data(uid 33) 运行，uid 不匹配会导致上传 / 缓存 / 配置写入失败。
# 做法：把 www-data 的 uid/gid 对齐到宿主机用户（PUID/PGID），
# 这样宿主机挂载进来的文件在容器内也归 www-data 所有，无需递归 chown。
#   - Linux 用户：在 docker-compose.yml 的 app 中设置
#       PUID=$(id -u)  PGID=$(id -g)
#   - Windows(Docker Desktop)：bind mount 通常对所有容器用户可写，保持默认 33/33 即可。
# ============================================================
PUID=${PUID:-33}
PGID=${PGID:-33}
if [ "$(id -u)" = "0" ]; then
    groupmod -o -g "$PGID" www-data 2>/dev/null || true
    usermod  -o -u "$PUID" -g www-data www-data 2>/dev/null || true
    # 确保网页根目录顶层对运行用户可写（应用需要创建 data/cache 等子目录）
    chown www-data:www-data /var/www/html 2>/dev/null || true
    # 确保证书目录对 Nginx 可读
    if [ -d /etc/nginx/ssl ]; then
        chmod 755 /etc/nginx/ssl 2>/dev/null || true
        chmod 644 /etc/nginx/ssl/* 2>/dev/null || true
    fi
fi
if [ ! -f "/var/www/html/index.php" ]; then
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
