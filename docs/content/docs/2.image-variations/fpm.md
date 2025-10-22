---
title: FPM
description: 'Learn how to use the FPM variation of the serversideup/php image.'
---

::lead-p
The FPM variation runs PHP-FPM (FastCGI Process Manager) without a web server. It's designed to work alongside a separate web server or load balancer that handles static content and proxies PHP requests to this container.

Use this variation when you're building microservices architectures or have a separate proxy layer handling HTTP traffic.
::

## When to Use FPM
Use the FPM variation when you need to:

- Separate your PHP processing from your web server layer
- Build microservices where PHP runs as a dedicated backend service
- Use a separate load balancer or API gateway to route traffic
- Have an existing NGINX, Traefik, or other reverse proxy infrastructure
- Scale your PHP processing independently from your web server

#### Perfect for
- Microservices architectures where separation of concerns is important
- Kubernetes deployments with separate service containers
- Large-scale deployments with dedicated load balancers
- Advanced setups where you want full control over your proxy configuration

#### What's Inside

| Item | Status |
|------|--------|
| PHP-FPM process manager | ✅ |
| PHP CLI binary | ✅ |
| Common PHP extensions | ✅ |
| `composer` executable | ✅ |
| `install-php-extensions` script | ✅ |
| Essential system utilities | ✅ |
| S6 Overlay (process supervisor) | ✅ |
| Native health checks | ✅ (via [`php-fpm-healthcheck`](https://github.com/renatomefi/php-fpm-healthcheck){target="_blank"} script) |
| Web server | ❌ (requires external web server) |
| Process management | Single entrypoint, single process |
| Exposed Ports | `9000` (FastCGI) |
| Stop Signal | `SIGQUIT` |

## How FPM Works
Unlike variations that include a web server, the FPM variation only runs PHP-FPM, which listens on port 9000 for FastCGI requests.

You'll need a separate web server (like NGINX, Apache, or Caddy) to:
1. Accept HTTP requests from clients
2. Serve static files directly (CSS, JavaScript, images)
3. Forward PHP requests to the FPM container on port 9000
4. Return the PHP-FPM response back to the client

This architecture gives you maximum flexibility but requires more configuration than the all-in-one variations.

::note
If you want a simpler setup with everything in one container, consider using the `fpm-nginx`, `fpm-apache`, or `frankenphp` variations instead. These include both the web server and PHP-FPM in a single container.
::

## Quick Start
Here are a few examples to help you get started with the FPM variation.

### Docker Compose with Separate NGINX
This example shows a common setup with PHP-FPM in one container and NGINX in another.

```yml [compose.yml]
services:
  php:
    image: serversideup/php:8.4-fpm
    volumes:
      - ./:/var/www/html

  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
    volumes:
      - ./:/var/www/html
      - ./nginx.conf:/etc/nginx/conf.d/default.conf
    depends_on:
      - php
```

And your NGINX configuration (`nginx.conf`):

```nginx [nginx.conf]
server {
    listen 80;
    server_name localhost;
    root /var/www/html/public;

    index index.php index.html;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location ~ \.php$ {
        fastcgi_pass php:9000;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~ /\.(?!well-known).* {
        deny all;
    }
}
```

::tip
Notice how the `fastcgi_pass` directive points to `php:9000`. This is the service name from your Docker Compose file. Docker's networking allows services to communicate using their service names.
::

### Kubernetes Example
The FPM variation is particularly well-suited for Kubernetes deployments where you might have separate containers in the same pod.

```yml [deployment.yaml]
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: my-app
  template:
    metadata:
      labels:
        app: my-app
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
        ports:
        - containerPort: 80
        volumeMounts:
        - name: app-code
          mountPath: /var/www/html
        - name: nginx-config
          mountPath: /etc/nginx/conf.d

      - name: php-fpm
        image: serversideup/php:8.4-fpm
        volumeMounts:
        - name: app-code
          mountPath: /var/www/html

      volumes:
      - name: app-code
        emptyDir: {}
      - name: nginx-config
        configMap:
          name: nginx-config
```

### Health Check
The FPM variation includes [`php-fpm-healthcheck`](https://github.com/renatomefi/php-fpm-healthcheck){target="_blank"}, a POSIX-compliant script that monitors PHP-FPM's `/status` endpoint to verify the service is healthy.

```yaml [compose.yml]{7-10}
services:
  php:
    image: serversideup/php:8.4-fpm
    volumes:
      - ./:/var/www/html
    healthcheck:
      test: ["CMD", "php-fpm-healthcheck"]
      interval: 10s
      timeout: 3s
      retries: 3
```

::tip
The `php-fpm-healthcheck` script can also monitor specific metrics like accepted connections or queue length. For example, you could fail the health check if the listen queue exceeds 10 processes: `php-fpm-healthcheck --listen-queue=10`
::

## Environment Variables
The FPM variation supports extensive customization through environment variables. Here are some common ones:

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

::tip
For a complete list of available environment variables, see the [Environment Variable Specification →](/docs/reference/environment-variable-specification).
::

## Performance Tuning
The FPM variation gives you fine-grained control over PHP process management. Here are some tuning tips:

### For High-Traffic Applications
```yaml [compose.yml]
services:
  php:
    image: serversideup/php:8.4-fpm
    environment:
      PHP_FPM_PM_CONTROL: "static"
      PHP_FPM_PM_MAX_CHILDREN: "50"
      PHP_MEMORY_LIMIT: "512M"
```

### For Low-Memory Environments
```yaml [compose.yml]
services:
  php:
    image: serversideup/php:8.4-fpm
    environment:
      PHP_FPM_PM_CONTROL: "ondemand"
      PHP_FPM_PM_MAX_CHILDREN: "10"
      PHP_FPM_PM_PROCESS_IDLE_TIMEOUT: "10s"
```

## Further Customization
If you need to customize the container further, reference the docs below:

- [Environment Variable Specification](/docs/reference/environment-variable-specification) - See which environment variables are available to customize PHP and PHP-FPM settings.
- [Command Reference](/docs/reference/command-reference) - See which commands are available to run inside the container.
