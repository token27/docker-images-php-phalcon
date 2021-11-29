# syntax=docker/dockerfile:experimental
FROM php:7.2-cli-alpine3.7 as cli

LABEL maintainer="Token27 <admin@token27.com>" \
    org.opencontainers.image.title="php-cli-phalcon" \
    org.opencontainers.image.description="PHP CLI with Phalcon on Alpine Linux" \
    org.opencontainers.image.authors="Token27 <admin@token27.com>" \
    org.opencontainers.image.vendor="Token27" \
    org.opencontainers.image.version="v1.0.0" \
    org.opencontainers.image.url="https://hub.docker.com/r/token27/php-phalcon/" \
    org.opencontainers.image.source="https://github.com/token27/php-phalcon"

ARG version_phalcon
ENV PHALCON_VERSION=$version_phalcon

ARG version_phalcon_devtools
ENV PHALCON_DEVTOOLS_VERSION=$version_phalcon_devtools

ENV XDEBUG_MODE="develop, debug, coverage"
ENV XDEDUG_IDEKEY="PHPSTORM"
ENV XDEBUG_REMOTE_HOST=host.docker.internal
ENV XDEBUG_REMOTE_PORT="9003"
ENV XDEBUG_START_WITH_REQUEST="yes"
ENV XDEBUG_LOG_FILE="/var/log/php/xdebug.log"
ENV XDEBUG_LOG_LEVEL="10"

ENV PHP_MAX_UPLOAD_SIZE="64M"
ENV PHP_POST_MAX_SIZE="64M"
ENV PHP_INI_SCAN_DIR="/usr/local/etc/php/conf.d/"

ENV APP_OWNER=app
ENV APP_GROUP=app

# Add user and group
RUN set -x \
    && addgroup -g 1000 ${APP_OWNER} \
    && adduser -u 1000 -D -G ${APP_OWNER} ${APP_GROUP}

# Temporary fix: pulls in the aports patch for https://bugs.alpinelinux.org/issues/10648
RUN apk add --no-cache --upgrade apk-tools \
    && apk add --no-cache --upgrade nano vim curl wget  zip unzip git g++ make autoconf bash supervisor tzdata gettext gcc pkgconf

# Extensions
RUN apk add --no-cache --upgrade \
    libxml2-dev \
    libxpm-dev \
    libxslt-dev \
    libevent-dev \
    libsodium-dev \
    libaio-dev \
    libmemcached-dev \
    libzip-dev \
    libpng-dev \
    libmcrypt-dev \
    libc-dev \
    libpcre32 \
    libbz2 \
    icu-dev \
    freetds-dev \
    unixodbc-dev \
    postgresql-dev \
    openssl-dev \
    openssh-server \
    openssh-client \
    bzip2-dev \
    cyrus-sasl-dev \
    binutils

# PHP Extensions
RUN apk add --no-cache --upgrade \
    php-curl \
    php-dom \
    php-fileinfo \
    php-gd \
    php-gettext \
    php-json \
    php-mbstring \
    php-openssl \
    php-pdo \
    php-phar \
    php-opcache \
    php-session \
    php-simplexml \
    php-tokenizer \
    php-xml \
    php-zlib \
    php-pear


# Install docker help scripts
COPY src/php/utils/docker/ /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-php-*

# Install
RUN apk add --no-cache --virtual .phpize-deps $PHPIZE_DEPS \
    && docker-php-ext-install pcntl opcache zip sockets ftp \
    && pecl channel-update pecl.php.net \
    && pecl install \
        apcu \
        event \
        libsodium \
        mongodb \
        redis \
        memcached \
    && pecl clear-cache

#
RUN docker-php-ext-enable apcu \
    && docker-php-ext-enable event \
    && mv /usr/local/etc/php/conf.d/docker-php-ext-event.ini \
        /usr/local/etc/php/conf.d/docker-php-ext-zz-event.ini \
    && docker-php-ext-enable \
    sodium \
    opcache \
    sockets

# Install modules
RUN docker-php-ext-install \
    pdo \
    pdo_dblib \
    pdo_mysql \
    mysqli \
    iconv \
    exif \
    soap \
    calendar

# Configure modules
RUN docker-php-ext-configure intl \
    && docker-php-ext-install intl \
    && docker-php-ext-enable intl

# Enable modules
RUN docker-php-ext-enable \
    redis \
    memcached \
    pdo \
    pdo_mysql \
    mysqli \
    sodium \
    mongodb \
    calendar \
    exif

# Install mycrpt
COPY src/php/utils/install-mycrpt /usr/local/bin/
RUN chmod +x /usr/local/bin/install-mycrpt \
    && install-mycrpt \
    && rm -rf /usr/local/bin/install-mycrpt

