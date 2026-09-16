---
head.title: 'Laravel Octane with Docker - Docker PHP - Server Side Up'
description: 'Learn how to configure Laravel Octane with Docker.'
layout: docs
title: Octane
---

::lead-p
Laravel Octane supercharges your application's performance by keeping it loaded in memory and serving requests at incredible speeds. The FrankenPHP variation of our images provides native Octane support with worker mode built-in.
::

## What is Laravel Octane?

Laravel Octane boots your Laravel application once and keeps it in memory, then processes thousands of requests without reloading. This dramatically improves performance compared to traditional PHP execution.

**Traditional PHP:**
Bootstrap → Handle Request → Teardown → Repeat for every request

**With Octane:**
Bootstrap once → Handle unlimited requests

::tip
FrankenPHP is Laravel's recommended application server for Octane and is included natively in our images. No additional installation required.
::

## Quick Start
Let's use this example project to get started.

::warning{to="https://serversideup.net/open-source/spin/docs" target="_blank"}
This example assumes you already have a Laravel application installed. If you need help installing a new Laravel project with Docker, check out [Spin](https://serversideup.net/open-source/spin/docs){target="_blank"} for a simple way to get started.
::

### Classic Mode
By default, FrankenPHP runs in classic mode. Your compose file might look something like this:

```yml [compose.yml]
services:
  php:
    image: serversideup/php:8.5-frankenphp
    ports:
      - "80:8080"
    volumes:
      - .:/var/www/html/
```

We'll expand upon this classic mode file and modify it to run Laravel Octane (which uses FrankenPHP's worker mode).

### Install Laravel Octane

