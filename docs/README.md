# PHP Phalcon Docker Images Builder

An easy way to create and maintain PHP Phalcon Docker images

- [Using and extending](#using-and-extending)
    - [PHP](#for-php-customization)
        - [Setting up Xdebug](#setting-up-xdebug)
        - [PHP Core extensions](#php-core-extensions)
        - [PECL extensions](#pecl-extensions)
        - [Healthcheck](#php-fpm-healthcheck)
- [The base images](#the-base-images)
- [Alpine Linux situation](#alpine-linux-situation)
- [The available tags](#the-available-tags)
- [Adding more supported versions](#adding-more-supported-versions)

## The base images

All images are based on their official variants, being:

- [PHP official image](https://hub.docker.com/_/php/)

## Alpine Linux situation

Even though both of the images are based on the Alpine Linux, the PHP official repository gives us the option to choose
between its versions, at this moment being `3.9` or `3.10`.

Meanwhile on the official Nginx images we have no control over which Alpine version we use, this explains the tagging
strategy coming in the next section.

## The available tags

The docker registry prefix is `token27/php-phalcon`, thus `token27/php-phalcon:OUR-TAGS`.

[Currently Available tags on Docker hub](https://hub.docker.com/r/token27/php-phalcon/tags/)

The tag naming strategy consists of (Read as a regex):

- PHP: `(phpMajor).(phpMinor)-(cli|fpm)-(alpine|future supported OSes)(alpineMajor).(alpineMinor)(-dev)?`
    - Example: `7.3-fpm-alpine3.11`, `7.3-fpm-alpine3.11-dev`
    - Note: The minor version might come followed by special versioning constraints in case of betas, etc. For instance
      `7.3-rc-fpm-alpine3.11-dev`

## Adding more supported versions

The whole CI/CD pipeline is centralized in Makefile targets, the build of cli and fpm images have their targets named
as `build-cli` and `build-fpm`.

With the help of building scripts the addition of new versions is as easy as updating the Makefile with the desired new
version.

All the newly built versions are going to be automatically tagged and pushed upon CI/CD success, to see the output of
your new changes you can see the `(BUILD).tags` file in the `tmp` directory.

### Example

In this example adding PHP 7.4-rc for cli and fpm:

```diff
build-cli: clean-tags
	./build-php.sh cli 7.4 3.10 [PHALCON_VERSION] [PHALCON_DEVTOOLS_VERSION]
	./build-php.sh cli 7.4 3.11 [PHALCON_VERSION] [PHALCON_DEVTOOLS_VERSION]
+	./build-php.sh cli 7.4-rc 3.12 [PHALCON_VERSION] [PHALCON_DEVTOOLS_VERSION]

build-fpm: clean-tags
	./build-php.sh fpm 7.4 3.10 [PHALCON_VERSION] [PHALCON_DEVTOOLS_VERSION]
	./build-php.sh fpm 7.4 3.11 [PHALCON_VERSION] [PHALCON_DEVTOOLS_VERSION]
+	./build-php.sh fpm 7.4-rc 3.12 [PHALCON_VERSION] [PHALCON_DEVTOOLS_VERSION]
```

Being `./build-php.sh (cli/fpm) (PHP version) (Alpine version)`

### Important

Removing a version from the build will not remove it from the Docker registry, this has to be done manually when
desired.

## Using and extending

### PHP FPM healthcheck

This image ships with the [php-fpm-healthcheck](https://github.com/renatomefi/php-fpm-healthcheck) which allows you to
healthcheck FPM independently of the Nginx setup, providing more compatibility
with [the single process Docker container](https://cloud.google.com/solutions/best-practices-for-building-containers#package_a_single_app_per_container)
.

This healthcheck provides diverse metrics to watch and can be configured according to your needs. More information on
how to use it can be found in the
[official documentation](https://github.com/renatomefi/php-fpm-healthcheck#a-php-fpm-health-check-script).

The healthcheck can be found in the container `$PATH` as an executable:

```console
$ php-fpm-healthcheck
$ echo $?
0
```

## Basic usage

Simply use the images as base of the application's `Dockerfile` and apply the necessary changes.

```Dockerfile
# syntax=docker/dockerfile:1.0.0-experimental

FROM token27/php-phalcon:fpm-7.2-phalcon-3.4.5
```

## For PHP customization

### PHP-FPM Configuration

To allow tuning the FPM pool, some pool directives are configurable via the following environment variables. For more
information on these directives, see [the documentation](https://www.php.net/manual/en/install.fpm.configuration.php).

| Directive               | Environment Variable            | Default                 |
|-------------------------|---------------------------------|-------------------------|
| pm                      | PHP_FPM_PM                      | dynamic                 |
| pm.max_children         | PHP_FPM_PM_MAX_CHILDREN         | 5                       |
| pm.start_servers        | PHP_FPM_PM_START_SERVERS        | 2                       |
| pm.min_spare_servers    | PHP_FPM_PM_MIN_SPARE_SERVERS    | 1                       |
| pm.max_spare_servers    | PHP_FPM_PM_MAX_SPARE_SERVERS    | 3                       |
| pm.process_idle_timeout | PHP_FPM_PM_PROCESS_IDLE_TIMEOUT | 10                      |
| pm.max_requests         | PHP_FPM_PM_MAX_REQUESTS         | 0                       |
| pm.status_path          | PHP_FPM_PM_STATUS_PATH          | /status                 |
| access.format           | PHP_FPM_ACCESS_FORMAT           | %R - %u %t \"%m %r\" %s |
| listen                  | FCGI_CONNECT                    | /var/run/php-fpm.sock   |
| listen.owner            | FCGI_OWNER                      | app                     |
| listen.group            | FCGI_GROUP                      | app                     |
| listen.mode             | FCGI_LISTEN_MODE                | 0666                    |

An example Dockerfile with customized configuration might look like:

```Dockerfile
# syntax=docker/dockerfile:1.0.0-experimental

FROM token27/php-phalcon:fpm-7.2-phalcon-3.4.5

ENV PHP_FPM_PM="static"
ENV PHP_FPM_PM_MAX_CHILDREN="70"
ENV PHP_FPM_PM_START_SERVERS="10"
ENV PHP_FPM_PM_MIN_SPARE_SERVERS="20"
ENV PHP_FPM_PM_MAX_SPARE_SERVERS="40" 
ENV PHP_FPM_PM_PROCESS_IDLE_TIMEOUT="35"
ENV PHP_FPM_PM_MAX_REQUESTS="500"
ENV PHP_FPM_ACCESS_FORMAT {\\\"cpu_usage\\\":%C,\\\"memory_usage\\\":%M,\\\"duration_microsecond\\\":%d,\\\"script\\\":\\\"%f\\\",\\\"content_length\\\":%l,\\\"request_method\\\":\\\"%m\\\",\\\"pool_name\\\":\\\"%n\\\",\\\"process_id\\\":\\\"%p\\\",\\\"request_query_string\\\":\\\"%q\\\",\\\"request_uri_query_string_glue\\\":\\\"%Q\\\",\\\"request_uri\\\":\\\"%r\\\",\\\"request_url\\\":\\\"%r%Q%q\\\",\\\"remote_ip_address\\\":\\\"%R\\\",\\\"response_status_code\\\":%s,\\\"time\\\":\\\"%t\\\",\\\"remote_user\\\":\\\"%u\\\"}
```

### PHP configuration

The official PHP images ship with recommended
[`ini` configuration files](https://github.com/docker-library/docs/tree/master/php#configuration) for both development
and production. In order to guarantee a reasonable configuration, our images load these files by default in each image
respectively at this path: `$PHP_INI_DIR/php.ini`.

Images that wish to extend the ones provided in this repository can override these configurations easily by including
customized configuration files in the `$PHP_INI_DIR/conf.d/` directory.

### Installing & enabling PHP extensions

This image bundles helper scripts to manage PHP extensions (`docker-php-ext-configure`, `docker-php-ext-install`, and
`docker-php-ext-enable`), so it's quite simple to install core and PECL extensions.

More about it in
the [Official Documentation](https://github.com/docker-library/docs/blob/master/php/README.md#how-to-install-more-php-extensions)
.

#### PHP Core extensions

To install a core extension that doesn't require any change in the way PHP is compiled you only need to use
`docker-php-ext-install`, which will compile the extra extension and enable it.

To do it should include something like this to your `Dockerfile`:

```Dockerfile
# Enables opcache:
RUN set -x \
    && apk add --no-cache gnupg \
    && docker-php-source-tarball download \
    && docker-php-ext-install opcache \
    && docker-php-source-tarball delete

# Installs PDO driver for PostgreSQL (temporarily adding postgresql-dev to have
# the necessary C libraries):
RUN set -x \
    && apk add --no-cache gnupg postgresql-client postgresql-dev \
    && docker-php-source-tarball download \
    && docker-php-ext-install pdo_pgsql \
    && docker-php-source-tarball delete \
    && apk del gnupg postgresql-dev
```

Some core extensions, like GD, requires changes to PHP compilation. For that you should also
use `docker-php-ext-configure`, e.g.:

```Dockerfile
# Installs GD extension and the required libraries: 
RUN set -x \
    apk add --no-cache imagemagick-dev freetype-dev libjpeg-turbo-dev libpng-dev libwebp-dev libzip-dev \
    && docker-php-ext-configure gd \
        --with-freetype-dir=/usr/include/ \
        --with-jpeg-dir=/usr/include/ \
        --with-png-dir=/usr/include/ \
        --with-webp-dir=/usr/include/ \
    && docker-php-ext-install gd
```

#### PECL extensions

Some extensions are not provided with the PHP source, but are instead available through [PECL](https://pecl.php.net/),
see a full list of them [here](https://pecl.php.net/packages.php).

To install a PECL extension, use `pecl install` to download and compile it, then use `docker-php-ext-enable` to enable
it:

```Dockerfile
# Installs ast extension (temporarily adding the necessary libraries):
RUN set -x \
    && apk add --no-cache --virtual .phpize-deps $PHPIZE_DEPS \
    && pecl install ast \
    && docker-php-ext-enable ast \
    && apk del .phpize-deps
```

Check if the extension is loaded after building it:

```console
$ docker build .
Successfully built 5b4s0f2d33b0
$ docker run --rm 5b4s0f2d33b0 php -m | grep ast
ast
```

```Dockerfile
# Installs MongoDB Driver (temporarily adding the necessary libraries):
RUN set -x \
    && apk add --no-cache --virtual .build-deps $PHPIZE_DEPS openssl-dev  \
    && pecl install mongodb-1.5.3 \
    && docker-php-ext-enable mongodb \
    && apk del .build-deps
```

#### Common extension helper scripts

Some extensions are used across multiple projects but can have some complexities while installing so we ship helper
scripts with the PHP images to install dependencies and enable the extension. The following helper scripts can be run
inside projects' Dockerfile:

- `docker-php-ext-rdkafka` for RD Kafka
- `docker-php-ext-pdo-pgsql` for PDO Postgres

#### Xdebug

Since [Xdebug](https://xdebug.org) is a common extension to be used we offer two options:

##### Dev image

Use the `dev` image by appending `-dev` to the end of the tag, like: `token27/php-phalcon:7.3-fpm-alpine3.11-dev`.

Not recommended if you're layering with your production images, using a different base image doesn't allow to you share
cache among your Dockerfile targets.

We ship the image with a dev mode helper, which can install and configure Xdebug, as well as override the production
`php.ini` with the recommended development version.

##### Setting up Xdebug

| Directive                 | Environment Variable            | Default                  |
|---------------------------|---------------------------------|--------------------------|
| xdebug.mode               | XDEBUG_MODE                     | develop, debug, coverage |
| xdebug.idekey             | XDEDUG_IDEKEY                   | PHPSTORM                 |
| xdebug.client_host        | XDEBUG_REMOTE_HOST              | host.docker.internal     |
| xdebug.client_port        | XDEBUG_REMOTE_PORT              | 9003                     |
| xdebug.start_with_request | XDEBUG_START_WITH_REQUEST       | yes                      |
| xdebug.log                | XDEBUG_LOG_FILE                 | /var/log/php/xdebug.log  |
| xdebug.log_level          | XDEBUG_LOG_LEVEL                | 10                       |

```Dockerfile
# syntax=docker/dockerfile:1.0.0-experimental

FROM token27/php-phalcon:fpm-7.2-phalcon-3.4.5
ENV XDEBUG_MODE="develop, debug, coverage"
ENV XDEDUG_IDEKEY="PHPSTORM"
ENV XDEBUG_REMOTE_HOST=host.docker.internal
ENV XDEBUG_REMOTE_PORT="9003"
ENV XDEBUG_START_WITH_REQUEST="yes"
ENV XDEBUG_LOG_FILE="/var/log/php/xdebug.log"
ENV XDEBUG_LOG_LEVEL="10"
```

```console
$ docker-php-dev-mode xdebug
```

As mentioned, we override the production `php.ini` with the recommended development version, which can be found
[here](https://github.com/php/php-src/blob/master/php.ini-development).

Next to that we provide some additional configuration to make it easier to start your debugging session. The contents of
that configuration can be found [here](src/php/conf/available/xdebug.conf.template).

Both are enabled via the helper script, by running

```console
$ docker-php-dev-mode config
```

Xdebug 3 comes with new mechanism to enable it's functionalities. The most notable, is the introduction of the
`xdebug.mode` setting, which controls which features are enabled. It can be specified via `.ini` files or by using the
environment variable `XDEBUG_MODE`. To learn more about the different modes in which Xdebug can be configured, please
refer to the [Xdebug settings guide](https://xdebug.org/docs/all_settings#mode).

##### Notable changes from Xdebug 2

With the introduction of the Xdebug mode in the v3 release, it is now mandatory to specify either `xdebug.mode=coverage`
setting in .ini file, or `XDEBUG_MODE=coverage` as environment variable, to use the code coverage analysis features.
This impacts tools like mutation tests.

We recommend setting the XDEBUG_MODE when booting up a new container. Here's an example on how it could look like:

```shell
docker run -it \
  -e XDEBUG_MODE=coverage \
  -v "<HOST_PATH>:<CONTAINER_PATH>" \
  token27/php-phalcon:7.2-cli-phalcon-3.4.5-dev \
  vendor/bin/infection --test-framework-options='--testsuite=unit' -s --threads=12 --min-msi=100 --min-covered-msi=100
```

Another notable change, is the Xdebug port change. The default port is now `9003` instead of `9000`. Check your IDE
settings to confirm the correct port is specified.

For the full upgrade guide, please refer to the [official upgrade guide](https://xdebug.org/docs/upgrade_guide).