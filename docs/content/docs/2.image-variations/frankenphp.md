---
title: FrankenPHP
description: 'Run PHP inside the Caddy web server, with optional worker mode and automatic HTTPS, using the frankenphp variation.'
---

::lead-p
The `frankenphp` variation runs [FrankenPHP](https://frankenphp.dev){target="_blank"}, an application server built on Caddy that runs PHP inside the web server process, with no PHP-FPM. Choose it for Laravel Octane and other worker-mode apps. It also gets Let's Encrypt certificates without a reverse proxy and serves HTTP/3. [Compare every variation →](/docs/getting-started/choosing-an-image)
::

## At a glance

| | `frankenphp` |
|---|---|
| Processes | One `frankenphp` process (Caddy with PHP built in). No supervisor. |
| Ports | `8080` (HTTP), `8443` (HTTPS over TCP, and HTTP/3 over UDP), `2019` (Caddy admin API, off unless `CADDY_ADMIN` sets it or Octane starts the server) |
| Stop signal | `SIGTERM` |
| Default health check | `curl` to `http://localhost:${CADDY_HTTP_PORT}${HEALTHCHECK_PATH}` (`/healthcheck` by default) |
| Webroot variable | `CADDY_SERVER_ROOT` (default `/var/www/html/public`) |
| PHP versions | 8.3 to 8.5, plus the 8.6 release candidate. Not built for 8.1 or 8.2. |
| Operating systems | Debian and Alpine |

The image also includes a [Mercure](#mercure) hub, turned off by default.

::warning{to="https://frankenphp.dev/docs/known-issues/" target="_blank"}
Read FrankenPHP's known issues before you run it in production. They include slower performance on Alpine images. Use the Debian image unless you need Alpine.
::

## Classic mode and worker mode
FrankenPHP starts in classic mode. Every request boots your app from scratch, as it would under PHP-FPM. Existing PHP apps run unchanged.

In worker mode, your app boots once and stays in memory between requests. The app must be written for it, because state left over from one request is still there for the next. For Laravel, run Octane with this image's Caddyfile; see [Laravel Octane](/docs/framework-guides/laravel/octane). For other frameworks, configure workers with `FRANKENPHP_CONFIG` as described in [FrankenPHP's worker docs](https://frankenphp.dev/docs/worker/){target="_blank"}.

## Quick start
Put your app's public files in `public/`, which is the default webroot:

::code-tree{defaultValue="compose.yml"}

```yaml [compose.yml]
services:
  php:
    image: serversideup/php:8.5-frankenphp
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
These variables are specific to this variation. Defaults and the full list, including every `PHP_*` option, are in the [environment variable specification](/docs/reference/environment-variable-specification).

| To change | Set |
|---|---|
| Document root | `CADDY_SERVER_ROOT` |
| Listening ports | `CADDY_HTTP_PORT`, `CADDY_HTTPS_PORT` |
| Let's Encrypt certificates | `CADDY_AUTO_HTTPS`, `CADDY_HTTPS_SERVER_ADDRESS`, `CADDY_ACME_PROFILE` |
| Log format and destination | `CADDY_LOG_FORMAT`, `CADDY_LOG_OUTPUT` |
| Caddy admin API | `CADDY_ADMIN` |
| FrankenPHP and `php_server` options | `FRANKENPHP_CONFIG`, `CADDY_PHP_SERVER_OPTIONS` |
| Raw Caddyfile rules | `CADDY_GLOBAL_OPTIONS`, `CADDY_SERVER_EXTRA_DIRECTIVES`, or the folders in [Adding your own Caddyfile rules](#adding-your-own-caddyfile-rules) |
| Mercure hub | `MERCURE_*`, see [Mercure](#mercure) |

## Adding your own Caddyfile rules
When the variables above don't cover a rule, add raw Caddyfile config at the level where it belongs. Every `.caddyfile` file in a folder is imported at that level:

| Level | What goes here | Variable | Folder |
|-------|----------------|----------|--------|
| Global | [Global options](https://caddyserver.com/docs/caddyfile/options){target="_blank"}, including Caddy's `servers` option | `CADDY_GLOBAL_OPTIONS` | `/etc/frankenphp/caddyfile-global.d/` |
| Server | [Directives](https://caddyserver.com/docs/caddyfile/directives){target="_blank"} for your app, such as `header`, `redir`, and request matchers | `CADDY_SERVER_EXTRA_DIRECTIVES` | `/etc/frankenphp/caddyfile-server.d/` |
| New sites | Extra site blocks, such as a second domain or a reverse proxy | None | `/etc/frankenphp/caddyfile.d/` |

Use a variable for a one-liner and a folder for anything longer. Only the folders work with [Laravel Octane](/docs/framework-guides/laravel/octane), which replaces `CADDY_GLOBAL_OPTIONS` and `CADDY_SERVER_EXTRA_DIRECTIVES` with its own values.

This is where each one lands in `/etc/frankenphp/Caddyfile`:

```txt [/etc/frankenphp/Caddyfile]
{
    frankenphp {
        FRANKENPHP_CONFIG
    }
    caddyfile-global.d/*.caddyfile
    CADDY_GLOBAL_OPTIONS
}

your app's site (one per listener that SSL_MODE creates) {
    php_server {
        CADDY_PHP_SERVER_OPTIONS
    }
    CADDY_SERVER_EXTRA_DIRECTIVES
    caddyfile-server.d/*.caddyfile
}

caddyfile.d/*.caddyfile
```

### Add rules to your app
Put directives for your app in `caddyfile-server.d/`. This example gives one JavaScript file a one-hour cache instead of the one-year cache the image sets for static assets:

```caddyfile [embed-cache.caddyfile]
@embed path /embed.js
header @embed >Cache-Control "public, max-age=3600"
```

Mount the file in development. For production, copy it into your image:

::code-group
```yaml [compose.yml]
services:
  php:
    image: serversideup/php:8.5-frankenphp
    volumes:
      - ./embed-cache.caddyfile:/etc/frankenphp/caddyfile-server.d/embed-cache.caddyfile
```

```dockerfile [Dockerfile]
FROM serversideup/php:8.5-frankenphp
COPY embed-cache.caddyfile /etc/frankenphp/caddyfile-server.d/
```
::

Rules in `caddyfile-server.d/` apply on every listener `SSL_MODE` creates. With `SSL_MODE=mixed` that includes plain HTTP. Match on `protocol https` for rules that belong only on HTTPS.

::warning
Docker's health check goes through your app's site too. Leave the health check path out of any rule that matches every request, such as `basic_auth` or `redir`, or the container is marked unhealthy:

```caddyfile [basic-auth.caddyfile]
@protected not path /healthcheck {$HEALTHCHECK_PATH:/healthcheck}
basic_auth @protected {
    admin $2a$14$KbVXTcgF3ZrK76FfvPLFj.kXOV/PH5pkAk.o53ct8bGdsl6yai9eC
}
```

Generate the password hash with `docker run --rm -it serversideup/php:8.5-frankenphp frankenphp hash-password`.
::

### Add another site
Files in `caddyfile.d/` sit at the top level of the Caddyfile, outside your app's site. Use them for a whole new site block:

```caddyfile [docs-proxy.caddyfile]
http://docs.example.com:{$CADDY_HTTP_PORT:8080} {
    reverse_proxy docs:3000
}
```

Rules for your app fail here with "request matchers may not be defined globally". Put those in `caddyfile-server.d/`.

### Replace the whole Caddyfile
Copy your own file over `/etc/frankenphp/Caddyfile` only if the folders can't do what you need. You then own everything the image's Caddyfile does, including SSL modes, security headers, and the health check endpoint.

## Automatic HTTPS
FrankenPHP can get and renew a Let's Encrypt certificate itself. Set `CADDY_AUTO_HTTPS=on` and `SSL_MODE=full`, and put your domain (such as `example.com`) in `CADDY_HTTPS_SERVER_ADDRESS`. The server must be reachable from the internet on ports 80 and 443. See [configuring SSL](/docs/deployment-and-production/configuring-ssl) for the full Compose file and the volumes that keep certificates across deployments.

Without automatic HTTPS, `SSL_MODE=mixed` serves HTTP on `8080` and HTTPS on `8443`. `SSL_MODE=full` serves HTTPS on `8443` and redirects HTTP on `8080` to it. Both use a self-signed certificate unless you provide one.

## Health checks
The default health check works without configuration. Set `HEALTHCHECK_PATH=/up` to check Laravel's health route instead. [Health checks](/docs/deployment-and-production/health-checks) covers timing and orchestrators. [Laravel health checks](/docs/framework-guides/laravel/health-checks) covers `/up` and worker containers.

## Logging
- Caddy writes request logs and errors to `stderr`, as JSON when no terminal is attached (Compose, Swarm, Kubernetes) and as readable console lines with `docker run -it`. Set `CADDY_LOG_FORMAT` to `json` or `console` to use one format everywhere. Under Laravel Octane, leave `CADDY_LOG_FORMAT` and `CADDY_LOG_OUTPUT` at their defaults, because Octane only reads JSON on `stderr`.
- `LOG_OUTPUT_LEVEL` defaults to `info` in this variation, so request logs are included. Set it to `warn` to log problems only.

See [default configurations](/docs/getting-started/default-configurations) for how logging differs across variations.

## Mercure
[Mercure](https://mercure.rocks){target="_blank"} pushes real-time updates from your app to the browser. FrankenPHP has a Mercure hub built in. Turn it on with environment variables. The hub answers at `/.well-known/mercure` on the same ports as your app, in classic mode and with Laravel Octane.

```yaml [compose.yml]
services:
  php:
    image: serversideup/php:8.5-frankenphp
    ports:
      - "80:8080"
    volumes:
      - ./:/var/www/html
    environment:
      MERCURE_ENABLED: "true"
      MERCURE_TRUSTED_ISSUERS: "https://example.com"
      MERCURE_PUBLISHER_JWT_KEY: "${MERCURE_JWT_SECRET}"
      MERCURE_SUBSCRIBER_JWT_KEY: "${MERCURE_JWT_SECRET}"
```

Docker Compose reads `MERCURE_JWT_SECRET` from your `.env` file. Generate one with `openssl rand -base64 32`. The hub only accepts subscribers with a valid token; to allow anonymous subscribers or set CORS origins, add [Mercure directives](https://mercure.rocks/docs/deployment/configuration){target="_blank"} with `MERCURE_EXTRA_DIRECTIVES`:

```yaml [compose.yml]
    environment:
      MERCURE_EXTRA_DIRECTIVES: |
        anonymous
        cors_origins https://example.com
```

::note
FrankenPHP 1.13 includes Mercure 1.0, which expects [OAuth 2.0 access tokens](https://github.com/dunglas/mercure/blob/v1.0.3/docs/UPGRADE.md#migrate-your-tokens){target="_blank"} with `iss`, `aud`, and `exp` claims. If your app still signs Mercure 0.x tokens, set `MERCURE_EXTRA_DIRECTIVES: "protocol_version_compatibility 8"` while you migrate, then remove it, because it relaxes token checks.
::

The other `MERCURE_*` variables, such as the JWT algorithms, are in the [environment variable specification](/docs/reference/environment-variable-specification).

## Related pages
- [Laravel Octane](/docs/framework-guides/laravel/octane)
- [Configuring SSL](/docs/deployment-and-production/configuring-ssl)
- [Configuring trusted proxies](/docs/deployment-and-production/configuring-trusted-proxies)
- [FrankenPHP documentation](https://frankenphp.dev/docs/){target="_blank"} and [Caddy documentation](https://caddyserver.com/docs/){target="_blank"}
