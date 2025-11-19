<p align="center">
		<a href="https://serversideup.net/open-source/docker-php/"><img src="https://raw.githubusercontent.com/serversideup/docker-php/main/.github/img/header.png" width="1280" alt="Docker Images Logo"></a>
</p>
<p align="center">
	<a href="https://github.com/serversideup/docker-php/actions/workflows/action_publish-images-production.yml"><img alt="Build Status" src="https://img.shields.io/github/actions/workflow/status/serversideup/docker-php/.github%2Fworkflows%2Faction_publish-images-production.yml"></a>
	<a href="https://github.com/serversideup/docker-php/blob/main/LICENSE" target="_blank"><img src="https://badgen.net/github/license/serversideup/docker-php" alt="License"></a>
	<a href="https://github.com/sponsors/serversideup"><img src="https://badgen.net/badge/icon/Support%20Us?label=GitHub%20Sponsors&color=orange" alt="Support us"></a>
  <br />
  <a href="https://hub.docker.com/r/serversideup/php/"><img alt="Docker Hub Pulls" src="https://img.shields.io/docker/pulls/serversideup/php"></a>
  <a href="https://serversideup.net/discord"><img alt="Discord" src="https://img.shields.io/discord/910287105714954251?color=blueviolet"></a>
</p>

## Introduction
Production-ready PHP Docker images built on official PHP. Optimized for Laravel, WordPress, and modern PHP applications.

### What Makes These Images Different?

**serversideup/php** takes the official PHP Docker images and adds everything you need for real-world production use:

- ✅ **Secure by Default** - Runs as unprivileged user, not root
- ✅ **Zero Config Required** - Production-ready defaults, customize with environment variables
- ✅ **Batteries Included** - Composer, common extensions, and helpful utilities pre-installed
- ✅ **Framework Optimized** - Special automations for Laravel (migrations, queues, Horizon, etc.)
- ✅ **Multiple Variations** - CLI, FPM, FPM+NGINX, FPM+Apache, FrankenPHP
- ✅ **Modern Architecture** - Native health checks, S6 Overlay, unified logging

<details open>
<summary>
 Features
</summary> <br />

|<picture><img width="100%" alt="Production-Ready" src="https://serversideup.net/wp-content/uploads/2023/08/production-ready.png"></picture>|<picture><img width="100%" alt="Native Health Checks" src="https://serversideup.net/wp-content/uploads/2023/08/native-health-checks.png"></picture>|<picture><img width="100%" alt="High Performance" src="https://serversideup.net/wp-content/uploads/2023/11/high-performance.png"></picture>|
|:---:|:---:|:---:|
|<picture><img width="100%" alt="Customizable and Flexible" src="https://serversideup.net/wp-content/uploads/2023/08/customizable-flexible.png"></picture>|<picture><img width="100%" alt="Native CloudFlare Support" src="https://serversideup.net/wp-content/uploads/2023/11/cloudflare.png"></picture>|<picture><img width="100%" alt="Base on Official PHP" src="https://serversideup.net/wp-content/uploads/2023/11/official-php.png"></picture>|
|<picture><img width="100%" alt="FrankenPHP" src="https://serversideup.net/wp-content/uploads/2023/11/frankenphp.png"></picture>|<picture><img width="100%" alt="Unified Logging" src="https://serversideup.net/wp-content/uploads/2023/11/unified-logging.png"></picture>|<picture><img width="100%" alt="FPM + S6 Overlay" src="https://serversideup.net/wp-content/uploads/2023/11/fpm-s6.png"></picture>|

</details>

## Getting Started

### Try it in 2 minutes ⚡

Want to see how easy it is? Our installation guide walks you through creating your first PHP app with Docker:

1. ✅ Run `phpinfo()` in your browser
2. ✅ Upgrade PHP versions by changing one line
3. ✅ Switch between variations (FPM, FrankenPHP, etc.)
4. ✅ See environment variables in action