# Install PDO SQLSRV
COPY src/php/utils/install-pdo-sqlsrv /usr/local/bin/
RUN chmod +x /usr/local/bin/install-pdo-sqlsrv \
    && install-pdo-sqlsrv \
    && rm -rf /usr/local/bin/install-pdo-sqlsrv

# Install GD
COPY src/php/utils/install-gd /usr/local/bin/
RUN chmod +x /usr/local/bin/install-gd \
    && install-gd \
    && rm -rf /usr/local/bin/install-gd

# Website dir
RUN mkdir -p /var/www/html \
    && chown -R ${APP_OWNER}:${APP_GROUP} /var/www/html \
    && chmod 755 -R /var/www/html


# Php logs
RUN mkdir -p /var/log/php && \
    touch /var/log/php/xdebug.log && \
    touch /var/log/php/php_errors.log && \
    touch /var/log/php/php_access.log && \
    touch /var/log/php/php-fpm_errors.log && \
    touch /var/log/php/php-fpm_access.log && \
    chown -R ${APP_OWNER}:${APP_GROUP} /var/log/php

# Cakephp Installer
COPY src/php/utils/docker/docker-cakephp-create-project /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-cakephp-create-project

# Install psr
COPY src/php/utils/install-psr /usr/local/bin/
RUN chmod +x /usr/local/bin/install-psr \
    && install-psr \
    && rm -rf /usr/local/bin/install-psr

# Install phalcon
COPY src/php/utils/install-phalcon /usr/local/bin/
RUN chmod +x /usr/local/bin/install-phalcon \
    && install-phalcon ${PHALCON_VERSION} \
    && rm -rf /usr/local/bin/install-phalcon

# Install phalcon devtools
COPY src/php/utils/install-phalcon-devtools /usr/local/bin/
RUN chmod +x /usr/local/bin/install-phalcon-devtools \
    && install-phalcon-devtools ${PHALCON_DEVTOOLS_VERSION} \
    && rm -rf /usr/local/bin/install-phalcon-devtools

# Removing all PHP leftovers since the helper scripts nor the official image are removing them
RUN docker-php-source-tarball clean && rm /usr/local/bin/php-cgi && rm /usr/local/bin/phpdbg && rm -rf /tmp/pear ~/.pearrc \
  && apk del .phpize-deps \
  && rm -rf /var/cache/apk/*

# Create a symlink to the recommended production configuration
# ref: https://github.com/docker-library/docs/tree/master/php#configuration
COPY src/php/conf/available/production.ini $PHP_INI_DIR/php.ini-production
RUN ln -s $PHP_INI_DIR/php.ini-production $PHP_INI_DIR/php.ini

COPY src/gpg /usr/local/etc/gpg
COPY src/php/conf/ /usr/local/etc/php/conf.d/
COPY src/php/conf/*.ini /usr/local/etc/php/conf.d/
COPY src/php/cli/conf/*.ini /usr/local/etc/php/conf.d/

RUN mkdir -p /usr/local/etc/php/conf.d/ \
    && touch /usr/local/etc/php/conf.d/020-cli.ini
COPY src/php/cli/conf/020-cli.ini /usr/local/etc/php/conf.d/020-cli.ini
RUN mkdir -p $PHP_INI_DIR/conf.d/ \
    && touch $PHP_INI_DIR/conf.d/020-cli.ini
COPY src/php/cli/conf/020-cli.ini $PHP_INI_DIR/conf.d/020-cli.ini

# Install shush
COPY src/php/utils/install-shush /usr/local/bin/
RUN chmod +x /usr/local/bin/install-shush \
    && install-shush \
    && rm -rf /usr/local/bin/install-shush

# Install composer
COPY src/php/utils/install-composer /usr/local/bin/
RUN chmod +x /usr/local/bin/install-composer \
    && install-composer \
    && rm -rf /usr/local/bin/install-composer

STOPSIGNAL SIGTERM

ENTRYPOINT ["/usr/local/bin/shush", "exec", "docker-php-entrypoint"]

# Base images don't need healthcheck since they are not running applications
# this can be overriden in the child images
HEALTHCHECK NONE

## CLI-DEV STAGE ##
FROM cli as cli-dev

COPY src/php/conf/available/development.ini $PHP_INI_DIR/php.ini-development

# Install Xdebug and development specific configuration
RUN docker-php-dev-mode xdebug \
    && docker-php-dev-mode config

# Change entrypoint back to the default because we don't need shush in development
ENTRYPOINT ["docker-php-entrypoint"]
