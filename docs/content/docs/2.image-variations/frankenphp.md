---
title: FrankenPHP
description: 'Learn how to use the FrankenPHP variation of the serversideup/php image.'
---

::lead-p
The FrankenPHP variation is a modern application server built on top of the Caddy web server. It runs PHP and the web server in a single process, eliminating the complexity of managing PHP-FPM and a separate web server.

This is the cutting-edge variation that offers worker mode, automatic HTTPS, and modern protocols like HTTP/2 and HTTP/3. It's the recommended variation for new Laravel projects seeking maximum performance.
::

## When to Use FrankenPHP
Use the FrankenPHP variation when you need to:

- Run Laravel Octane with maximum performance
- Use worker mode to keep your application in memory
- Get automatic HTTPS with zero configuration
- Support modern protocols like HTTP/2 and HTTP/3
- Simplify your container architecture (single process)
- Deploy Symfony applications with the Runtime component

#### Perfect for
- Laravel Octane applications
- Symfony applications using the Runtime component
- Modern PHP applications that can benefit from worker mode
- Projects requiring automatic HTTPS
- High-performance APIs that benefit from persistent connections
- Teams wanting the latest and greatest in PHP application servers
- Apps that need PHP 8.3 or newer

## Comparing FrankenPHP to Other Variations

| Feature | FrankenPHP | FPM-NGINX | FPM-Apache |
|---------|-----------|-----------|------------|
| Performance | ⚡️ Excellent (worker mode) | ✅ Very Good | ✅ Good |
| Setup Complexity | ✅ Simple | ✅ Simple | ✅ Simple |
| Worker Mode | ✅ Yes | ❌ No | ❌ No |
| Automatic HTTPS | ✅ Yes | ❌ No | ❌ No |
| HTTP/3 Support | ✅ Yes | ❌ No | ❌ No |
| Laravel Octane | ✅ Native support | ⚠️ Use Swoole | ⚠️ Use Swoole |
| .htaccess Support | ❌ No | ❌ No | ✅ Yes |
| Maturity | ⚠️ New | ✅ Mature | ✅ Mature |

::tip
FrankenPHP is the newest variation and represents the future of PHP application servers. If you're starting a new project and can commit to modern practices, this is the variation to choose.
::


#### Known Issues
::warning{to="https://frankenphp.dev/docs/known-issues/#standalone-binary-and-alpine-based-docker-images" target="_blank"}
Some people are reporting performance issues on the `alpine` version of FrankenPHP. If you're experiencing this, consider using the `debian` version.
::

FrankenPHP is cutting edge and is a very active project. Be sure to understand FrankenPHP's known issues before using it in production. If you're looking for better compatibility, consider using the [FPM-NGINX](/docs/image-variations/fpm-nginx) image.

:u-button{to="https://frankenphp.dev/docs/known-issues/" target="_blank" label="View FrankenPHP's known issues" aria-label="FrankenPHP known issues" size="md" color="primary" variant="outline"  trailing-icon="i-lucide-arrow-right" class="font-bold"}

#### What's Inside

| Item | Status |
|------|--------|
| FrankenPHP application server | ✅ |
| Caddy web server | ✅ (built-in) |
| PHP CLI binary | ✅ |
| Common PHP extensions | ✅ |
| `composer` executable | ✅ |
| `install-php-extensions` script | ✅ |
| Essential system utilities | ✅ |
| Worker mode support | ✅ |
| Automatic HTTPS | ✅ |
| HTTP/2 support | ✅ |
| HTTP/3 support | ✅ |
| Mercure (real-time) | ✅ |
| Native health checks | ✅ (via HTTP endpoint) |
| SSL/TLS support | ✅ (automatic + self-signed) |
| Process management | Single process (no supervisor needed) |
| Exposed Ports | `8080` (HTTP), `8443` (HTTPS + HTTP/3), `2019` (Caddy admin) |
| Stop Signal | `SIGTERM` |

## Classic Mode vs Worker Mode
Unlike traditional setups that require a separate web server and PHP-FPM, FrankenPHP runs everything in a single process. It also operates in two modes:

#### Classic Mode (Default)
- FrankenPHP functions like a traditional PHP server (similar to PHP-FPM)
- Each request bootstraps your application fresh
- No additional configuration needed
- Safe for any existing PHP applications

#### Worker Mode (Advanced)
Worker mode is FrankenPHP's killer feature. Instead of bootstrapping your application for every request, it stays loaded in memory:

