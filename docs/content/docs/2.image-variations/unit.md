---
title: Unit (Deprecated)
description: 'NGINX Unit has been archived. This guide helps you understand what happened and how to migrate to actively maintained alternatives.'
---

## NGINX Unit Has Been Archived

In October 2025, NGINX officially archived the NGINX Unit project and stopped all maintenance. If you're seeing this page, you're likely using our Unit-based images and wondering what to do next.

::caution{to="https://github.com/nginx/unit?tab=readme-ov-file#nginx-unit" target="_blank"}
**The Unit variation is deprecated and has been removed from our project.** [View official NGINX announcement →](https://github.com/nginx/unit?tab=readme-ov-file#nginx-unit){target="_blank"}
::

**The good news:** Your application will continue to work, and you have time to plan your migration. Below, we'll answer your most important questions and guide you through your options.

## Common Questions

### Will my application stop working immediately?

No. Your existing containers will continue to run without interruption. However:

- **No security updates:** NGINX Unit will not receive security patches
- **No bug fixes:** Any issues with Unit itself won't be resolved
- **No new PHP versions:** Unit may not support future PHP releases

You should prioritize your migration, but you're not in a downtime situation.

### What should I migrate to?

We recommend **FrankenPHP** as the best alternative because it offers:

- **Single-process architecture** (similar to Unit's design)
- **Built-in HTTP/2 and HTTP/3 support**
- **Active development** by the PHP community
- **Laravel Octane support** for enhanced performance
- **Better performance** than traditional PHP-FPM setups

:u-button{to="/docs/image-variations/frankenphp" label="Learn about FrankenPHP" aria-label="Learn about FrankenPHP variation" size="md" color="primary" variant="outline" trailing-icon="i-lucide-arrow-right" class="font-bold ring ring-inset ring-blue-600 text-blue-600 hover:ring-blue-500 hover:text-blue-500"}

### What if FrankenPHP doesn't work for me?

You have other proven options:

- **[FPM + NGINX](/docs/image-variations/fpm-nginx)** - Traditional, highly scalable setup (recommended for most production apps)
- **[FPM + Apache](/docs/image-variations/fpm-apache)** - If you need `.htaccess` support or prefer Apache
- **[CLI](/docs/image-variations/cli)** - For queue workers, scheduled tasks, and CLI-only workloads

All of these variations are actively maintained and production-ready.

### How urgent is this migration?

**Timeline:**
- **Now:** Unit images work but receive no updates
- **Next release:** Unit images will be removed from our project

**Recommendation:** Start planning your migration now. Don't rush, but don't delay indefinitely.

### Where can I get help?

We're here to support you through this transition:

- **Community Support:** [Post on our forum](https://serversideup.net/php/community) or [join our Discord](https://serversideup.net/discord) for migration questions
- **Migration Assistance:** Ask questions specific to your setup
- **Documentation:** Follow our comprehensive guides for each variation

## Need More Information?

Explore the documentation for your chosen variation:

- [FrankenPHP Documentation](/docs/image-variations/frankenphp)
- [FPM + NGINX Documentation](/docs/image-variations/fpm-nginx)
- [FPM + Apache Documentation](/docs/image-variations/fpm-apache)

Each variation includes detailed configuration examples, performance tuning tips, and deployment guides.