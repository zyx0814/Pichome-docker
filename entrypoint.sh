#!/bin/sh

set -e

directory_empty() {
    [ -z "$(ls -A "$1/")" ]
}
if  directory_empty "/var/www/html"; then
        if [ "$(id -u)" = 0 ]; then
            rsync_options="-rlDog --chown nginx:root"
        else
            rsync_options="-rlD"
        fi
        echo "PICHOME is downloading ..."
        apk add --no-cache --virtual .fetch-deps gnupg
        curl -fsSL -o pichome.zip "https://codeload.github.com/zyx0814/Pichome/zip/refs/heads/master"
        export GNUPGHOME="$(mktemp -d)"
        unzip pichome.zip -d /usr/src/
        gpgconf --kill all
        rm pichome.zip
        rm -rf "$GNUPGHOME"
        apk del .fetch-deps
        echo "PICHOME is installing ..."
        rsync $rsync_options --delete /usr/src/Pichome-master/ /var/www/html/
else
        echo "PICHOME has been configured!"
fi
if [ -f /etc/nginx/ssl/fullchain.pem ] && [ -f /etc/nginx/ssl/privkey.pem ] && [ ! -f /etc/nginx/sites-enabled/*-ssl.conf ] ; then
        ln -s /etc/nginx/sites-available/private-ssl.conf /etc/nginx/sites-enabled/
        sed -i "s/#return 301/return 301/g" /etc/nginx/sites-available/default.conf
fi

exec "$@"
