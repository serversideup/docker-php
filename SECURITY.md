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

We publish images for end-of-life PHP versions so legacy applications have a path into containers, but only while two things remain true:

1. The official `php` image for that version still exists on Docker Hub, so we have a base to build from.
2. The operating system release underneath still receives security updates from its distribution. Debian LTS counts. Once a release passes its end of life, a rebuild cannot deliver any patches, and Debian removes the packages from its mirrors soon after, so the build fails anyway.

When either condition stops holding, we stop rebuilding that image and its existing tags freeze at their last successful build. We do not pin archived or snapshot package repositories to keep an EOL base building: that produces a fresh tag with the same unpatched packages, which is worse than an honest frozen tag. Use an EOL base as a stepping stone, not a destination. See [Choosing an image — Operating Systems](https://serversideup.net/open-source/docker-php/docs/getting-started/choosing-an-image#operating-systems) for the trade-off.

## EOL versions and the legacy-modernization path

The following images are no longer built. Their existing tags remain pullable on Docker Hub and GitHub Packages, but they are frozen at their last successful build and will receive no further security updates — not for PHP, and not for the operating system underneath them.

| Image | Last built | Why it stopped |
| --- | --- | --- |
| PHP 7.4 (all variations) | 2026-09-03 | Debian Bullseye and Alpine 3.16 were the only bases the official `php:7.4` images ever shipped, and upstream stopped building them in November 2022. Both bases are now past end of life (see below). |
| PHP 8.0 (all variations) | 2026-09-03 | Same bases as 7.4. Upstream stopped building `php:8.0` in November 2023. |
| Anything on Debian Bullseye | 2026-09-03 | Debian 11 LTS ended on 2026-08-31. The following week Debian removed the Bullseye packages from `deb.debian.org` and `security.debian.org`, so `apt-get install` fails inside the build. |
| Anything on Alpine 3.16 | 2026-09-03 | Alpine 3.16 reached end of life on 2024-05-23 and has received no security updates since. It was only ever used by PHP 7.4 and 8.0. |

PHP 8.1 is also end of life, but it is still built. Its official base images exist, and Debian Bookworm, Debian Trixie, and Alpine 3.22 still receive security updates, so a weekly rebuild delivers real operating system patches. It stops when those bases do.

If you are running one of the frozen images, treat it as a migration deadline rather than a stable base. Move to a supported PHP version and base from [Choosing an image](https://serversideup.net/open-source/docker-php/docs/getting-started/choosing-an-image). The [Upgrade Guide](https://serversideup.net/open-source/docker-php/docs/getting-started/upgrade-guide) covers moving between our releases. If you cannot move yet and need to install packages on a frozen Bullseye tag, the [major version migration guide](https://serversideup.net/open-source/docker-php/docs/guide/major-version-migrations#installing-packages-on-a-frozen-bullseye-image) shows how to do it in your own Dockerfile.

## How updates flow

For the full release model, how floating vs. version-pinned tags behave, and how to apply your own patches to a pinned image, see the [Upgrade Guide](https://serversideup.net/open-source/docker-php/docs/getting-started/upgrade-guide).

For the EOL trade-off when picking an operating system base, see [Choosing an image — Operating Systems](https://serversideup.net/open-source/docker-php/docs/getting-started/choosing-an-image#operating-systems).
