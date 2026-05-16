# Security Policy

`serversideup/php` is a **downstream distributor**. We package PHP, NGINX, Apache, Composer, the base operating system, and related tooling into production-ready Docker images. We do not maintain those upstream projects ourselves — this policy explains what belongs here and what belongs upstream.

## Reporting a vulnerability

For anything in scope below, please use **[GitHub's private vulnerability reporting](https://github.com/serversideup/docker-php/security/advisories/new)** to open a confidential report. Please include:

- The affected image tag and digest (e.g. `serversideup/php:8.4-fpm-nginx@sha256:…`)
- Steps to reproduce and the impact
- Any suggested mitigation, if you have one

Do not disclose details publicly (issues, discussions, social media) before a fix is released.

## What is in scope

Vulnerabilities in what *we* author and ship:

- Entrypoint scripts, healthchecks, helper scripts, and S6 service definitions in `src/`
- Default configs we ship for PHP-FPM, NGINX, Apache, and FrankenPHP
- Insecure defaults: ports, file permissions, the `www-data` user model, SSL defaults
- Build pipeline integrity (GitHub Actions workflows, tag assembly, image publishing)
- Documentation that materially misleads users about a security-relevant setting

## What is out of scope — report to the upstream project

Vulnerabilities in software we package but do not maintain belong with the upstream project, not here:

| Component | Where to report |
| --- | --- |
| PHP itself | [The PHP project](https://www.php.net/) (security mailing list: `security@php.net`) |
| NGINX | [NGINX security advisories](https://nginx.org/en/security_advisories.html) |
| Apache HTTP Server | [Apache HTTPD security](https://httpd.apache.org/security_report.html) |
| Composer | [composer/composer on GitHub](https://github.com/composer/composer/security) |
| Debian / Alpine base packages | The respective distribution security teams |

If an upstream CVE is already publicly disclosed, you don't need to file with us — we pick up upstream patches on our **weekly rebuilds (Tuesday 08:00 UTC)** for floating tags. See [How our releases work](https://serversideup.net/open-source/docker-php/docs/getting-started/upgrade-guide#how-our-releases-work) for the full cadence and which tags receive rebuilds.

## Component lifecycle references

Our images bundle third-party software, each with its own support window. Before reporting an issue (or pinning to a particular version), confirm the component is still receiving security fixes from its maintainers:

| Component | Lifecycle reference |
| --- | --- |
| PHP | [endoflife.date/php](https://endoflife.date/php) |
| Debian | [endoflife.date/debian](https://endoflife.date/debian) |
| Alpine Linux | [endoflife.date/alpine-linux](https://endoflife.date/alpine-linux) |
| NGINX | [endoflife.date/nginx](https://endoflife.date/nginx) |
| Apache HTTP Server | [endoflife.date/apache](https://endoflife.date/apache) |
| Composer | [endoflife.date/composer](https://endoflife.date/composer) |

We continue to publish images for end-of-life PHP versions and operating system bases so legacy applications have a path into containers — but those bases will not receive new upstream security fixes. Use them as a stepping stone, not a destination. See [Choosing an image — Operating Systems](https://serversideup.net/open-source/docker-php/docs/getting-started/choosing-an-image#operating-systems) for the trade-off.

## How updates flow

For the full release model, how floating vs. version-pinned tags behave, and how to apply your own patches to a pinned image, see the [Upgrade Guide](https://serversideup.net/open-source/docker-php/docs/getting-started/upgrade-guide).

For the EOL trade-off when picking an operating system base, see [Choosing an image — Operating Systems](https://serversideup.net/open-source/docker-php/docs/getting-started/choosing-an-image#operating-systems).
