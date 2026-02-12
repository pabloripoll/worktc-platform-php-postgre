ARG ALPINE_VERSION=3.21
ARG PHP_VERSION=8.3

FROM alpine:${ALPINE_VERSION}
FROM php:${PHP_VERSION}-fpm-alpine

ARG PHP_MODULE="php83"

# Setup unique user and group - needs bash
RUN apk add --no-cache bash

ARG UID
ARG GID
ENV UID=${UID}
ENV GID=${GID}
ARG USER
ARG GROUP
ENV USER=${USER}
ENV GROUP=${GROUP}

# Create user and group
RUN addgroup -S --gid ${GID} ${GROUP} \
    && adduser -S --uid ${UID} ${USER} -s /bin/sh -G ${GROUP} ${USER} \
    && apk add --no-cache sudo \
    && chmod u+s /bin/su \
    && echo "${USER} ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# Install main required packages
RUN apk add --no-cache \
  openrc \
  curl \
  wget \
  openssl \
  nginx \
  libva-dev \
  # OS extras
  git \
  nano \
  #zip \
  #ffmpeg \
  # Process Control System
  supervisor

RUN set -xe \
    && apk add --no-cache --virtual .build-deps \
      $PHPIZE_DEPS \
      libzip-dev \
      freetype-dev \
      icu-dev \
      libmcrypt-dev \
      libjpeg-turbo-dev \
      libpng-dev \
      libxslt-dev \
      patch \
      openssh-client

# Install PHP and its extensions packages
ENV PHP_V=$PHP_MODULE
RUN apk add --no-cache \
  ${PHP_V} \
  ${PHP_V}-cli \
  ${PHP_V}-fpm \
  ${PHP_V}-ctype \
  ${PHP_V}-curl \
  ${PHP_V}-dom \
  ${PHP_V}-fileinfo \
  ${PHP_V}-gd \
  ${PHP_V}-intl \
  ${PHP_V}-mbstring \
  ${PHP_V}-opcache \
  ${PHP_V}-openssl \
  ${PHP_V}-phar \
  ${PHP_V}-session \
  ${PHP_V}-tokenizer \
  ${PHP_V}-soap \
  ${PHP_V}-xml \
  ${PHP_V}-xmlreader \
  ${PHP_V}-xmlwriter \
  ${PHP_V}-simplexml \
  ${PHP_V}-zip \
  ${PHP_V}-bcmath \
  ## Databases
  ${PHP_V}-pdo \
  # SQLite
  ${PHP_V}-pdo_sqlite \
  ${PHP_V}-sqlite3 \
  # MySQL - MariaDB
  #${PHP_V}-pdo_mysql \
  #${PHP_V}-mysqlnd \
  #${PHP_V}-mysqli \
  # Postgre
  ${PHP_V}-pgsql \
  ${PHP_V}-pdo_pgsql \
  postgresql-dev \
  # MongoDB
  ${PHP_V}-pecl-mongodb \
  # Redis
  ${PHP_V}-pecl-amqp
  # XDebug
  #${PHP_V}-pecl-xdebug

# Install amqp via PECL for clients that use the native ext-amqp like RabbitMQ
RUN apk add --no-cache rabbitmq-c
RUN set -eux; \
    apk add --no-cache --virtual .amqp-build-deps $PHPIZE_DEPS rabbitmq-c-dev; \
    pecl install amqp; \
    docker-php-ext-enable amqp; \
    php -m | grep -i amqp; \
    apk del .amqp-build-deps; \
    rm -rf /tmp/pear ~/.pearrc

# Install PHP required extensions from Docker
RUN docker-php-ext-install \
  pdo \
  pdo_pgsql \
  pcntl \
  sockets

# Install MongoDB extension from PECL
RUN pecl install mongodb-2.1.0 \
    && docker-php-ext-enable mongodb

# Clean up build dependencies to reduce image size
RUN apk del .build-deps

# Configure NGINX and remove created its default html directory
COPY config/nginx/nginx.conf /etc/nginx/nginx.conf
COPY config/nginx/conf.d /etc/nginx/conf.d/
RUN rm -rf /var/www/html

# Configure PHP-FPM
COPY config/php/conf.d/fpm-pool.conf /etc/${PHP_V}/php-fpm.d/www.conf
COPY config/php/conf.d/php.ini /etc/${PHP_V}/conf.d/custom.ini

# Create symlink for php
RUN ln -s -f /usr/bin/${PHP_V} /usr/bin/php

# Configure Supervisor
COPY config/supervisor/supervisord.conf /etc/supervisor/supervisord.conf
COPY config/supervisor/conf.d/. /etc/supervisor/conf.d/

# Create predifined Crontab and apply file permissions
COPY config/crontab /var/spool/cron/crontabs/root
RUN chmod -R 0644 /var/spool/cron/crontabs/root

# PHP Composer
COPY --from=composer:latest /usr/bin/composer /usr/local/bin/composer

## Configure XDebug - (optional - uncomment line to use it)
#COPY config/php/xdebug.ini /etc/${PHP_V}/conf.d/xdebug.ini

# Create project root and set it as work directory
RUN mkdir -p /var/www
WORKDIR /var/www

# Add application from docker-compose.yml -> volumes: source
COPY --chown=${USER}:${GROUP} ../ /var/www

# Remove unused directories
RUN rm -rf /var/www/html /var/www/localhost

# Make sure files/folders needed by the processes are accessable when they run under the nobody user
RUN chown -R ${USER}:${GROUP} /var/www /run /var/lib/nginx /var/log/nginx

# Switch to use a non-root user from here on
USER ${USER}

# Expose as many ports as required - Nginx: 80 / SSL: 443 / Xdebug: 9003
EXPOSE 80

# Let supervisord start nginx & php-fpm
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]
