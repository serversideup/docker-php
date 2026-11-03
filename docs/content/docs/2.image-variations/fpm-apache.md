---
title: FPM-Apache
description: 'Run Apache and PHP-FPM together in one container with the fpm-apache variation.'
---

::lead-p
The `fpm-apache` variation runs Apache and PHP-FPM in one container, supervised by S6 Overlay. Choose it when your app depends on `.htaccess` files or Apache modules, as WordPress and many older PHP apps do. [Compare every variation →](/docs/getting-started/choosing-an-image)
::

## At a glance

| | `fpm-apache` |
|---|---|
| Processes | Apache (event MPM) and PHP-FPM, supervised by S6 Overlay |
| Ports | `8080` (HTTP), `8443` (HTTPS) |
| Stop signal | `SIGQUIT` |
| Default health check | `curl` to `http://localhost:${APACHE_HTTP_PORT}${HEALTHCHECK_PATH}` (`/healthcheck` by default) |
| Webroot variable | `APACHE_DOCUMENT_ROOT` (default `/var/www/html/public`) |
| PHP versions | 8.1 to 8.5, plus the 8.6 release candidate |
| Operating systems | Debian only. There is no Alpine build. |

Requests flow the same way as in [`fpm-nginx`](/docs/image-variations/fpm-nginx#how-a-request-flows-through-nginx-and-php-fpm), with Apache in place of NGINX. One difference: Apache has no built-in rule that sends unknown paths to `index.php`. Your app's `.htaccess` does that, such as the one Laravel ships in `public/.htaccess`. Without it, routes other than real files return `404`.

## Quick start
Put your app's public files in `public/`, which is the default document root:

::code-tree{defaultValue="compose.yml"}

```yaml [compose.yml]
services:
  php:
    image: serversideup/php:8.5-fpm-apache
    ports:
      - "80:8080"
    volumes:
      - ./:/var/www/html
```

```php [public/index.php]
<?php
phpinfo();
```

::

Run `docker compose up` and open `http://localhost`. Mounting your code like this is for development. In production, copy the code into your own image instead; see [packaging your app for deployment](/docs/deployment-and-production/packaging-your-app-for-deployment). For a WordPress setup with a database, see [using WordPress with Docker](/docs/framework-guides/wordpress/using-wordpress-with-docker).

## Configuration
These variables are specific to this variation. Defaults and the full list, including every `PHP_*` and `PHP_FPM_*` option, are in the [environment variable specification](/docs/reference/environment-variable-specification).

| To change | Set |
|---|---|
| Document root | `APACHE_DOCUMENT_ROOT` |
| Listening ports | `APACHE_HTTP_PORT`, `APACHE_HTTPS_PORT` |
| Apache worker threads | `APACHE_START_SERVERS`, `APACHE_MIN_SPARE_THREADS`, `APACHE_MAX_SPARE_THREADS`, `APACHE_THREAD_LIMIT`, `APACHE_THREADS_PER_CHILD`, `APACHE_MAX_REQUEST_WORKERS`, `APACHE_MAX_CONNECTIONS_PER_CHILD` |
| Maximum upload size | `PHP_UPLOAD_MAX_FILE_SIZE` and `PHP_POST_MAX_SIZE` |

## Customize Apache
The default configuration adds security headers, hides the Apache version, turns off `TRACE`, blocks dotfiles (except `/.well-known/`), PHP files under `/storage/`, and WordPress's `xmlrpc.php`. You can add rules in two places.

### `.htaccess` for per-directory rules
`AllowOverride All` is set on the document root. Your `.htaccess` files work as they would on any Apache host and apply without a restart.

### `conf-enabled` for server-wide rules
Files in `/etc/apache2/conf-enabled/` ending in `.conf` load before the virtual hosts and apply to every site and port. This example redirects an old URL and limits `/admin` to a private network:

```apache [custom.conf]
Redirect permanent /old-pricing /pricing

<Location "/admin">
    Require ip 10.0.0.0/8
</Location>
```

::code-group

```yaml [compose.yml]
services:
  php:
    image: serversideup/php:8.5-fpm-apache
    ports:
      - "80:8080"
    volumes:
      - ./:/var/www/html
      - ./custom.conf:/etc/apache2/conf-enabled/custom.conf:ro
```

```dockerfile [Dockerfile]
FROM serversideup/php:8.5-fpm-apache
COPY custom.conf /etc/apache2/conf-enabled/
```

::

The image's own rules are in `conf-enabled/security.conf`, `remoteip.conf`, and `serversideup.conf`. A file with the same name replaces the image's file.

### Replace a site
Each `SSL_MODE` has its own virtual host file in `/etc/apache2/sites-available/`: `ssl-off.conf`, `ssl-mixed.conf`, and `ssl-full.conf`. Mount your own file over the one for your mode to replace it. You then own the health check route and the PHP handler. Start from a copy of the [image's files](https://github.com/serversideup/docker-php/tree/main/src/variations/fpm-apache/etc/apache2){target="_blank"}.

## Health checks
PHP-FPM answers the `/healthcheck` route. The default health check fails if either Apache or PHP-FPM is down. Set `HEALTHCHECK_PATH=/up` to check Laravel's health route instead. [Health checks](/docs/deployment-and-production/health-checks) covers timing and orchestrators. [Laravel health checks](/docs/framework-guides/laravel/health-checks) covers `/up` and worker containers.

## SSL
`SSL_MODE=mixed` serves HTTP on `8080` and HTTPS on `8443`. `SSL_MODE=full` serves HTTPS on `8443` and redirects HTTP on `8080` to it. The image generates a self-signed certificate unless you provide one. See [configuring SSL](/docs/deployment-and-production/configuring-ssl).

## Related pages
- [Using WordPress with Docker](/docs/framework-guides/wordpress/using-wordpress-with-docker)
- [Configuring trusted proxies](/docs/deployment-and-production/configuring-trusted-proxies)
- [Production performance tuning](/docs/deployment-and-production/production-performance-tuning)
- [Command reference](/docs/reference/command-reference)
