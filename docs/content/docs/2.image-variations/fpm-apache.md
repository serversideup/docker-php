---
title: FPM-Apache
description: 'Learn how to use the FPM-Apache variation of the serversideup/php image.'
---

::lead-p
The FPM-Apache variation combines PHP-FPM with Apache as a reverse proxy in a single container. Apache serves static content directly and forwards PHP requests to PHP-FPM for processing.

Use this variation when you need Apache-specific features, `.htaccess` support, or want an all-in-one solution for running PHP applications.
::

## When to Use FPM-Apache
Use the FPM-Apache variation when you need to:

- Run WordPress sites that rely on `.htaccess` configurations
- Use Apache-specific modules like `mod_rewrite` or `mod_security`
- Deploy applications that require `.htaccess` support
- Want an all-in-one container with both web server and PHP processing
- Need Apache's mature ecosystem and widespread documentation

#### Perfect for
- WordPress hosting with Docker
- Legacy PHP applications that depend on Apache
- Teams familiar with Apache configuration
- Applications requiring `.htaccess` support

#### What's Inside

| Item | Status |
|------|--------|
| Apache web server | ✅ |
| PHP-FPM process manager | ✅ |
| PHP CLI binary | ✅ |
| Common PHP extensions | ✅ |
| `composer` executable | ✅ |
| `install-php-extensions` script | ✅ |
| Essential system utilities | ✅ |
| S6 Overlay (process supervisor) | ✅ |
| Native health checks | ✅ (via HTTP endpoint) |
| `.htaccess` support | ✅ |
| SSL/TLS support | ✅ (self-signed certificates or bring your own) |
| Process management | S6 Overlay supervising both Apache and PHP-FPM |
| Exposed Ports | `8080` (HTTP), `8443` (HTTPS) |
| Stop Signal | `SIGQUIT` |

## How FPM-Apache Works
This variation runs both Apache and PHP-FPM in a single container, managed by S6 Overlay (for the most accurate process supervision). Here's how requests flow:

::steps{level="4"}

#### Client sends HTTP request
The container listens on port 8080 (or 8443 for HTTPS) for incoming HTTP requests.

#### Apache receives the request
Apache receives the request and determines if it's a static file or PHP script.

#### Check for static files
Static files (CSS, JavaScript, images) are served directly by Apache.

#### Forward PHP requests to PHP-FPM
PHP requests are forwarded to PHP-FPM via FastCGI protocol.

#### Process PHP requests with PHP-FPM
PHP-FPM processes the PHP script and returns the result to Apache.

#### Send the response back to the client
Apache sends the response back to the client.

::

S6 Overlay ensures both Apache and PHP-FPM are running and automatically restarts them if either process fails.

::note
If you don't specifically need Apache, consider using the [`fpm-nginx`](/docs/image-variations/fpm-nginx) or [`frankenphp`](/docs/image-variations/frankenphp) variations instead. They offer better performance for modern PHP applications.
::

## Quick Start
Here are a few examples to help you get started with the FPM-Apache variation.

### Docker CLI
```bash [Terminal]
docker run -p 80:8080 -v $(pwd):/var/www/html/public serversideup/php:8.4-fpm-apache
```

Your application will be available at `http://localhost`. The default document root is `/var/www/html/public`.

### Docker Compose
::warning
Notice how we're mapping the current directory to `/var/www/html/`, but the actual default document root is `/var/www/html/public`. We're assuming you're creating the `public` directory and putting your PHP code in there. It's not best practice to expose your `compose.yml` file. See the [Installation guide](/docs/getting-started/installation) for a full example.
::

This is the recommended approach for local development and production deployments.

```yml [compose.yml]
services:
  php:
    image: serversideup/php:8.4-fpm-apache
    ports:
      - "80:8080"
    volumes:
      - ./:/var/www/html
    environment:
      PHP_OPCACHE_ENABLE: "1"
```

::tip
The FPM-Apache variation uses ports 8080 and 8443 (instead of 80 and 443) to allow the container to run as a non-root user for better security.
::

### WordPress Example
The FPM-Apache variation is excellent for WordPress hosting:

```yml [compose.yml]
services:
  wordpress:
    image: serversideup/php:8.4-fpm-apache
    ports:
      - "8080:8080"
    volumes:
      - ./wordpress:/var/www/html/public
    environment:
      PHP_MEMORY_LIMIT: "512M"
      PHP_OPCACHE_ENABLE: "1"
    depends_on:
      - mariadb

  mariadb:
    image: mariadb:11
    environment:
      MYSQL_ROOT_PASSWORD: rootpassword
      MYSQL_DATABASE: wordpress
      MYSQL_USER: wordpress
      MYSQL_PASSWORD: wordpress
    volumes:
      - db_data:/var/lib/mysql

volumes:
  db_data:
```