- **Traditional**: Bootstrap app → Handle request → Teardown → Repeat
- **Worker Mode**: Bootstrap app once → Handle requests indefinitely

This can result in dramatic performance improvements for Laravel applications.

::tip
Worker mode is perfect for Laravel Octane. Your application boots once and handles thousands of requests without reloading, dramatically improving response times.
::

## How FrankenPHP Works

::steps{level="4"}

#### Client sends request
The client sends an HTTP request to port 8080 (or 8443 for HTTPS).

#### FrankenPHP receives and processes the request
FrankenPHP receives and processes the request directly in a single process. This includes:

1. Static files
2. PHP requests

#### Send response back to client
The response is sent back to the client.

::

## Quick Start
Here are a few examples to help you get started with the FrankenPHP variation.

### Docker CLI

```bash [Terminal]
docker run -p 80:8080 -v $(pwd):/var/www/html/public serversideup/php:8.4-frankenphp
```

Your application will be available at `http://localhost`. The default webroot is `/var/www/html/public`.

### Docker Compose
Here's a basic example getting FrankenPHP up and running with Docker Compose.

::warning
Don't forget to create a `public` directory and put your PHP code in there.
::

::code-tree{defaultValue="compose.yml"}

```yml [compose.yml]
services:
  php:
    # Choose our PHP version and variation
    image: serversideup/php:8.4-frankenphp
    # Expose and map HTTP and HTTPS ports
    ports:
      - 80:8080
      - 443:8443
    # Mount current directory to /var/www/html
    volumes:
      - ./:/var/www/html
    # Support both HTTP and HTTPS
    environment:
      SSL_MODE: mixed
```

```php [public/index.php]
<?php
// Let's just print out some PHP info
phpinfo();
?>
```
::

::tip
The FrankenPHP variation uses ports 8080 and 8443 (instead of 80 and 443) to allow the container to run as a non-root user for better security.
::

### Laravel Octane
Laravel Octane natively supports FrankenPHP. Use our guide below to learn more.

:u-button{to="/docs/framework-guides/laravel/octane" label="Learn more about Laravel Octane" aria-label="Learn more about Laravel Octane" size="md" color="primary" variant="outline" trailing-icon="i-lucide-arrow-right" class="font-bold"}

### Health Check
The FrankenPHP variation includes a built-in health check that verifies the server is responding:

::note
The health check endpoint is configurable via the `HEALTHCHECK_PATH` environment variable, which defaults to `/healthcheck`.
::

If you are using Laravel, you can use the `/up` route to validate that Laravel is running and healthy.

:u-button{to="/docs/guide/using-healthchecks-with-laravel" label="Learn more about using healthchecks with Laravel" aria-label="Learn more about using healthchecks with Laravel" size="md" color="primary" variant="outline" trailing-icon="i-lucide-arrow-right" class="font-bold"}

## Automatic HTTPS
One of FrankenPHP's standout features is automatic HTTPS powered by Caddy. It can automatically obtain and renew SSL certificates from Let's Encrypt.

::tip{to="/docs/deployment-and-production/configuring-ssl"}
See our [Configuring SSL](/docs/deployment-and-production/configuring-ssl) guide for more information on the best strategies for running SSL in production.
::

### Enabling Automatic HTTPS
```yml [compose.yml]
services:
  php:
    image: serversideup/php:8.4-frankenphp
    ports:
      - "80:8080"
      - "443:8443"
    volumes:
      - ./:/var/www/html
    environment:
      CADDY_AUTO_HTTPS: "on"
      # Your domain for automatic certificate
      SERVER_NAME: "example.com"
      SSL_MODE: "full"
```

::warning
Automatic HTTPS requires a public domain name and ports 80/443 accessible from the internet for Let's Encrypt validation. For local development, use self-signed certificates with `SSL_MODE`.
::

### SSL Modes for Development
For local development, use the `SSL_MODE` environment variable:

```yml [compose.yml]
services:
  php:
    image: serversideup/php:8.4-frankenphp
    ports:
      - "80:8080"
      - "443:8443"
    volumes:
      - ./:/var/www/html
    environment:
      SSL_MODE: "full"
```

Available SSL modes:
- `off` - SSL disabled (default)
- `mixed` - Both HTTP (8080) and HTTPS (8443) enabled
- `full` - HTTPS only on port 8443

Learn more about SSL modes in the [Configuring SSL](/docs/deployment-and-production/configuring-ssl) guide.

:u-button{to="/docs/deployment-and-production/configuring-ssl" label="Learn more about SSL modes" aria-label="Learn more about SSL modes" size="md" color="primary" variant="outline" trailing-icon="i-lucide-arrow-right" class="font-bold"}

