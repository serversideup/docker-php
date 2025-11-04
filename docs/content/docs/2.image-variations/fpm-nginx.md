---
title: FPM-NGINX
description: 'Learn how to use the FPM-NGINX variation of the serversideup/php image.'
---

::lead-p
The FPM-NGINX variation combines PHP-FPM with NGINX as a reverse proxy in a single container. This is the traditional setup widely adopted for many PHP applications and is currently is the best balance of performance, stability, and compatibility. If you want the latest and greatest, consider using the [FrankenPHP variation →](/docs/image-variations/frankenphp).
::

## When to Use FPM-NGINX
Use the FPM-NGINX variation when you need to:

- Run Laravel applications with excellent performance and stability
- Want an all-in-one container with both web server and PHP processing
- Need a fast, lightweight web server with low resource consumption
- Serve static assets efficiently while processing PHP requests

#### Perfect for
- Laravel applications (this is our most popular variation for Laravel)
- Modern PHP frameworks (Symfony, etc.)
- API-first applications
- Production deployments requiring high performance and stability

#### What's Inside

| Item | Status |
|------|--------|
| NGINX web server | ✅ |
| PHP-FPM process manager | ✅ |
| PHP CLI binary | ✅ |
| Common PHP extensions | ✅ |
| `composer` executable | ✅ |
| `install-php-extensions` script | ✅ |
| Essential system utilities | ✅ |
| S6 Overlay (process supervisor) | ✅ |
| Native health checks | ✅ (via HTTP endpoint) |
| SSL/TLS support | ✅ (self-signed certificates) |
| Process management | S6 Overlay supervising both NGINX and PHP-FPM |
| Exposed Ports | `8080` (HTTP), `8443` (HTTPS) |
| Stop Signal | `SIGQUIT` |

## How FPM-NGINX Works
This variation runs both NGINX and PHP-FPM in a single container, managed by S6 Overlay. Here's how requests flow:

::steps{level="4"}

#### Client sends HTTP request
The container listens on port 8080 (or 8443 for HTTPS) for incoming HTTP requests.

#### NGINX receives the request
NGINX receives the request and determines if it's a static file or PHP script.

#### Check for static files
Static files (CSS, JavaScript, images) are served directly by NGINX.

#### Forward PHP requests to PHP-FPM
PHP requests are forwarded to PHP-FPM via FastCGI protocol.

#### Process PHP requests with PHP-FPM
PHP-FPM processes the PHP script and returns the result to NGINX.

#### Send the response back to the client
NGINX sends the response back to the client.

::

S6 Overlay ensures both NGINX and PHP-FPM are running and automatically restarts them if either process fails.

::tip
This variation offers better performance than FPM-Apache for most modern PHP applications. NGINX is designed to handle high concurrency with lower resource consumption.
::

## Quick Start
Here are a few examples to help you get started with the FPM-NGINX variation.

### Docker CLI
```bash [Terminal]
docker run -p 80:8080 -v $(pwd):/var/www/html/public serversideup/php:8.4-fpm-nginx
```

Your application will be available at `http://localhost`. The default webroot is `/var/www/html/public`.

### Docker Compose

::warning
Notice how we're mapping the current directory to `/var/www/html/`, but the actual default document root is `/var/www/html/public`. We're assuming you're creating the `public` directory and putting your PHP code in there. It's not best practice to expose your `compose.yml` file. See the [Installation guide](/docs/getting-started/installation) for a full example.
::

This is the recommended approach for local development and production deployments.

```yml [compose.yml]
services:
  php:
    image: serversideup/php:8.4-fpm-nginx
    ports:
      - "80:8080"
    volumes:
      - ./:/var/www/html
    environment:
      PHP_OPCACHE_ENABLE: "1"
```

::tip
The FPM-NGINX variation uses ports 8080 and 8443 (instead of 80 and 443) to allow the container to run as a non-root user for better security.
::

### Laravel Example
The FPM-NGINX variation is perfectly suited for Laravel applications:

```yml [compose.yml]
services:
  php:
    image: serversideup/php:8.4-fpm-nginx
    ports:
      - "80:8080"
      - "443:8443"
    volumes:
      - .:/var/www/html
    environment:
      SSL_MODE: "full"
      PHP_OPCACHE_ENABLE: "1"
    depends_on:
      - mariadb
      - redis

  mariadb:
    image: mariadb:11
    environment:
      MYSQL_ROOT_PASSWORD: rootpassword
      MYSQL_DATABASE: laravel
      MYSQL_USER: laravel
      MYSQL_PASSWORD: laravel
    volumes:
      - db_data:/var/lib/mysql

  redis:
    image: redis:alpine
    command: redis-server --appendonly yes
    volumes:
      - redis_data:/data

volumes:
  db_data:
  redis_data:
```


### Health Check
The FPM-NGINX variation includes a built-in health check that verifies NGINX is responding:

::note
The health check endpoint is configurable via the `HEALTHCHECK_PATH` environment variable, which defaults to `/healthcheck`.
::

If you are using Laravel, you can use the `/up` route to validate that Laravel is running and healthy.

