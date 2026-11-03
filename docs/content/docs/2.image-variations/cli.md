---
title: CLI
description: 'Run PHP and Composer from the command line with the cli variation, which has no web server.'
---

::lead-p
The `cli` variation runs PHP from the command line, with no web server and no process supervisor. Choose it for Composer, one-off scripts, running PHP without installing it on your machine, or [Laravel Octane on Swoole or RoadRunner](/docs/framework-guides/laravel/octane#run-octane-on-swoole-or-roadrunner). [Compare every variation →](/docs/getting-started/choosing-an-image)
::

## At a glance

| | `cli` |
|---|---|
| Processes | One: the command you pass. No supervisor. |
| Ports | None |
| Stop signal | `SIGTERM` |
| Default health check | None |
| Webroot variable | Not used |
| PHP versions | 8.1 to 8.5, plus the 8.6 release candidate |
| Operating systems | Debian and Alpine |

The image also includes `composer` and `install-php-extensions`. See [default configurations](/docs/getting-started/default-configurations) for the full list of extensions and settings.

## Quick start
Mount your project into `/var/www/html` and open a shell:

```bash [Terminal]
docker run --rm -it -v "$(pwd):/var/www/html" serversideup/php:8.5-cli bash
```

Or run one command and exit:

```bash [Terminal]
docker run --rm -v "$(pwd):/var/www/html" serversideup/php:8.5-cli composer install
```

Alpine images have no `bash`. Use `sh` with `serversideup/php:8.5-cli-alpine`.

### With Docker Compose
Define the service once:

```yaml [compose.yml]
services:
  php:
    image: serversideup/php:8.5-cli
    volumes:
      - ./:/var/www/html
```

Then run commands through it. The first `php` is the service name and the second is the command:

```bash [Terminal]
docker compose run --rm php php my-script.php
```

## Laravel workers and the scheduler
Queue workers, Horizon, and the scheduler usually run from the same image as your web app with a different command, so every container has the same code and extensions. See [Laravel workers](/docs/framework-guides/laravel/workers) for the commands and health checks.

## Related pages
- [Environment variable specification](/docs/reference/environment-variable-specification): every `PHP_*` setting
- [Command reference](/docs/reference/command-reference): helper commands inside the container
- [Installing additional PHP extensions](/docs/customizing-the-image/installing-additional-php-extensions)
