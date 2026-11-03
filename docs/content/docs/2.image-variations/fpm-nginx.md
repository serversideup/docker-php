---
title: FPM-NGINX
description: 'Run NGINX and PHP-FPM together in one container with the fpm-nginx variation.'
---

::lead-p
The `fpm-nginx` variation runs NGINX and PHP-FPM in one container, supervised by S6 Overlay. Choose it for Laravel and other PHP apps that run on PHP-FPM when you want the web server included and don't need Apache's `.htaccess` files or FrankenPHP's worker mode. [Compare every variation →](/docs/getting-started/choosing-an-image)
::

## At a glance

| | `fpm-nginx` |
|---|---|
| Processes | NGINX and PHP-FPM, supervised by S6 Overlay |
| Ports | `8080` (HTTP), `8443` (HTTPS) |
| Stop signal | `SIGQUIT` |
| Default health check | `curl` to `http://localhost:${NGINX_HTTP_PORT}${HEALTHCHECK_PATH}` (`/healthcheck` by default) |
| Webroot variable | `NGINX_WEBROOT` (default `/var/www/html/public`) |
| PHP versions | 8.1 to 8.5, plus the 8.6 release candidate |
| Operating systems | Debian and Alpine |

## How a request flows through NGINX and PHP-FPM

1. NGINX receives the request on `8080` or `8443`.
2. If the path matches a file in the webroot, such as a CSS file or image, NGINX serves it directly.
3. Any other path is rewritten to `/index.php`, and NGINX passes `.php` requests to PHP-FPM over FastCGI on `127.0.0.1:9000`.
4. PHP-FPM runs the script and returns the response through NGINX.

S6 Overlay starts PHP-FPM before NGINX and restarts either one if it exits. PHP-FPM answers the `/healthcheck` route. The default health check fails if either process is down.

## Quick start
Put your app's public files in `public/`, which is the default webroot:

::code-tree{defaultValue="compose.yml"}

```yaml [compose.yml]
services:
  php:
    image: serversideup/php:8.5-fpm-nginx
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

Run `docker compose up` and open `http://localhost`. Mounting your code like this is for development. In production, copy the code into your own image instead; see [packaging your app for deployment](/docs/deployment-and-production/packaging-your-app-for-deployment).

## Configuration
These variables are specific to this variation. Defaults and the full list, including every `PHP_*` and `PHP_FPM_*` option, are in the [environment variable specification](/docs/reference/environment-variable-specification).

| To change | Set |
|---|---|
| Document root | `NGINX_WEBROOT` |
| Maximum upload or request size | `NGINX_CLIENT_MAX_BODY_SIZE`, plus `PHP_UPLOAD_MAX_FILE_SIZE` and `PHP_POST_MAX_SIZE` |
| FastCGI response buffers | `NGINX_FASTCGI_BUFFERS`, `NGINX_FASTCGI_BUFFER_SIZE` |
| Log destinations | `NGINX_ACCESS_LOG`, `NGINX_ERROR_LOG` |
| Listening ports | `NGINX_HTTP_PORT`, `NGINX_HTTPS_PORT` |
| IPv4 only or IPv6 only | `NGINX_LISTEN_IP_PROTOCOL` |
| NGINX version in response headers | `NGINX_SERVER_TOKENS` |

## Custom NGINX rules go in `server-opts.d`
The default site sends missing paths to `/index.php` and adds security headers. It blocks dotfiles (except `/.well-known/`) and PHP files under `/storage/`. Static assets get a one-year cache and gzip is on. To add your own rules, put a `.conf` file in the folder for the level where the rules belong:

| Folder | Included inside | Use it for |
|---|---|---|
| `/etc/nginx/server-opts.d/` | Each `server {}` block that serves your app | `location` blocks, redirects, `add_header` |
| `/etc/nginx/conf.d/` | The `http {}` block | `limit_req_zone`, `map`, or a whole extra `server {}` |

A `location` block in `conf.d/` stops NGINX from starting with `"location" directive is not allowed here`. With `SSL_MODE=full`, the HTTP server only redirects. Rules in `server-opts.d/` then apply to HTTPS requests only.

The image already has `performance.conf` and `security.conf` in `server-opts.d/`. A file with the same name replaces the image's rules. Your files are used as written: environment variables such as `${NGINX_WEBROOT}` are not filled in.

### Example: rate limit an API and redirect an old URL
A rate limit needs two parts: the zone at `http` level and the limit inside a `location`.

::code-group

```nginx [rate-limit-zone.conf]
limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;
```

```nginx [api.conf]
location /api/ {
    limit_req zone=api burst=20 nodelay;
    try_files $uri /index.php?$query_string;
}

location = /old-pricing {
    return 301 /pricing;
}
```

::

Mount the files in development. For production, copy them into your image:

::code-group

```yaml [compose.yml]
services:
  php:
    image: serversideup/php:8.5-fpm-nginx
    ports:
      - "80:8080"
    volumes:
      - ./:/var/www/html
      - ./rate-limit-zone.conf:/etc/nginx/conf.d/rate-limit-zone.conf:ro
      - ./api.conf:/etc/nginx/server-opts.d/api.conf:ro
```

```dockerfile [Dockerfile]
FROM serversideup/php:8.5-fpm-nginx
COPY rate-limit-zone.conf /etc/nginx/conf.d/
COPY api.conf /etc/nginx/server-opts.d/
```

::

Requests to `/api/` over the limit get a `503`.

### Replace the whole site
To write the `server {}` blocks yourself, put your file at `/etc/nginx/conf.d/default.conf`. When that file exists at startup, the image uses it instead of its own site. You then own everything the default site does, including `SSL_MODE` handling and the `/healthcheck` location. Try `server-opts.d/` first.

## Health checks
The default health check works without configuration. Set `HEALTHCHECK_PATH=/up` to check Laravel's health route instead. [Health checks](/docs/deployment-and-production/health-checks) covers timing and orchestrators. [Laravel health checks](/docs/framework-guides/laravel/health-checks) covers `/up` and worker containers.

## SSL
`SSL_MODE=mixed` serves HTTP on `8080` and HTTPS on `8443`. `SSL_MODE=full` serves HTTPS on `8443` and redirects HTTP on `8080` to it. The image generates a self-signed certificate unless you provide one. See [configuring SSL](/docs/deployment-and-production/configuring-ssl).

## Related pages
- [Configuring trusted proxies](/docs/deployment-and-production/configuring-trusted-proxies)
- [Production performance tuning](/docs/deployment-and-production/production-performance-tuning)
- [Using S6 Overlay](/docs/customizing-the-image/using-s6-overlay)
- [Command reference](/docs/reference/command-reference)
