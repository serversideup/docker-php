---
title: FPM
description: 'Run PHP-FPM on its own behind a web server or proxy you manage.'
---

::lead-p
The `fpm` variation runs PHP-FPM alone and answers FastCGI requests on port `9000`, so you bring the web server. Choose it when you already run NGINX, Caddy, or another FastCGI-capable server, or want to scale PHP separately from it. If you want the web server in the same container, use [`fpm-nginx`](/docs/image-variations/fpm-nginx), [`fpm-apache`](/docs/image-variations/fpm-apache), or [`frankenphp`](/docs/image-variations/frankenphp). [Compare every variation →](/docs/getting-started/choosing-an-image)
::

## At a glance

| | `fpm` |
|---|---|
| Processes | `php-fpm` only. No S6 Overlay; the FPM master manages its own workers. |
| Ports | `9000` (FastCGI, not HTTP) |
| Stop signal | `SIGQUIT` (FPM finishes in-flight requests, then exits) |
| Default health check | [`php-fpm-healthcheck`](https://github.com/renatomefi/php-fpm-healthcheck){target="_blank"}, which reads FPM's status page |
| Webroot variable | None. Your web server sets the document root. |
| PHP versions | 8.1 to 8.5, plus the 8.6 release candidate |
| Operating systems | Debian and Alpine |

## Quick start
This Compose file runs PHP-FPM and the official NGINX image side by side. Both mount the same code, because NGINX serves static files itself and passes only PHP requests to FPM.

::code-tree{defaultValue="compose.yml"}

```yaml [compose.yml]
services:
  php:
    image: serversideup/php:8.5-fpm
    volumes:
      - ./:/var/www/html

  nginx:
    image: nginx:1.30-alpine
    ports:
      - "80:80"
    volumes:
      - ./:/var/www/html
      - ./nginx.conf:/etc/nginx/conf.d/default.conf:ro
    depends_on:
      - php
```

```nginx [nginx.conf]
server {
    listen 80;
    root /var/www/html/public;
    index index.php index.html;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location ~ \.php$ {
        fastcgi_pass php:9000;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }
}
```

```php [public/index.php]
<?php
phpinfo();
```

::

`fastcgi_pass php:9000` uses the Compose service name as the host name. The file path in `SCRIPT_FILENAME` is resolved inside the PHP container, so mount the code at the same path in both containers.

## Health check
The image's health check runs `php-fpm-healthcheck`, which passes when FPM's status page answers. Add options to fail on load as well, such as `--listen-queue=10` to fail when more than 10 requests are waiting:

```yaml [compose.yml]
services:
  php:
    image: serversideup/php:8.5-fpm
    healthcheck:
      test: ["CMD", "php-fpm-healthcheck", "--listen-queue=10"]
```

For Laravel queue, Horizon, and scheduler health checks, see [Laravel health checks](/docs/framework-guides/laravel/health-checks).

## Configuration
Set PHP and PHP-FPM options with `PHP_*` and `PHP_FPM_*` environment variables. All of them, with defaults, are in the [environment variable specification](/docs/reference/environment-variable-specification). To size the FPM process pool for your server, see [production performance tuning](/docs/deployment-and-production/production-performance-tuning).

## Related pages
- [Choosing an image](/docs/getting-started/choosing-an-image)
- [Packaging your app for deployment](/docs/deployment-and-production/packaging-your-app-for-deployment)
- [Command reference](/docs/reference/command-reference)
