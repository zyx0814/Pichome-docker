#!/bin/bash

# 定时任务 URL 配置文件路径
URL_FILE="/var/www/html/cron_url.txt"

# 检查文件是否存在
if [ ! -f "$URL_FILE" ]; then
    echo "$(date): Cron URL file $URL_FILE not found."
    exit 0
fi

# 读取第一行作为 URL
CRON_URL=$(head -n 1 "$URL_FILE" | tr -d '\r\n' | xargs)

# 检查 URL 是否为空
if [ -z "$CRON_URL" ]; then
    echo "$(date): Cron URL file is empty."
    exit 0
fi

# 执行 curl
echo "$(date): Running curl for $CRON_URL"
curl -s -k "$CRON_URL" > /dev/null 2>&1