**[👉 Follow the quick start guide](https://serversideup.net/open-source/docker-php/docs/getting-started/installation)**

### Quick Example

Here's what a complete Laravel setup with NGINX + PHP 8.5 looks like:

```yml
services:
  php:
    image: serversideup/php:8.5-fpm-nginx
    ports:
      - "80:8080"
    environment:
      # Customize PHP with environment variables
      PHP_OPCACHE_ENABLE: "1"
      PHP_MEMORY_LIMIT: "512M"
      
      # Laravel automations (migrations, storage link, etc.)
      AUTORUN_ENABLED: "true"
    volumes:
      - .:/var/www/html
```

That's it. No complex configs. Just environment variables.

**Ready to try it?** [Get started with our tutorial →](https://serversideup.net/open-source/docker-php/docs/getting-started/installation)

## Available Image Variations

Choose the variation that fits your needs. All images follow the pattern:

```
serversideup/php:{{version}}-{{variation-name}}
```

### Popular Variations

| Variation | Best For | Example |
|-----------|----------|---------|
| **cli** | CLI scripts, cron jobs, queues | `serversideup/php:8.5-cli` |
| **fpm** | Custom web server setup | `serversideup/php:8.5-fpm` |
| **fpm-apache** | Apache-based deployments | `serversideup/php:8.5-fpm-apache` |
| **fpm-nginx** | Stable and performant web server | `serversideup/php:8.5-fpm-nginx` |
| **frankenphp** | Modern, high-performance apps with worker mode | `serversideup/php:8.5-frankenphp` |

### Supported PHP Versions & Platforms

> [!NOTE]  
> All images are available on [**Docker Hub**](https://hub.docker.com/r/serversideup/php/) and [**GitHub Packages**](https://github.com/serversideup/docker-php/pkgs/container/php).

We support **PHP 7.4 through 8.5** with both **Debian** and **Alpine** base images.

[Learn More About Choosing an Image →](https://serversideup.net/open-source/docker-php/docs/getting-started/choosing-an-image)


| ⚙️ Variation | 🚀 Version |
| ------------ | ---------- |
| cli | **Debian Based**<br>[![serversideup/php:8.5-cli](https://img.shields.io/docker/image-size/serversideup/php/8.5-cli?label=serversideup%2Fphp%3A8.5-cli)](https://hub.docker.com/r/serversideup/php/tags?name=8.5-cli&page=1&ordering=-name)<br>[![serversideup/php:8.4-cli](https://img.shields.io/docker/image-size/serversideup/php/8.4-cli?label=serversideup%2Fphp%3A8.4-cli)](https://hub.docker.com/r/serversideup/php/tags?name=8.4-cli&page=1&ordering=-name)<br>[![serversideup/php:8.3-cli](https://img.shields.io/docker/image-size/serversideup/php/8.3-cli?label=serversideup%2Fphp%3A8.3-cli)](https://hub.docker.com/r/serversideup/php/tags?name=8.3-cli&page=1&ordering=-name)<br>[![serversideup/php:8.2-cli](https://img.shields.io/docker/image-size/serversideup/php/8.2-cli?label=serversideup%2Fphp%3A8.2-cli)](https://hub.docker.com/r/serversideup/php/tags?name=8.2-cli&page=1&ordering=-name)<br>[![serversideup/php:8.1-cli](https://img.shields.io/docker/image-size/serversideup/php/8.1-cli?label=serversideup%2Fphp%3A8.1-cli)](https://hub.docker.com/r/serversideup/php/tags?name=8.1-cli&page=1&ordering=-name)<br>[![serversideup/php:8.0-cli](https://img.shields.io/docker/image-size/serversideup/php/8.0-cli?label=serversideup%2Fphp%3A8.0-cli)](https://hub.docker.com/r/serversideup/php/tags?name=8.0-cli&page=1&ordering=-name)<br>[![serversideup/php:7.4-cli](https://img.shields.io/docker/image-size/serversideup/php/7.4-cli?label=serversideup%2Fphp%3A7.4-cli)](https://hub.docker.com/r/serversideup/php/tags?name=7.4-cli&page=1&ordering=-name)<br>**Alpine Based**<br>[![serversideup/php:8.5-cli-alpine](https://img.shields.io/docker/image-size/serversideup/php/8.5-cli-alpine?label=serversideup%2Fphp%3A8.5-cli-alpine)](https://hub.docker.com/r/serversideup/php/tags?name=8.5-cli-alpine&page=1&ordering=-name)<br>[![serversideup/php:8.4-cli-alpine](https://img.shields.io/docker/image-size/serversideup/php/8.4-cli-alpine?label=serversideup%2Fphp%3A8.4-cli-alpine)](https://hub.docker.com/r/serversideup/php/tags?name=8.4-cli-alpine&page=1&ordering=-name)<br>[![serversideup/php:8.3-cli-alpine](https://img.shields.io/docker/image-size/serversideup/php/8.3-cli-alpine?label=serversideup%2Fphp%3A8.3-cli-alpine)](https://hub.docker.com/r/serversideup/php/tags?name=8.3-cli&page=1&ordering=-name)<br>[![serversideup/php:8.2-cli-alpine](https://img.shields.io/docker/image-size/serversideup/php/8.2-cli-alpine?label=serversideup%2Fphp%3A8.2-cli-alpine)](https://hub.docker.com/r/serversideup/php/tags?name=8.2-cli-alpine&page=1&ordering=-name)<br>[![serversideup/php:8.1-cli-alpine](https://img.shields.io/docker/image-size/serversideup/php/8.1-cli-alpine?label=serversideup%2Fphp%3A8.1-cli-alpine)](https://hub.docker.com/r/serversideup/php/tags?name=8.1-cli-alpine&page=1&ordering=-name)<br>[![serversideup/php:8.0-cli-alpine](https://img.shields.io/docker/image-size/serversideup/php/8.0-cli-alpine?label=serversideup%2Fphp%3A8.0-cli-alpine)](https://hub.docker.com/r/serversideup/php/tags?name=8.0-cli-alpine&page=1&ordering=-name)<br>[![serversideup/php:7.4-cli-alpine](https://img.shields.io/docker/image-size/serversideup/php/7.4-cli-alpine?label=serversideup%2Fphp%3A7.4-cli-alpine)](https://hub.docker.com/r/serversideup/php/tags?name=7.4-cli-alpine&page=1&ordering=-name) |
| fpm | **Debian Based**<br>[![serversideup/php:8.5-fpm](https://img.shields.io/docker/image-size/serversideup/php/8.5-fpm?label=serversideup%2Fphp%3A8.5-fpm)](https://hub.docker.com/r/serversideup/php/tags?name=8.5-fpm&page=1&ordering=-name)<br>[![serversideup/php:8.4-fpm](https://img.shields.io/docker/image-size/serversideup/php/8.4-fpm?label=serversideup%2Fphp%3A8.4-fpm)](https://hub.docker.com/r/serversideup/php/tags?name=8.4-fpm&page=1&ordering=-name)<br>[![serversideup/php:8.3-fpm](https://img.shields.io/docker/image-size/serversideup/php/8.3-fpm?label=serversideup%2Fphp%3A8.3-fpm)](https://hub.docker.com/r/serversideup/php/tags?name=8.3-fpm&page=1&ordering=-name)<br>[![serversideup/php:8.2-fpm](https://img.shields.io/docker/image-size/serversideup/php/8.2-fpm?label=serversideup%2Fphp%3A8.2-fpm)](https://hub.docker.com/r/serversideup/php/tags?name=8.2-fpm&page=1&ordering=-name)<br>[![serversideup/php:8.1-fpm](https://img.shields.io/docker/image-size/serversideup/php/8.1-fpm?label=serversideup%2Fphp%3A8.1-fpm)](https://hub.docker.com/r/serversideup/php/tags?name=8.1-fpm&page=1&ordering=-name)<br>[![serversideup/php:8.0-fpm](https://img.shields.io/docker/image-size/serversideup/php/8.0-fpm?label=serversideup%2Fphp%3A8.0-fpm)](https://hub.docker.com/r/serversideup/php/tags?name=8.0-fpm&page=1&ordering=-name)<br>[![serversideup/php:7.4-fpm](https://img.shields.io/docker/image-size/serversideup/php/7.4-fpm?label=serversideup%2Fphp%3A7.4-fpm)](https://hub.docker.com/r/serversideup/php/tags?name=7.4-fpm&page=1&ordering=-name)<br>**Alpine Based**<br>[![serversideup/php:8.5-fpm-alpine](https://img.shields.io/docker/image-size/serversideup/php/8.5-fpm-alpine?label=serversideup%2Fphp%3A8.5-fpm-alpine)](https://hub.docker.com/r/serversideup/php/tags?name=8.5-fpm-alpine&page=1&ordering=-name)<br>[![serversideup/php:8.4-fpm-alpine](https://img.shields.io/docker/image-size/serversideup/php/8.4-fpm-alpine?label=serversideup%2Fphp%3A8.4-fpm-alpine)](https://hub.docker.com/r/serversideup/php/tags?name=8.4-fpm-alpine&page=1&ordering=-name)<br>[![serversideup/php:8.3-fpm-alpine](https://img.shields.io/docker/image-size/serversideup/php/8.3-fpm-alpine?label=serversideup%2Fphp%3A8.3-fpm-alpine)](https://hub.docker.com/r/serversideup/php/tags?name=8.3-fpm-alpine&page=1&ordering=-name)<br>[![serversideup/php:8.2-fpm-alpine](https://img.shields.io/docker/image-size/serversideup/php/8.2-fpm-alpine?label=serversideup%2Fphp%3A8.2-fpm-alpine)](https://hub.docker.com/r/serversideup/php/tags?name=8.2-fpm-alpine&page=1&ordering=-name)<br>[![serversideup/php:8.1-fpm-alpine](https://img.shields.io/docker/image-size/serversideup/php/8.1-fpm-alpine?label=serversideup%2Fphp%3A8.1-fpm-alpine)](https://hub.docker.com/r/serversideup/php/tags?name=8.1-fpm-alpine&page=1&ordering=-name)<br>[![serversideup/php:8.0-fpm-alpine](https://img.shields.io/docker/image-size/serversideup/php/8.0-fpm-alpine?label=serversideup%2Fphp%3A8.0-fpm-alpine)](https://hub.docker.com/r/serversideup/php/tags?name=8.0-fpm-alpine&page=1&ordering=-name)<br>[![serversideup/php:7.4-fpm-alpine](https://img.shields.io/docker/image-size/serversideup/php/7.4-fpm-alpine?label=serversideup%2Fphp%3A7.4-fpm-alpine)](https://hub.docker.com/r/serversideup/php/tags?name=7.4-fpm-alpine&page=1&ordering=-name) |
| fpm-apache | **Debian Based**<br>[![serversideup/php:8.5-fpm-apache](https://img.shields.io/docker/image-size/serversideup/php/8.5-fpm-apache?label=serversideup%2Fphp%3A8.5-fpm-apache)](https://hub.docker.com/r/serversideup/php/tags?name=8.5-fpm-apache&page=1&ordering=-name)<br>[![serversideup/php:8.4-fpm-apache](https://img.shields.io/docker/image-size/serversideup/php/8.4-fpm-apache?label=serversideup%2Fphp%3A8.4-fpm-apache)](https://hub.docker.com/r/serversideup/php/tags?name=8.4-fpm-apache&page=1&ordering=-name)<br>[![serversideup/php:8.3-fpm-apache](https://img.shields.io/docker/image-size/serversideup/php/8.3-fpm-apache?label=serversideup%2Fphp%3A8.3-fpm-apache)](https://hub.docker.com/r/serversideup/php/tags?name=8.3-fpm-apache&page=1&ordering=-name)<br>[![serversideup/php:8.2-fpm-apache](https://img.shields.io/docker/image-size/serversideup/php/8.2-fpm-apache?label=serversideup%2Fphp%3A8.2-fpm-apache)](https://hub.docker.com/r/serversideup/php/tags?name=8.2-fpm-apache&page=1&ordering=-name)<br>[![serversideup/php:8.1-fpm-apache](https://img.shields.io/docker/image-size/serversideup/php/8.1-fpm-apache?label=serversideup%2Fphp%3A8.1-fpm-apache)](https://hub.docker.com/r/serversideup/php/tags?name=8.1-fpm-apache&page=1&ordering=-name)<br>[![serversideup/php:8.0-fpm-apache](https://img.shields.io/docker/image-size/serversideup/php/8.0-fpm-apache?label=serversideup%2Fphp%3A8.0-fpm-apache)](https://hub.docker.com/r/serversideup/php/tags?name=8.0-fpm-apache&page=1&ordering=-name)<br>[![serversideup/php:7.4-fpm-apache](https://img.shields.io/docker/image-size/serversideup/php/7.4-fpm-apache?label=serversideup%2Fphp%3A7.4-fpm-apache)](https://hub.docker.com/r/serversideup/php/tags?name=7.4-fpm-apache&page=1&ordering=-name) |
| fpm-nginx | **Debian Based**<br>[![serversideup/php:8.5-fpm-nginx](https://img.shields.io/docker/image-size/serversideup/php/8.5-fpm-nginx?label=serversideup%2Fphp%3A8.5-fpm-nginx)](https://hub.docker.com/r/serversideup/php/tags?name=8.5-fpm-nginx&page=1&ordering=-name)<br>[![serversideup/php:8.4-fpm-nginx](https://img.shields.io/docker/image-size/serversideup/php/8.4-fpm-nginx?label=serversideup%2Fphp%3A8.4-fpm-nginx)](https://hub.docker.com/r/serversideup/php/tags?name=8.4-fpm-nginx&page=1&ordering=-name)<br>[![serversideup/php:8.3-fpm-nginx](https://img.shields.io/docker/image-size/serversideup/php/8.3-fpm-nginx?label=serversideup%2Fphp%3A8.3-fpm-nginx)](https://hub.docker.com/r/serversideup/php/tags?name=8.3-fpm-nginx&page=1&ordering=-name)<br>[![serversideup/php:8.2-fpm-nginx](https://img.shields.io/docker/image-size/serversideup/php/8.2-fpm-nginx?label=serversideup%2Fphp%3A8.2-fpm-nginx)](https://hub.docker.com/r/serversideup/php/tags?name=8.2-fpm-nginx&page=1&ordering=-name)<br>[![serversideup/php:8.1-fpm-nginx](https://img.shields.io/docker/image-size/serversideup/php/8.1-fpm-nginx?label=serversideup%2Fphp%3A8.1-fpm-nginx)](https://hub.docker.com/r/serversideup/php/tags?name=8.1-fpm-nginx&page=1&ordering=-name)<br>[![serversideup/php:8.0-fpm-nginx](https://img.shields.io/docker/image-size/serversideup/php/8.0-fpm-nginx?label=serversideup%2Fphp%3A8.0-fpm-nginx)](https://hub.docker.com/r/serversideup/php/tags?name=8.0-fpm-nginx&page=1&ordering=-name)<br>[![serversideup/php:7.4-fpm-nginx](https://img.shields.io/docker/image-size/serversideup/php/7.4-fpm-nginx?label=serversideup%2Fphp%3A7.4-fpm-nginx)](https://hub.docker.com/r/serversideup/php/tags?name=7.4-fpm-nginx&page=1&ordering=-name)<br>**Alpine Based**<br>[![serversideup/php:8.5-fpm-nginx-alpine](https://img.shields.io/docker/image-size/serversideup/php/8.5-fpm-nginx-alpine?label=serversideup%2Fphp%3A8.5-fpm-nginx-alpine)](https://hub.docker.com/r/serversideup/php/tags?name=8.5-fpm-nginx-alpine&page=1&ordering=-name)<br>[![serversideup/php:8.4-fpm-nginx-alpine](https://img.shields.io/docker/image-size/serversideup/php/8.4-fpm-nginx-alpine?label=serversideup%2Fphp%3A8.4-fpm-nginx-alpine)](https://hub.docker.com/r/serversideup/php/tags?name=8.4-fpm-nginx-alpine&page=1&ordering=-name)<br>[![serversideup/php:8.3-fpm-nginx-alpine](https://img.shields.io/docker/image-size/serversideup/php/8.3-fpm-nginx-alpine?label=serversideup%2Fphp%3A8.3-fpm-nginx-alpine)](https://hub.docker.com/r/serversideup/php/tags?name=8.3-fpm-nginx-alpine&page=1&ordering=-name)<br>[![serversideup/php:8.2-fpm-nginx-alpine](https://img.shields.io/docker/image-size/serversideup/php/8.2-fpm-nginx-alpine?label=serversideup%2Fphp%3A8.2-fpm-nginx-alpine)](https://hub.docker.com/r/serversideup/php/tags?name=8.2-fpm-nginx-alpine&page=1&ordering=-name)<br>[![serversideup/php:8.1-fpm-nginx-alpine](https://img.shields.io/docker/image-size/serversideup/php/8.1-fpm-nginx-alpine?label=serversideup%2Fphp%3A8.1-fpm-nginx-alpine)](https://hub.docker.com/r/serversideup/php/tags?name=8.1-fpm-nginx-alpine&page=1&ordering=-name)<br>[![serversideup/php:8.0-fpm-nginx-alpine](https://img.shields.io/docker/image-size/serversideup/php/8.0-fpm-nginx-alpine?label=serversideup%2Fphp%3A8.0-fpm-nginx-alpine)](https://hub.docker.com/r/serversideup/php/tags?name=8.0-fpm-nginx-alpine&page=1&ordering=-name)<br>[![serversideup/php:7.4-fpm-nginx-alpine](https://img.shields.io/docker/image-size/serversideup/php/7.4-fpm-nginx-alpine?label=serversideup%2Fphp%3A7.4-fpm-nginx-alpine)](https://hub.docker.com/r/serversideup/php/tags?name=7.4-fpm-nginx-alpine&page=1&ordering=-name) |
| frankenphp | **Debian Based**<br>[![serversideup/php:8.5-frankenphp](https://img.shields.io/docker/image-size/serversideup/php/8.5-frankenphp?label=serversideup%2Fphp%3A8.5-frankenphp)](https://hub.docker.com/r/serversideup/php/tags?name=8.5-frankenphp&page=1&ordering=-name)<br>[![serversideup/php:8.4-frankenphp](https://img.shields.io/docker/image-size/serversideup/php/8.4-frankenphp?label=serversideup%2Fphp%3A8.4-frankenphp)](https://hub.docker.com/r/serversideup/php/tags?name=8.4-frankenphp&page=1&ordering=-name)<br>[![serversideup/php:8.3-frankenphp](https://img.shields.io/docker/image-size/serversideup/php/8.3-frankenphp?label=serversideup%2Fphp%3A8.3-frankenphp)](https://hub.docker.com/r/serversideup/php/tags?name=8.3-frankenphp&page=1&ordering=-name)<br>**Alpine Based**<br>[![serversideup/php:8.5-frankenphp-alpine](https://img.shields.io/docker/image-size/serversideup/php/8.5-frankenphp-alpine?label=serversideup%2Fphp%3A8.5-frankenphp-alpine)](https://hub.docker.com/r/serversideup/php/tags?name=8.5-frankenphp-alpine&page=1&ordering=-name)<br>[![serversideup/php:8.4-frankenphp-alpine](https://img.shields.io/docker/image-size/serversideup/php/8.4-frankenphp-alpine?label=serversideup%2Fphp%3A8.4-frankenphp-alpine)](https://hub.docker.com/r/serversideup/php/tags?name=8.4-frankenphp-alpine&page=1&ordering=-name)<br>[![serversideup/php:8.3-frankenphp-alpine](https://img.shields.io/docker/image-size/serversideup/php/8.3-frankenphp-alpine?label=serversideup%2Fphp%3A8.3-frankenphp-alpine)](https://hub.docker.com/r/serversideup/php/tags?name=8.3-frankenphp-alpine&page=1&ordering=-name) |
| unit (deprecated) | ⚠️ NGINX is no longer maintaining NGINX Unit. Updates have been removed from this project. [Learn more →](https://serversideup.net/open-source/docker-php/docs/image-variations/unit) |

## Professional Support
Need help integrating Docker with your PHP application?

- **[Managed Hosting](https://serversideup.net/hire-us/)** - CI/CD design, managed hosting, guaranteed uptime
- **[One-time Session](https://schedule.serversideup.net/team/serversideup/quick-chat-with-jay)** - Video + screen-sharing with core contributors
- **[Complete Development Team](https://serversideup.net/hire-us/)** - Get help from hardware to pixel and everything in between.

## Resources
- **[Website](https://serversideup.net/open-source/docker-php/)** overview of the product.
- **[Docs](https://serversideup.net/open-source/docker-php/docs)** for a deep-dive on how to use the product.
- **[Discord](https://serversideup.net/discord)** for friendly support from the community and the team.
- **[GitHub](https://github.com/serversideup/docker-php)** for source code, bug reports, and project management.
- **[Get Professional Help](https://serversideup.net/professional-support)** - Get video + screen-sharing help directly from the core contributors.

## Contributing
As an open-source project, we strive for transparency and collaboration in our development process. We greatly appreciate any contributions members of our community can provide. Whether you're fixing bugs, proposing features, improving documentation, or spreading awareness - your involvement strengthens the project. Please review our [contribution guidelines](https://serversideup.net/open-source/docker-php/docs/getting-started/contributing) and [code of conduct](./.github/code_of_conduct.md) to understand how we work together respectfully.

- **Bug Report**: If you're experiencing an issue while using these images, please [create an issue](https://github.com/serversideup/docker-php/issues/new/choose).
- **Feature Request**: Make this project better by [submitting a feature request](https://github.com/serversideup/docker-php/discussions/66).
- **Documentation**: Improve our documentation by [submitting a documentation change](./docs/README.md).
- **Community Support**: Help others on [GitHub Discussions](https://github.com/serversideup/docker-php/discussions) or [Discord](https://serversideup.net/discord).
- **Security Report**: Report critical security issues via [our responsible disclosure policy](https://www.notion.so/Responsible-Disclosure-Policy-421a6a3be1714d388ebbadba7eebbdc8).

Need help getting started? Join our Discord community and we'll help you out!

<a href="https://serversideup.net/discord"><img src="https://serversideup.net/wp-content/themes/serversideup/images/open-source/join-discord.svg" title="Join Discord"></a>

## Our Sponsors
All of our software is free and open to the world. None of this can be brought to you without the financial backing of our sponsors.

<p align="center"><a href="https://github.com/sponsors/serversideup"><img src="https://521public.s3.amazonaws.com/serversideup/sponsors/sponsor-box.png" alt="Sponsors"></a></p>

### Black Level Sponsors
<a href="https://sevalla.com"><img src="https://serversideup.net/wp-content/uploads/2024/10/sponsor-image.png" alt="Sevalla" width="546px"></a>

#### Bronze Sponsors
<!-- bronze -->No bronze sponsors yet. <a href="https://github.com/sponsors/serversideup">Become a sponsor →</a><!-- bronze -->

#### Infrastructure Sponsors
This project requires significant computing power to build and maintain over 8,000 different Docker image tags. We're extremely grateful for the following sponsors:

<a href="https://depot.dev/"><img src="https://serversideup.net/sponsors/depot.png" alt="Depot" width="250px"></a>&nbsp;&nbsp;<a href="https://hub.docker.com/u/serversideup"><img src="https://serversideup.net/sponsors/docker.png" alt="Docker" width="250px"></a>

#### Individual Supporters
<!-- supporters --><a href="https://github.com/aagjalpankaj"><img src="https://github.com/aagjalpankaj.png" width="40px" alt="aagjalpankaj" /></a>&nbsp;&nbsp;<!-- supporters -->

## About Us
We're [Dan](https://x.com/danpastori) and [Jay](https://x.com/jaydrogers) - a two-person team with a passion for open source products. We created [Server Side Up](https://serversideup.net) to help share what we learn.

<div align="center">

| <div align="center">Dan Pastori</div>                  | <div align="center">Jay Rogers</div>                                 |
| ----------------------------- | ------------------------------------------ |
| <div align="center"><a href="https://x.com/danpastori"><img src="https://serversideup.net/wp-content/uploads/2023/08/dan.jpg" title="Dan Pastori" width="150px"></a><br /><a href="https://x.com/danpastori"><img src="https://serversideup.net/wp-content/themes/serversideup/images/open-source/twitter.svg" title="Twitter" width="24px"></a><a href="https://github.com/danpastori"><img src="https://serversideup.net/wp-content/themes/serversideup/images/open-source/github.svg" title="GitHub" width="24px"></a></div>                        | <div align="center"><a href="https://x.com/jaydrogers"><img src="https://serversideup.net/wp-content/uploads/2023/08/jay.jpg" title="Jay Rogers" width="150px"></a><br /><a href="https://x.com/jaydrogers"><img src="https://serversideup.net/wp-content/themes/serversideup/images/open-source/twitter.svg" title="Twitter" width="24px"></a><a href="https://github.com/jaydrogers"><img src="https://serversideup.net/wp-content/themes/serversideup/images/open-source/github.svg" title="GitHub" width="24px"></a></div>                                       |

</div>

### Find us at:

* **📖 [Blog](https://serversideup.net)** - Get the latest guides and free courses on all things web/mobile development.
* **🙋 [Community](https://community.serversideup.net)** - Get friendly help from our community members.
* **🤵‍♂️ [Get Professional Help](https://serversideup.net/professional-support)** - Get video + screen-sharing support from the core contributors.
* **💻 [GitHub](https://github.com/serversideup)** - Check out our other open source projects.
* **📫 [Newsletter](https://serversideup.net/subscribe)** - Skip the algorithms and get quality content right to your inbox.
* **🐥 [Twitter](https://x.com/serversideup)** - You can also follow [Dan](https://x.com/danpastori) and [Jay](https://x.com/jaydrogers).
* **❤️ [Sponsor Us](https://github.com/sponsors/serversideup)** - Please consider sponsoring us so we can create more helpful resources.

## Our Products
If you appreciate this project, be sure to check out our other projects.

### 📚 Books
- **[The Ultimate Guide to Building APIs & SPAs](https://serversideup.net/ultimate-guide-to-building-apis-and-spas-with-laravel-and-nuxt3/)**: Build web & mobile apps from the same codebase.
- **[Building Multi-Platform Browser Extensions](https://serversideup.net/building-multi-platform-browser-extensions/)**: Ship extensions to all browsers from the same codebase.

### 🛠️ Software-as-a-Service
- **[Bugflow](https://bugflow.io/)**: Get visual bug reports directly in GitHub, GitLab, and more.
- **[SelfHost Pro](https://selfhostpro.com/)**: Connect Stripe or Lemonsqueezy to a private docker registry for self-hosted apps.

### 🌍 Open Source
- **[AmplitudeJS](https://521dimensions.com/open-source/amplitudejs)**: Open-source HTML5 & JavaScript Web Audio Library.
- **[Spin](https://serversideup.net/open-source/spin/)**: Laravel Sail alternative for running Docker from development → production.
- **[Financial Freedom](https://github.com/serversideup/financial-freedom)**: Open source alternative to Mint, YNAB, & Monarch Money.