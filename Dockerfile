# 第一阶段：下载 WordPress
FROM alpine:latest AS wordpress-downloader

RUN apk --no-cache add curl tar && \
    curl -o wordpress.tar.gz https://wordpress.org/latest.tar.gz && \
    mkdir -p /app && \
    tar -xzvf wordpress.tar.gz --strip-components=1 --directory /app && \
    rm wordpress.tar.gz


# 第二阶段：设置 Nginx 和 PHP
FROM nginx:stable-alpine

WORKDIR /app
COPY --from=wordpress-downloader /app /app

# 设置权限
RUN chown -R nginx:nginx /app && chmod -R 755 /app

# 安装 PHP 和必要的扩展
RUN apk --update add --no-cache \
    php83 \
    php83-fpm \
    php83-pdo \
    php83-sqlite3 \
    php83-zip \
    php83-curl \
    php83-gd \
    php83-intl \
    php83-xsl \
    php83-mbstring \
    php83-dom \
    php83-json \
    php83-openssl \
    php83-pdo_sqlite \
    php83-zlib \
    php83-fileinfo \
    php83-opcache \
    php83-imap \
    php83-redis \
    php83-exif \
    && rm -rf /var/cache/apk/*

# 复制自定义 PHP 和 Nginx 配置文件
COPY nginx.conf /etc/nginx/nginx.conf
COPY php.ini /etc/php83/php.ini
COPY www.conf /etc/php83/php-fpm.d/www.conf
COPY default /etc/nginx/sites-available/default
RUN mkdir -p /etc/nginx/sites-enabled \
    && ln -s /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default
# 复制 WordPress 文件和其他资源
COPY sqlite-database-integration /app/wp-content/plugins/sqlite-database-integration
COPY config.php /app/wp-config.php
RUN  cp /app/wp-content/plugins/sqlite-database-integration/db.copy /app/wp-content/db.php
# 复制启动脚本
COPY start.sh /start.sh
RUN chmod +x /start.sh

# 曝光必要端口
EXPOSE 80

# 启动服务
CMD ["/start.sh"]