### Health Check
The FPM-Apache variation includes a built-in health check that verifies Apache is responding:

::note
The health check endpoint is configurable via the `HEALTHCHECK_PATH` environment variable, which defaults to `/healthcheck`.
::

## SSL/TLS Support
The FPM-Apache variation includes built-in SSL support with self-signed certificates for development.

### Enabling SSL
```yml [compose.yml]
services:
  php:
    image: serversideup/php:8.4-fpm-apache
    ports:
      - "8080:8080"
      - "8443:8443"
    volumes:
      - ./:/var/www/html
    environment:
      SSL_MODE: "full"
```

Available SSL modes:
- `off` - SSL disabled (default)
- `mixed` - Both HTTP (8080) and HTTPS (8443) enabled
- `full` - HTTPS only on port 8443

### Custom SSL Certificates
For production, use your own SSL certificates:

```yml [compose.yml]
services:
  php:
    image: serversideup/php:8.4-fpm-apache
    ports:
      - "443:8443"
    volumes:
      - ./:/var/www/html
      - ./certs/server.crt:/etc/ssl/private/self-signed-web.crt:ro
      - ./certs/server.key:/etc/ssl/private/self-signed-web.key:ro
    environment:
      SSL_MODE: "full"
```

::warning
For production deployments, consider using a reverse proxy like Traefik or Caddy to handle SSL termination instead of managing certificates in the container.
::

## Environment Variables
The FPM-Apache variation supports extensive customization through environment variables.

### Apache Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `APACHE_DOCUMENT_ROOT` | `/var/www/html/public` | Document root for Apache |
| `APACHE_START_SERVERS` | `2` | Number of Apache server processes to start |
| `APACHE_MIN_SPARE_THREADS` | `10` | Minimum idle threads |
| `APACHE_MAX_SPARE_THREADS` | `75` | Maximum idle threads |
| `APACHE_THREADS_PER_CHILD` | `25` | Number of threads per child process |
| `APACHE_MAX_REQUEST_WORKERS` | `150` | Maximum simultaneous connections |
| `APACHE_MAX_CONNECTIONS_PER_CHILD` | `0` | Requests before child process restarts (0 = unlimited) |
| `SSL_MODE` | `off` | SSL mode: `off`, `mixed`, or `full` |
| `SSL_CERTIFICATE_FILE` | `/etc/ssl/private/self-signed-web.crt` | Path to SSL certificate |
| `SSL_PRIVATE_KEY_FILE` | `/etc/ssl/private/self-signed-web.key` | Path to SSL private key |
| `HEALTHCHECK_PATH` | `/healthcheck` | Path for health check endpoint |

::tip
For a complete list of available environment variables, see the [Environment Variable Specification →](/docs/reference/environment-variable-specification).
::

### PHP-FPM Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `PHP_FPM_POOL_NAME` | `www` | Name of the PHP-FPM pool |
| `PHP_FPM_PM_CONTROL` | `dynamic` | Process manager control (`dynamic`, `static`, `ondemand`) |
| `PHP_FPM_PM_MAX_CHILDREN` | `20` | Maximum number of child processes |
| `PHP_FPM_PM_START_SERVERS` | `2` | Number of child processes created on startup |
| `PHP_FPM_PM_MIN_SPARE_SERVERS` | `1` | Minimum number of idle processes |
| `PHP_FPM_PM_MAX_SPARE_SERVERS` | `3` | Maximum number of idle processes |
| `PHP_MEMORY_LIMIT` | `256M` | Maximum memory a script can use |
| `PHP_MAX_EXECUTION_TIME` | `99` | Maximum time a script can run (seconds) |
| `PHP_UPLOAD_MAX_FILE_SIZE` | `100M` | Maximum upload file size |
| `PHP_POST_MAX_SIZE` | `100M` | Maximum POST request size |

::tip
For a complete list of available environment variables, see the [Environment Variable Specification →](/docs/reference/environment-variable-specification).
::

## Further Customization
If you need to customize the container further, reference the docs below:

- [Environment Variable Specification](/docs/reference/environment-variable-specification) - See which environment variables are available to customize PHP and Apache settings.
- [Command Reference](/docs/reference/command-reference) - See which commands are available to run inside the container.

