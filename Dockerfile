# 使用 PHP 8.4-FPM 作为基础镜像 (基于 Debian Bookworm)
FROM php:8.4-fpm-bookworm

# 设置工作目录
WORKDIR /var/www/html

# 设置环境变量以避免交互式提示
ENV DEBIAN_FRONTEND=noninteractive


# 替换为更通用的镜像源 (支持多架构 amd64, arm64, arm/v6, arm/v7 等)
# 针对国内用户，可以使用阿里云加速，但保留原始结构以支持多架构
# 使用 sed 在现有源后追加 contrib non-free (兼容 Debian 12)
RUN find /etc/apt/sources.list* -type f -exec sed -i 's/main/main contrib non-free/g' {} + && \
    find /etc/apt/sources.list* -type f -exec sed -i 's/deb.debian.org/mirrors.aliyun.com/g' {} + && \
    find /etc/apt/sources.list* -type f -exec sed -i 's/security.debian.org/mirrors.aliyun.com/g' {} + || true

# 合并安装步骤以减少层数并提高稳定性
# 增加重试机制和网络容错，如果安装失败则回退到默认源
RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    (apt-get update -y || (sleep 5 && apt-get update -y)) && \
    apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    gnupg \
    unzip \
    rsync \
    nginx \
    cron \
    libpng-dev \
    libjpeg62-turbo-dev \
    libfreetype6-dev \
    libwebp-dev \
    libonig-dev \
    libzip-dev \
    libcurl4-openssl-dev \
    libtidy-dev \
    libxslt1-dev \
    libmagickwand-dev \
    libicu-dev \
    libbz2-dev \
    libxml2-dev \
    libreadline-dev \
    libedit-dev \
    libsqlite3-dev \
    libheif-dev \
    libopenjp2-7-dev \
    imagemagick \
    ffmpeg \
    libraw-bin \
    dcraw \
    ghostscript || \
    (echo "Installation failed, falling back to default mirrors..." && \
     find /etc/apt/sources.list* -type f -exec sed -i 's/mirrors.aliyun.com/deb.debian.org/g' {} + && \
     apt-get update -y && \
     apt-get install -y --no-install-recommends \
     ca-certificates curl gnupg unzip nginx cron libpng-dev libjpeg62-turbo-dev libfreetype6-dev \
     libwebp-dev libonig-dev libzip-dev libcurl4-openssl-dev libtidy-dev libxslt1-dev \
     libmagickwand-dev libicu-dev libbz2-dev libxml2-dev libreadline-dev libedit-dev libsqlite3-dev libheif-dev \
     libopenjp2-7-dev imagemagick ffmpeg libraw-bin dcraw ghostscript) \
    && rm -rf /var/lib/apt/lists/*

# 配置并安装 PHP 扩展
# 包括要求的扩展及常用的基础扩展
# 注意：在 PHP 8.4 中，curl, dom, mbstring, simplexml, pdo_sqlite, sqlite3 已内置，无需重复安装
RUN docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp \
    && docker-php-ext-install -j$(nproc) \
        gd \
        intl \
        pcntl \
        posix \
        xsl \
        zip \
        tidy \
        mysqli \
        opcache \
        pdo_mysql \
        exif \
        sockets \
        bz2 \
        soap


# 安装 PECL 扩展: imagick, redis
# 针对 PHP 8.4，imagick 需要从 master 分支编译以获得支持
RUN mkdir -p /usr/src/php/ext/imagick && \
    curl -fsSL https://github.com/Imagick/imagick/archive/refs/heads/master.tar.gz | tar xvz -C /usr/src/php/ext/imagick --strip-components=1 && \
    docker-php-ext-install imagick && \
    pecl install redis && \
    docker-php-ext-enable redis

# 配置 ImageMagick 代理以使用 dcraw 处理 RAW/DNG 格式 (推荐两段式)
RUN sed -i '/decode="\(dng:decode\|arw:decode\|cr2:decode\|nef:decode\|orf:decode\|rw2:decode\)"/d' /etc/ImageMagick-6/delegates.xml && \
    sed -i '/<delegatemap>/a \  <delegate decode="dng:decode" stealth="True" command="\&quot;dcraw\&quot; -c -6 -W -o 1 \&quot;%i\&quot; > \&quot;%u.ppm\&quot;"/>' /etc/ImageMagick-6/delegates.xml && \
    sed -i '/<delegatemap>/a \  <delegate decode="arw:decode" stealth="True" command="\&quot;dcraw\&quot; -c -6 -W -o 1 \&quot;%i\&quot; > \&quot;%u.ppm\&quot;"/>' /etc/ImageMagick-6/delegates.xml && \
    sed -i '/<delegatemap>/a \  <delegate decode="cr2:decode" stealth="True" command="\&quot;dcraw\&quot; -c -6 -W -o 1 \&quot;%i\&quot; > \&quot;%u.ppm\&quot;"/>' /etc/ImageMagick-6/delegates.xml && \
    sed -i '/<delegatemap>/a \  <delegate decode="nef:decode" stealth="True" command="\&quot;dcraw\&quot; -c -6 -W -o 1 \&quot;%i\&quot; > \&quot;%u.ppm\&quot;"/>' /etc/ImageMagick-6/delegates.xml && \
    sed -i '/<delegatemap>/a \  <delegate decode="orf:decode" stealth="True" command="\&quot;dcraw\&quot; -c -6 -W -o 1 \&quot;%i\&quot; > \&quot;%u.ppm\&quot;"/>' /etc/ImageMagick-6/delegates.xml && \
    sed -i '/<delegatemap>/a \  <delegate decode="rw2:decode" stealth="True" command="\&quot;dcraw\&quot; -c -6 -W -o 1 \&quot;%i\&quot; > \&quot;%u.ppm\&quot;"/>' /etc/ImageMagick-6/delegates.xml

# 配置 ImageMagick 允许处理相关格式 (包括 RAW, PDF, PSD, HEIC, AVIF 等)
RUN for pattern in PDF EPS XPS PS PS2 PS3 PLT DNG CR2 PSD RAW HEIC HEIF AVIF TIFF; do \
        if grep -q "pattern=\"$pattern\"" /etc/ImageMagick-6/policy.xml; then \
            sed -i "s/rights=\"none\" pattern=\"$pattern\"/rights=\"read|write\" pattern=\"$pattern\"/g" /etc/ImageMagick-6/policy.xml; \
        else \
            sed -i "/<\/policymap>/i \  <policy domain=\"coder\" rights=\"read|write\" pattern=\"$pattern\" \/>" /etc/ImageMagick-6/policy.xml; \
        fi \
    done && \
    sed -i '/domain="path" rights="none" pattern="@*"/d' /etc/ImageMagick-6/policy.xml || true

# 安装 Composer (PHP 依赖管理工具)
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# 复制 Nginx 配置模板并清理默认配置
RUN mkdir -p /etc/nginx/templates && \
    rm -f /etc/nginx/sites-enabled/default
COPY ./config/nginx.conf /etc/nginx/nginx.conf
COPY ./config/nginx-http.conf /etc/nginx/templates/nginx-http.conf
COPY ./config/nginx-https.conf /etc/nginx/templates/nginx-https.conf

# 复制优化的 PHP 和 PHP-FPM 配置

COPY ./config/custom-php.ini /usr/local/etc/php/conf.d/99-custom.ini
COPY ./config/php-fpm-www.conf /usr/local/etc/php-fpm.d/www.conf

# 复制启动脚本和定时任务脚本
COPY ./config/entrypoint.sh /usr/local/bin/entrypoint.sh
COPY ./config/cron-task.sh /usr/local/bin/cron-task.sh
RUN chmod +x /usr/local/bin/entrypoint.sh /usr/local/bin/cron-task.sh

# 设置定时任务 (每 5 分钟执行一次)
RUN echo "*/5 * * * * root /usr/local/bin/cron-task.sh >> /var/log/cron.log 2>&1" > /etc/cron.d/cron-task && \
    chmod 0644 /etc/cron.d/cron-task && \
    touch /var/log/cron.log

# 暴露 80 和 443 端口
EXPOSE 80 443

# 使用自定义启动脚本
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
