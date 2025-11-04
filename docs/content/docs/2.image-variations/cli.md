---
title: CLI
description: 'Learn how to use the CLI variation of the serversideup/php image.'
---

::lead-p
The CLI variation is a minimal image designed for running PHP from the command line only. It does not include a web server.

Use this variation for running commands like Composer, running one-off scripts, or executing PHP commands that don't require a web server.
::

## When to Use CLI
Use the CLI variation when you need to:

- Run Composer for dependency management
- Execute one-off PHP scripts
- Need a very small image size

#### Perfect for
- Running PHP locally without needing to install PHP on your host system.

#### What's Inside

| Item | Status |
|------|--------|
| PHP CLI binary | ✅ |
| Common PHP extensions | ✅ |
| `composer` executable | ✅ |
| `install-php-extensions` script | ✅ |
| Essential system utilities | ✅ |
| Native health checks | ❌ |
| Web server | ❌ (no web server included) |
| Process management | Single entrypoint, single process |
| Exposed Ports | None |
| Stop Signal | `SIGTERM` |

## Quick Start
Here are a few quick examples to get you started.

### Docker CLI
```bash [Terminal]
docker run -it -v $(pwd):/var/www/html serversideup/php:cli bash
```

The above command will mount your current directory as the `/var/www/html` directory in the container and open a bash shell inside the container where PHP is installed. To exit, just type `exit`.

### Docker Compose
If you want something more repeatable, you can use Docker Compose to start a container with the CLI variation and mount your current directory as the `/var/www/html` directory in the container.

```yml [compose.yml]
services:
  php:
    image: serversideup/php:cli
    volumes:
      - ./:/var/www/html
```

Once you have your `compose.yml` file set, you can use the `docker compose` cli to start a container with your configuration.

```bash [Terminal]
docker compose run -it php bash
```

Or you can pass commands directly to the container without starting a shell.

::note
Don't get confused. `php` is in this command twice because it's the name of the service and the command to run inside the container. If this is too confusing, you can set your service name to something else like `app` in your `compose.yml` file.
::

```bash [Terminal]
docker compose run php php my-script.php
```

### Further Customization
If you need to customize the container further, reference the docs below:

- [Environment Variable Specifications](/docs/reference/environment-variable-specification) - See which environment variables are available to customize common PHP settings.
- [Command Reference](/docs/reference/command-reference) - See which commands are available to run inside the container.