:u-button{to="/docs/guide/using-healthchecks-with-laravel" label="Learn more about using healthchecks with Laravel" aria-label="Learn more about using healthchecks with Laravel" size="md" color="primary" variant="outline" trailing-icon="i-lucide-arrow-right" class="font-bold"}

## SSL/TLS Support
The FPM-NGINX variation includes built-in SSL support with self-signed certificates for development.

### Enabling SSL
```yml [compose.yml]
services:
  php:
    image: serversideup/php:8.4-fpm-nginx
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

### Custom SSL Certificates
For production, use your own SSL certificates:

```yml [compose.yml]
services:
  php:
    image: serversideup/php:8.4-fpm-nginx
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
The FPM-NGINX variation supports extensive customization through environment variables.

### NGINX Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `NGINX_WEBROOT` | `/var/www/html/public` | Document root for NGINX |
| `NGINX_ACCESS_LOG` | `/dev/stdout` | Path to access log file |
| `NGINX_ERROR_LOG` | `/dev/stderr` | Path to error log file |
| `NGINX_CLIENT_MAX_BODY_SIZE` | `100M` | Maximum upload/request body size |
| `NGINX_FASTCGI_BUFFERS` | `8 8k` | Number and size of FastCGI buffers |
| `NGINX_FASTCGI_BUFFER_SIZE` | `8k` | Size of the first FastCGI response buffer |
| `NGINX_SERVER_TOKENS` | `off` | Show NGINX version in headers (`on`/`off`) |
| `NGINX_LISTEN_IP_PROTOCOL` | `all` | IP protocol to listen on (`all`, `ipv4`, `ipv6`) |
| `SSL_MODE` | `off` | SSL mode: `off`, `mixed`, or `full` |
| `SSL_CERTIFICATE_FILE` | `/etc/ssl/private/self-signed-web.crt` | Path to SSL certificate |
| `SSL_PRIVATE_KEY_FILE` | `/etc/ssl/private/self-signed-web.key` | Path to SSL private key |
| `HEALTHCHECK_PATH` | `/healthcheck` | Path for health check endpoint |

::tip{to="/docs/reference/environment-variable-specification"}
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

## Performance Tuning
Here are some tuning recommendations for different scenarios:

### For Production (low memory environments)
::note{to="/docs/deployment-and-production/packaging-your-app-for-deployment"}
If you're running an application in production, you'll likely want to package your application inside an image for deployment. Click here to learn more.
::
```yml [compose.yml]
services:
  php:
    # You'll likely replace this with your own custom image name
    image: serversideup/php:8.4-fpm-nginx
    environment:
      # Enable OPcache for production
      PHP_OPCACHE_ENABLE: "1"
      
      # NGINX Settings (adjust as needed)
      NGINX_FASTCGI_BUFFERS: "16 16k"
      NGINX_FASTCGI_BUFFER_SIZE: "32k"
```

### For High-Traffic Applications
```yml [compose.yml]
services:
  php:
    # You'll likely replace this with your own custom image name
    image: serversideup/php:8.4-fpm-nginx
    environment:
      # NGINX Settings
      NGINX_CLIENT_MAX_BODY_SIZE: "200M"
      NGINX_FASTCGI_BUFFERS: "32 32k"
      
      # PHP-FPM Settings (adjust as needed)
      PHP_FPM_PM_CONTROL: "static"
      PHP_FPM_PM_MAX_CHILDREN: "50"
      PHP_MEMORY_LIMIT: "512M"
      
      # OPcache Settings
      PHP_OPCACHE_ENABLE: "1"
```

::note{to="/docs/reference/environment-variable-specification"}
These are just examples. Review the [Environment Variable Specification](/docs/reference/environment-variable-specification) for a complete list of available environment variables to match your needs.
::

## NGINX Configuration
Unlike Apache's `.htaccess` files, NGINX uses configuration files. The FPM-NGINX variation comes pre-configured for Laravel and modern PHP applications.

### Default Configuration
The default NGINX configuration includes:
- FastCGI caching headers
- Gzip compression
- Security headers
- Laravel-compatible URL rewriting
- Static file optimization

### Custom NGINX Configuration
You can add custom NGINX server configuration by mounting files:

```yml [compose.yml]
services:
  php:
    image: serversideup/php:8.4-fpm-nginx
    ports:
      - "80:8080"
    volumes:
      - ./:/var/www/html
      - ./custom-nginx.conf:/etc/nginx/conf.d/custom.conf:ro
```

Example custom configuration:

```nginx [custom-nginx.conf]
# Add custom headers
add_header X-Custom-Header "My Value" always;

# Custom location block
location /api {
    try_files $uri $uri/ /index.php?$query_string;
    
    # Additional settings for API endpoints
    client_max_body_size 50M;
}

# Rate limiting
limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;
location /api/ {
    limit_req zone=api burst=20 nodelay;
}
```

## Further Customization
If you need to customize the container further, reference the docs below:

- [Environment Variable Specification](/docs/reference/environment-variable-specification) - See which environment variables are available to customize PHP and NGINX settings.
- [Command Reference](/docs/reference/command-reference) - See which commands are available to run inside the container.