First, install Octane in your Laravel application and tell it to use FrankenPHP. These are the same steps from the [official Laravel documentation](https://laravel.com/docs/13.x/octane#installation){target="_blank"}:

```bash [Terminal]
docker compose run php composer require laravel/octane
docker compose run php php artisan octane:install --server=frankenphp
```

The install command publishes `config/octane.php`, sets `OCTANE_SERVER=frankenphp` in your `.env` file, and creates a PHP file in your `/public` directory. This is the script FrankenPHP keeps running in memory, and Octane needs it to work.

```php [public/frankenphp-worker.php]
<?php

// Set a default for the application base path and public path if they are missing...
$_SERVER['APP_BASE_PATH'] = $_ENV['APP_BASE_PATH'] ?? $_SERVER['APP_BASE_PATH'] ?? __DIR__.'/..';
$_SERVER['APP_PUBLIC_PATH'] = $_ENV['APP_PUBLIC_PATH'] ?? $_SERVER['APP_PUBLIC_PATH'] ?? __DIR__;

require __DIR__.'/../vendor/laravel/octane/bin/frankenphp-worker.php';

```

::note
`octane:install` also adds `frankenphp-worker.php` to your `.gitignore`. We recommend removing that line and committing the file, so it is present in every build of your image. If you leave it ignored, `octane:start` recreates the file when the container starts, but only if the `public` directory is writable.
::

### Configure Worker Mode
We now want to update the compose file to start Octane instead of FrankenPHP's classic mode.

```yml [compose.yml]{8-9}
services:
  php:
    image: serversideup/php:8.5-frankenphp
    ports:
      - "80:8080"
    volumes:
      - .:/var/www/html/
    # Start Octane in worker mode with our production-ready Caddyfile
    command: ["php", "artisan", "octane:start", "--server=frankenphp", "--port=8080", "--caddyfile=/etc/frankenphp/Caddyfile"]
```

The command does three things:
1. **`octane:start --server=frankenphp`** starts FrankenPHP in worker mode through Octane, exactly as the [official Laravel documentation](https://laravel.com/docs/13.x/octane#serving-your-application){target="_blank"} describes.
2. **`--port=8080`** matches `CADDY_HTTP_PORT`, which defaults to `8080`. Our Caddyfile listens on `CADDY_HTTP_PORT`, so if you change that variable, change `--port` to match. The port is written out because Docker's exec form (the JSON array syntax) [does not perform variable substitution](https://docs.docker.com/reference/dockerfile/#exec-form){target="_blank"}.
3. **`--caddyfile=/etc/frankenphp/Caddyfile`** tells Octane to use the Caddyfile that ships with this image instead of its own. Laravel documents this option under [Custom Caddyfile Configuration](https://laravel.com/docs/13.x/octane#frankenphp-caddyfile){target="_blank"}. Octane's own Caddyfile is a minimal configuration, so without this flag you lose our trusted proxy support, security headers, asset caching, SSL modes, health check endpoint, and most of the `CADDY_*` environment variables.

Octane sets `LARAVEL_OCTANE=1` in FrankenPHP's environment when it starts the server. Our Caddyfile detects this and switches on the settings Octane expects: the worker script, routing every request to `frankenphp-worker.php` instead of `index.php`, and the Caddy admin API that `octane:status` and `octane:reload` rely on. Everything else in the Caddyfile stays the same as classic mode, including logs on `stderr`, which is the only stream Octane relays.

::note
Octane always uses its own Caddyfile unless you pass `--caddyfile`. The [Octane Caddyfile](https://github.com/laravel/octane/blob/2.x/src/Commands/stubs/Caddyfile){target="_blank"} is a good reference for the variables Octane controls, but we recommend passing our Caddyfile so you get the same production hardening as classic mode.
::

### Testing Locally

Run your application locally to test Octane:

```bash [Terminal]
docker compose up
```

Your Laravel application will be available at `http://localhost` with Octane running in worker mode.

## Health Checks
The image's built-in health check keeps working in Octane mode, because our Caddyfile still serves the `/healthcheck` endpoint. No changes are required.

If you would rather use Octane's own status check, the image also ships a `healthcheck-octane` command. It runs [`php artisan octane:status`](https://laravel.com/docs/13.x/octane#checking-the-server-status){target="_blank"}, which asks the Caddy admin API whether the server Octane started is still running:

```yml [compose.yml]
services:
  php:
    # ...
    healthcheck:
      test: ["CMD", "healthcheck-octane"]
      start_period: 10s
```

## Logging
Octane relays FrankenPHP's log output to your console, but it only reads `stderr` and it only understands JSON. Our Caddyfile satisfies both without any settings. The FrankenPHP variation writes to `stderr` by default, which is [Caddy's default](https://caddyserver.com/docs/caddyfile/directives/log#output){target="_blank"}, and Caddy [writes JSON whenever `stderr` is not a terminal](https://caddyserver.com/docs/caddyfile/directives/log#format){target="_blank"}, which is always the case when Octane starts FrankenPHP. Read more about [how we approach logging](/docs/getting-started/default-configurations#logging).

::warning
Leave `CADDY_LOG_OUTPUT` and `CADDY_LOG_FORMAT` at their defaults when you run Octane. With `CADDY_LOG_OUTPUT=stdout`, Octane discards the output and your logs disappear. With `CADDY_LOG_FORMAT=console`, Octane cannot parse the lines and wraps each one in an `INFO` message, including Caddy's warnings and errors.
::

Here is what you will see:
- In the `local` environment, Octane prints one line per request with the method, path, status code, and duration. This is the same output you get with Octane's own Caddyfile.
- In every other environment, Octane prints Caddy's warnings and errors and drops the request lines.
- With `--log-level`, Octane passes Caddy's JSON through untouched. Laravel [documents this option](https://laravel.com/docs/13.x/octane#frankenphp-via-docker){target="_blank"} as the switch to FrankenPHP's native logger that "will produce structured JSON logs", and that is exactly what you get.

Octane also decides the log level. It sets `CADDY_SERVER_LOG_LEVEL` to `INFO` when `APP_ENV` is `local` and to `WARN` everywhere else, which takes precedence over `LOG_OUTPUT_LEVEL`. Caddy [writes request logs at the `INFO` level](https://caddyserver.com/docs/caddyfile/directives/log#level){target="_blank"}, so at `WARN` successful requests no longer appear in your logs.

::note
If you want request logs in production, pass `--log-level=INFO` to `octane:start`. You get one JSON object per request on `stderr`, ready for your log collector.
::

The request log redacts the `authorization` query parameter, so the JWT that [Mercure subscribers pass in the URL](https://mercure.rocks/spec#authorization){target="_blank"} never lands in your logs. This is the same filter that [FrankenPHP's own Caddyfile](https://github.com/php/frankenphp/blob/main/caddy/frankenphp/Caddyfile){target="_blank"} recommends.

## PHP Settings Still Apply
Octane does not change how PHP loads its configuration. FrankenPHP reads the same `php.ini` files from `/usr/local/etc/php/conf.d/` in every mode, so all of the `PHP_*` environment variables (like `PHP_MEMORY_LIMIT` and `PHP_OPCACHE_ENABLE`) work exactly as they do in classic mode. Any custom `.ini` files you mount into that directory apply as well.

::tip
Enable OPcache with `PHP_OPCACHE_ENABLE=1` when you run Octane in production. See [Changing common PHP settings](/docs/customizing-the-image/changing-common-php-settings) for the full list of options.
::

## Octane Options
Octane passes its command line options to FrankenPHP through environment variables. Here is how they behave with our Caddyfile:

| Option | Behavior with our Caddyfile |
|--------|-----------------------------|
| `--port` | Keep this the same as `CADDY_HTTP_PORT` (default `8080`). Our Caddyfile listens on `CADDY_HTTP_PORT`. Octane also derives its admin port from this value, so `--port=8080` puts the admin API on port `2099`. |
| `--host` | Not used. The container listens on all interfaces, like classic mode. |
| `--workers` | Works. Sets the number of PHP threads FrankenPHP starts for the Octane worker. Leave it out and FrankenPHP [defaults to twice the number of CPUs](https://frankenphp.dev/docs/config/#caddyfile-config){target="_blank"}. |
| `--max-requests` | Works. The worker exits after this many requests and FrankenPHP starts a fresh one, which [limits the impact of memory leaks](https://laravel.com/docs/13.x/octane#specifying-the-max-request-count){target="_blank"}. Defaults to `500`. |
| `--watch` | Works. Passes the `watch` paths from `config/octane.php` to [FrankenPHP's file watcher](https://frankenphp.dev/docs/config/#watching-for-file-changes){target="_blank"}, which is built into our image. Node and Chokidar are not needed. `--poll` has no effect with FrankenPHP. |
| `--admin-port` | Works. `octane:status`, `octane:reload`, and `octane:stop` use this port, and `CADDY_ADMIN` is ignored. The admin API only listens on `localhost` inside the container. |
| `--admin-host` | Not available on `octane:start`, which always binds the admin API to `localhost`. The hidden `octane:frankenphp` command accepts it, but leave it alone. The [admin API has no authentication](https://caddyserver.com/docs/api){target="_blank"} and can reconfigure the web server, so binding it to `0.0.0.0` hands that control to anything that can reach the container. The image also lists port `2019` in `EXPOSE`, so `docker run -P` would publish it to the host. |
| `--log-level` | Works. This sets `CADDY_SERVER_LOG_LEVEL`, which takes precedence over `LOG_OUTPUT_LEVEL`, and switches Octane to relaying Caddy's JSON lines untouched. See [Logging](#logging). |
| `--https` and `--http-redirect` | Not used. Configure HTTPS with `SSL_MODE` and `CADDY_AUTO_HTTPS` instead, the same as classic mode. See [Automatic HTTPS](/docs/image-variations/frankenphp#automatic-https). |

The `max_execution_time` setting in `config/octane.php` works as [documented by Laravel](https://laravel.com/docs/13.x/octane#specifying-the-max-execution-time){target="_blank"}, because Octane passes it to the worker script rather than to the Caddyfile.

Octane also sets `CADDY_GLOBAL_OPTIONS` and `CADDY_SERVER_EXTRA_DIRECTIVES` for its own use, so any value you set for those variables is replaced when Octane starts FrankenPHP:
- `CADDY_SERVER_EXTRA_DIRECTIVES` carries the Mercure settings from `config/octane.php`, so Mercure works as [documented by FrankenPHP](https://frankenphp.dev/docs/laravel/#mercure-support){target="_blank"}.
- `CADDY_GLOBAL_OPTIONS` is not applied in Octane mode, because Octane sets it to `auto_https disable_redirects`, which would conflict with `CADDY_AUTO_HTTPS`. If you need additional global options, mount a `.caddyfile` into `/etc/frankenphp/caddyfile-global.d/`.

Octane's own Caddyfile asks for JSON logs through `CADDY_SERVER_LOGGER`. Our Caddyfile does not read that variable, because Caddy already writes JSON when Octane starts it. See [Logging](#logging).

::tip
Octane 2.14 and newer let you override any of the variables Octane sets through the `caddy.env` option in `config/octane.php`. For example, this enables request logs in every environment without passing `--log-level`:

```php [config/octane.php]
'caddy' => [
    'env' => [
        'CADDY_SERVER_LOG_LEVEL' => 'INFO',
    ],
],
```

See the [Octane 2.14.0 release notes](https://github.com/laravel/octane/releases/tag/v2.14.0){target="_blank"} for details.
::

Octane sets `APP_PUBLIC_PATH` to your application's public directory, but our Caddyfile looks for `frankenphp-worker.php` in `CADDY_SERVER_ROOT` instead. This keeps the worker script and the document root in the same place. If you changed `APP_BASE_DIR`, set `CADDY_SERVER_ROOT` to match, just like classic mode.

## Things to Watch Out For
Since Octane is a whole different way of running Laravel compared to traditional PHP-FPM, there are a few things to watch out for.

### Dependency Injection
Be careful with how you inject dependencies into long-lived objects. Injecting the wrong things into constructors can cause requests to "leak" between users. Review Laravel's [Dependency Injection and Octane](https://laravel.com/docs/13.x/octane#dependency-injection-and-octane){target="_blank"} documentation for details.

### Memory Leaks
Review Laravel's [Octane documentation on memory leaks](https://laravel.com/docs/13.x/octane#managing-memory-leaks){target="_blank"} to understand what to avoid.

### Reloading After Deployments
Octane keeps your code in memory, so a deployment needs [`php artisan octane:reload`](https://laravel.com/docs/13.x/octane#reloading-the-workers){target="_blank"} to pick up new code. In a container this usually means replacing the container instead. If you do reload in place, our Caddyfile exposes the admin API Octane needs, so `octane:reload` works as expected.

## Learn More
- [FrankenPHP Variation Documentation](/docs/image-variations/frankenphp)
- [Laravel Octane Documentation](https://laravel.com/docs/13.x/octane)
- [FrankenPHP Documentation](https://frankenphp.dev/docs/)
