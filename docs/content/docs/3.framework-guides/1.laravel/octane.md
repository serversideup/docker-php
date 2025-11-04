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
    image: serversideup/php:8.4-frankenphp
    ports:
      - "80:8080"
    volumes:
      - .:/var/www/html/
```

We'll expand upon this classic mode file and modify it to run Laravel Octane (which uses FrankenPHP's worker mode).

### Install Laravel Octane

First, install Octane in your Laravel application:

```bash [Terminal]
docker compose run php composer require laravel/octane
```

### Configure Worker Mode
We now want to update the compose file to run Laravel Octane and use proper health checks.


```yml [compose.yml]{8-13}
services:
  php:
    image: serversideup/php:8.4-frankenphp
    ports:
      - "80:8080"
    volumes:
      - .:/var/www/html/
    # Start Octane in worker mode
    command: ["php", "artisan", "octane:start", "--server=frankenphp", "--port=8080"]
    # Set healthcheck to use our native healthcheck script for Octane
    healthcheck:
      test: ["CMD", "healthcheck-octane"]
      start_period: 10s
```
We make two major changes here:
1. **Set the command to start Octane in worker mode** - Instead of starting FrankenPHP in classic mode, we start Octane in worker mode.
2. **Set the healthcheck to use our native healthcheck script for Octane** - This is important to ensure that Octane is running and healthy.

### Testing Locally

Run your application locally to test Octane:

```bash [Terminal]
docker compose up
```

Your Laravel application will be available at `http://localhost` with Octane running in worker mode.

## Things to Watch Out For
Since Octane is a whole different way of running Laravel compared to traditional PHP-FPM, there are a few things to watch out for.

### Dependency Injection
Be careful with how you inject dependencies into long-lived objects. Injecting the wrong things into constructors can cause requests to "leak" between users. Review Laravel's [Dependency Injection and Octane](https://laravel.com/docs/12.x/octane#dependency-injection-and-octane) documentation for details.

### Memory Leaks
Review Laravel's [Octane documentation on memory leaks](https://laravel.com/docs/12.x/octane#managing-memory-leaks) to understand what to avoid.

## Learn More
- [FrankenPHP Variation Documentation](/docs/image-variations/frankenphp)
- [Laravel Octane Documentation](https://laravel.com/docs/12.x/octane)
- [FrankenPHP Documentation](https://frankenphp.dev/docs/)