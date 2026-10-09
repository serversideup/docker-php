# Threat model

## What this project does and where untrusted input enters
serversideup/php publishes PHP Docker images (`cli`, `fpm`, `fpm-nginx`, `fpm-apache`, `frankenphp`) on Debian and Alpine. We build on the official `php` images and add entrypoint scripts, S6 Overlay services, and web server configs. All of it is configured through environment variables. The images run as `www-data` and listen on 8080 and 8443. See `SECURITY.md` for our full scope.

Untrusted input:
- **HTTP requests** to the NGINX, Apache, and Caddy (FrankenPHP) configs we ship. Assume any client on the network can send them. This includes headers that reach PHP or our real-IP handling (`TRUSTED_PROXY`), requests for `/healthcheck`, PHP-FPM status paths, `/storage/*.php`, dotfiles such as `.env` and `.git`, path info after `index.php`, and plain-HTTP requests when `SSL_MODE` is `mixed` or `full`.
- **Pull requests from forks** against `.github/workflows/`. A fork can control the PR title, branch name, and file contents. It must never reach repository secrets, the Depot OIDC trust, or any publish to Docker Hub or GHCR.
- **Downloads during image builds** (s6-overlay, NGINX signing keys, PHP extension installer) through `docker-php-serversideup-download`. Tampering in transit or at the source must be caught by checksums or signatures.

Trusted (operators control these):
- Environment variables
- The Dockerfiles that extend our images
- Files mounted into the container
- The PHP application in `/var/www/html`

A finding that needs an attacker to set an environment variable, change the Dockerfile, or write application code is not a vulnerability, unless the docs tell users to fill that value from untrusted input.

## Components that matter most / least
Most:
- `src/common/usr/local/bin/` and `src/common/etc/entrypoint.d/` (startup, Laravel automations, permission changes)
- `src/s6/` services and `src/utilities-webservers/` (SSL certificate generation)
- Web server configs in `src/variations/*/etc/` and PHP-FPM pools in `src/php-fpm.d/`
- The unprivileged model. A path from `www-data` to root, or a default that runs something as root, matters.
- `.github/workflows/` and `scripts/` used by CI (what gets built, tested, and published)

Least, or out of scope:
- The `docs/` site
- Vulnerabilities in PHP, NGINX, Apache, Caddy/FrankenPHP, Composer, s6-overlay, or Debian/Alpine packages. Report those upstream. A config of ours that exposes or enables such a bug is in scope.
- End-of-life images listed in `SECURITY.md`

## How to exercise it
There is no Docker in this environment. The scan image holds every web server variation, each built from the published image with this checkout's `src/` copied over it:
- `fpm-nginx` (Debian) is the image root `/`.
- `fpm-apache`, `frankenphp`, and `fpm-nginx-alpine` are under `/variations/<name>/`.

Each variation has a fresh Laravel app in `/var/www/html`, so the `AUTORUN_*` automations work offline. Start a variation as root with:

```sh
/src/.oss-scanner/run-variation fpm-apache &              # default command, like docker run
/src/.oss-scanner/run-variation frankenphp SSL_MODE=full &
/src/.oss-scanner/run-variation fpm-nginx-alpine AUTORUN_ENABLED=true &
curl -i localhost:8080/healthcheck
kill %1                                                   # stops it, like docker stop
```

`KEY=VALUE` arguments override the image's environment, like `docker run -e`. Every variation listens on 8080 and 8443, so run one at a time or change the port variables. Scripts in `src/` must run under both Debian `dash` and Alpine BusyBox `sh`, so check behavior on `fpm-nginx-alpine` as well. `scripts/tests/run.sh` tests the CI helper scripts.

## How you rate severity
- **Critical:** remote, unauthenticated code execution or arbitrary file read (for example, `.env` or application source) through a config we ship with default settings. Also a fork pull request that can publish an image or read a secret.
- **High:** escalation from `www-data` to root. A default that exposes secrets, the PHP-FPM status page, or FastCGI to the network. A fork pull request that can run code with write access to the repository or with Depot or registry credentials. A downloaded artifact that is used without verification.
- **Medium:** client IP spoofing past `TRUSTED_PROXY`, so that IP-based controls are bypassed. Plain HTTP served when the docs say SSL is enforced. Denial of service from a single unauthenticated request.
- **Low:** version banners and other information leaks that give no access. Hardening gaps with no demonstrated impact.

When a finding only applies with a non-default environment variable, rate it one level lower, unless the docs recommend that setting for production.

## Anything to leave alone
- `COMPOSER_ALLOW_SUPERUSER=1` is intentional for builds that run as root.
- `PHP_DISPLAY_ERRORS` and similar settings that operators can turn on for development are not findings.
- Images run as `www-data` and can be switched to root with `USER root`. That design is documented and intentional.
- Packages that are not pinned, and floating base image tags, are intentional. Weekly rebuilds pick up security fixes.