## Environment Variables
The FrankenPHP variation supports extensive customization through environment variables.

### FrankenPHP/Caddy Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `FRANKENPHP_CONFIG` | `""` | FrankenPHP-specific configuration (e.g., worker mode) |
| `CADDY_SERVER_ROOT` | `/var/www/html/public` | Document root for the application |
| `CADDY_AUTO_HTTPS` | `off` | Enable automatic HTTPS (`on`/`off`) |
| `CADDY_HTTP_PORT` | `8080` | HTTP port |
| `CADDY_HTTPS_PORT` | `8443` | HTTPS port |
| `CADDY_ADMIN` | `off` | Caddy admin API endpoint |
| `CADDY_LOG_FORMAT` | `console` | Log format (`console`/`json`) |
| `CADDY_LOG_OUTPUT` | `stdout` | Log output destination |
| `CADDY_GLOBAL_OPTIONS` | `""` | Additional Caddy global options |
| `CADDY_SERVER_EXTRA_DIRECTIVES` | `""` | Additional Caddy server directives |
| `SSL_MODE` | `off` | SSL mode: `off`, `mixed`, or `full` |
| `SSL_CERTIFICATE_FILE` | `/etc/ssl/private/self-signed-web.crt` | Path to SSL certificate |
| `SSL_PRIVATE_KEY_FILE` | `/etc/ssl/private/self-signed-web.key` | Path to SSL private key |
| `HEALTHCHECK_PATH` | `/healthcheck` | Path for health check endpoint |
| `SERVER_NAME` | `""` | Domain name for automatic HTTPS |

::tip{to="/docs/reference/environment-variable-specification"}
For a complete list of available environment variables, see the [Environment Variable Specification →](/docs/reference/environment-variable-specification).
::

### PHP Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `PHP_MEMORY_LIMIT` | `256M` | Maximum memory a script can use |
| `PHP_MAX_EXECUTION_TIME` | `99` | Maximum time a script can run (seconds) |
| `PHP_UPLOAD_MAX_FILE_SIZE` | `100M` | Maximum upload file size |
| `PHP_POST_MAX_SIZE` | `100M` | Maximum POST request size |
| `PHP_OPCACHE_ENABLE` | `0` | Enable OPcache (`0`/`1`) |
| `PHP_OPCACHE_REVALIDATE_FREQ` | `2` | How often to check for file changes (seconds) |
| `PHP_OPCACHE_VALIDATE_TIMESTAMPS` | `1` | Whether to validate timestamps (`0`/`1`) |

## Caddy Configuration
FrankenPHP uses Caddy's configuration format (Caddyfile) instead of NGINX configuration.

### Adding Custom Options
There are a few areas where you can use environment variables to customize your Caddy configuration:

| Variable | Description | Official Documentation |
|----------|-------------|-------------|
| `CADDY_GLOBAL_OPTIONS` | Global Caddy options | [Caddy Global Options](https://caddyserver.com/docs/caddyfile/options){target="_blank"} |
| `CADDY_SERVER_EXTRA_DIRECTIVES` | Server-specific Caddy directives | [Caddy Server Directives](https://caddyserver.com/docs/caddyfile/directives){target="_blank"} |
| `CADDY_PHP_SERVER_OPTIONS` | PHP-specific Caddy directives (site-specific) | [FrankenPHP PHP Server Options](https://frankenphp.dev/docs/config/#caddyfile-config){target="_blank"} |
| `FRANKENPHP_CONFIG` | FrankenPHP-specific configuration (global) | [FrankenPHP Configuration](https://frankenphp.dev/docs/config/#caddyfile-config){target="_blank"} |

```yml [compose.yml]
services:
  php:
    image: serversideup/php:8.4-frankenphp
    environment:
      CADDY_SERVER_EXTRA_DIRECTIVES: |
        # Add custom headers
        header {
          X-Custom-Header "My Value"
          -Server
        }
```

## Further Customization
If you need to customize the container further, reference the docs below:

- [Environment Variable Specification](/docs/reference/environment-variable-specification) - See which environment variables are available to customize PHP and Caddy settings.
- [Command Reference](/docs/reference/command-reference) - See which commands are available to run inside the container.
- [FrankenPHP Documentation](https://frankenphp.dev/){target="_blank"} - Official FrankenPHP documentation for advanced features.
- [Caddy Documentation](https://caddyserver.com/docs/){target="_blank"} - Official Caddy documentation for web server configuration.