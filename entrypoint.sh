#!/bin/sh
set -eu

# return true if specified directory is empty
directory_empty() {
    [ -z "$(ls -A "$1/")" ]
}

waiting_for_connection(){
  until nc -z -w 3 "$1" "$2"; do
    >&2 echo "Waiting for connection to the $1 host on port $2"
    sleep 1
  done
}

file_env() {
    local var="$1"
    local fileVar="${var}_FILE"
    local def="${2:-}"
    local varValue=$(env | grep -E "^${var}=" | sed -E -e "s/^${var}=//")
    local fileVarValue=$(env | grep -E "^${fileVar}=" | sed -E -e "s/^${fileVar}=//")
    if [ -n "${varValue}" ] && [ -n "${fileVarValue}" ]; then
        echo >&2 "error: both $var and $fileVar are set (but are exclusive)"
        exit 1
    fi
    if [ -n "${varValue}" ]; then
        export "$var"="${varValue}"
    elif [ -n "${fileVarValue}" ]; then
        export "$var"="$(cat "${fileVarValue}")"
    elif [ -n "${def}" ]; then
        export "$var"="$def"
    fi
    unset "$fileVar"
}

file_env MYSQL_SERVER
file_env MYSQL_DATABASE
file_env MYSQL_USER
file_env MYSQL_PASSWORD
file_env MYSQL_PORT



MYSQL_PORT=${MYSQL_PORT:-3306}


waiting_for_db(){
  waiting_for_connection $MYSQL_SERVER $MYSQL_PORT
}

waiting_for_session(){
  waiting_for_connection $SESSION_HOST $SESSION_PORT
}



if  directory_empty "/var/www/html"; then
        if [ "$(id -u)" = 0 ]; then
            rsync_options="-rlDog --chown nginx:root"
        else
            rsync_options="-rlD"
        fi
        echo "PICHOME is installing ..."
        rsync $rsync_options --delete /usr/src/pichome/ /var/www/html/
        
else
        echo "PICHOME has been configured!"
fi

if [ -f /etc/nginx/ssl/fullchain.pem ] && [ -f /etc/nginx/ssl/privkey.pem ] && [ ! -f /etc/nginx/sites-enabled/*-ssl.conf ] ; then
        ln -s /etc/nginx/sites-available/private-ssl.conf /etc/nginx/sites-enabled/
        sed -i "s/#return 301/return 301/g" /etc/nginx/sites-available/default.conf
fi

exec "$@"

