---
title: NGINX Unit (removed)
description: 'The unit variation was removed in v4.1.0 after NGINX archived the NGINX Unit project.'
---

::lead-p
The `unit` variation was removed in [v4.1.0](https://github.com/serversideup/docker-php/releases/tag/v4.1.0){target="_blank"} (November 21, 2025), after NGINX [archived the NGINX Unit project](https://github.com/nginx/unit?tab=readme-ov-file#nginx-unit){target="_blank"} in October 2025.
::

Existing `unit` tags can still be pulled, but they are frozen at v4.0.0 and get no PHP, operating system, or security updates. Move to one of these variations:

- [`fpm-nginx`](/docs/image-variations/fpm-nginx): NGINX and PHP-FPM in one container. The closest match for most apps.
- [`frankenphp`](/docs/image-variations/frankenphp): The application server runs PHP itself, with no PHP-FPM, as Unit did. Requires PHP 8.3 or newer.

Both listen on `8080` and `8443`, as Unit did. Questions about migrating are welcome in the [community forum](https://serversideup.net/php/community){target="_blank"}.
