# AI Agent Guidelines

This project maintains open source PHP Docker images (`serversideup/php`) for Laravel and other PHP applications. Images are published to Docker Hub and GitHub Packages. These images build on top of the official PHP Docker images with production-grade defaults, security hardening, and a superior developer experience through environment-variable-driven configuration. See `docs/content/docs/1.getting-started/4.these-images-vs-others.md` for the full philosophy.

## Project Structure

```
src/
  variations/        # One Dockerfile per image variation (cli, fpm, fpm-apache, fpm-nginx, frankenphp)
  common/            # Shared scripts and configs copied into ALL variations
    usr/local/bin/   # Entrypoint and helper scripts (POSIX /bin/sh)
    etc/entrypoint.d/# Numbered priority entrypoint scripts (00-*, 50-*, etc.)
  s6/                # Shared S6 Overlay service definitions and install script
  php-fpm.d/         # Shared PHP-FPM pool configuration templates
  utilities-webservers/ # Shared web server entrypoint utilities (SSL, etc.)
scripts/             # Build tooling (Bash, not POSIX)
  dev.sh             # Local image builds
  conf/              # PHP version matrix and base config (YAML)
  generate-matrix.sh # Generates CI build matrix from YAML config
  assemble-docker-tags.sh
docs/                # Nuxt 4 documentation site (see docs/AGENTS.md for docs-specific guidelines)
.github/workflows/   # CI/CD with GitHub Actions + Depot for multi-arch builds
```

## Shell Script Rules

**IMPORTANT:** There are two distinct shell environments in this project. Getting this wrong breaks images.

- **`src/` scripts** (entrypoint, healthcheck, helper scripts): MUST be POSIX-compliant `/bin/sh`. These run inside Docker containers on both **Debian** and **Alpine** Linux. No bashisms (`[[ ]]`, arrays, `local -n`, process substitution, etc.).
- **`scripts/` directory** (build tooling): Bash (`/bin/bash`). Must work on macOS, Linux, and WSL2.

### Common gotchas
- Alpine uses BusyBox `sh`, not `bash`. Commands like `readlink -f`, `sed -i` (without backup extension), and `which` behave differently.
- Use `command -v` instead of `which` in POSIX scripts.
- Use `$(...)` not backticks for command substitution.
- Test OS detection with `[ -f /etc/alpine-release ]` (Alpine) or `[ -f /etc/debian_version ]` (Debian).

## Naming Conventions

- Container scripts in `src/common/usr/local/bin/` follow the prefix pattern: `docker-php-serversideup-*` (e.g., `docker-php-serversideup-entrypoint`, `docker-php-serversideup-set-file-permissions`).
- Healthcheck scripts use: `healthcheck-*` (e.g., `healthcheck-horizon`, `healthcheck-queue`).
- Entrypoint.d scripts use numbered prefixes for execution order: `0-container-info.sh`, `1-log-output-level.sh`, `50-laravel-automations.sh`.

## Image Architecture

**There is exactly one Dockerfile per variation.** Each Dockerfile must work across all supported OS bases (Debian and Alpine). OS-specific logic is pushed into shared helper scripts (e.g., `docker-php-serversideup-dep-install-debian`, `docker-php-serversideup-dep-install-alpine`) rather than duplicating Dockerfiles. This keeps maintenance manageable across 8,000+ image tags.

Each variation Dockerfile uses multi-stage builds:
1. Shared assets are `COPY`ed from `src/common/`, `src/s6/`, `src/php-fpm.d/`, and `src/utilities-webservers/`
2. Variation-specific configs live in `src/variations/<variation>/etc/`
3. The build context is the **project root** (not `src/`), so COPY paths are relative to root: `COPY --chmod=755 src/common/ /`

### Build args used across Dockerfiles
- `PHP_VERSION`, `BASE_OS_VERSION`, `PHP_VARIATION` -- set by CI matrix or `scripts/dev.sh`
- `NGINX_VERSION` -- resolved per-OS from `scripts/conf/php-versions-base-config.yml`
- `REPOSITORY_BUILD_VERSION` -- image version label

### Variations
| Variation | Web Server | Process Manager | S6 Overlay |
|-----------|-----------|----------------|------------|
| cli | None | None | No |
| fpm | None | PHP-FPM | No |
| fpm-apache | Apache | PHP-FPM | Yes |
| fpm-nginx | NGINX | PHP-FPM | Yes |
| frankenphp | Caddy (FrankenPHP) | Built-in | No |

## Building Locally
There is a helper script in the `scripts/` directory that will build the image locally. If you attempt to build the image and Docker is not running, tell the user to start Docker Desktop or ensure that the Docker daemon is running before trying again.

```sh
# Requires: Docker with buildx, yq (for fpm-nginx NGINX version resolution)
scripts/dev.sh --variation fpm-nginx --version 8.4 --os bookworm

# Other examples
scripts/dev.sh --variation cli --version 8.5 --os alpine3.22
scripts/dev.sh --variation fpm-nginx --version 8.4 --os bookworm --no-cache
scripts/dev.sh --variation frankenphp --version 8.5 --os bookworm --push
```

## PHP Version Pipeline

PHP versions are NOT hardcoded. The pipeline works like this:
1. `scripts/get-php-versions.sh` fetches the latest active PHP releases from `https://www.php.net/releases/active.php`
2. It validates each version actually exists on DockerHub (with automatic fallback to previous patch if not yet published)
3. The fetched versions are merged with the base config (`scripts/conf/php-versions-base-config.yml`) which defines OS bases, variations, and NGINX versions
4. The merged result is written to `scripts/conf/php-versions.yml` -- this is the source of truth for CI builds
5. `scripts/generate-matrix.sh` reads the final YAML and produces the GitHub Actions matrix JSON

When modifying the version pipeline, the base config (`php-versions-base-config.yml`) is the file you edit. Never edit `php-versions.yml` directly -- it's generated.

## CI/CD

- Builds run via GitHub Actions using **Depot** (`depot/build-push-action`) for multi-arch (`linux/amd64` + `linux/arm64/v8`).
- The reusable workflow is `.github/workflows/service_docker-build-and-publish.yml`.
- The build matrix is generated from the PHP version pipeline described above.
- Image tags follow the pattern: `serversideup/php:{version}-{variation}` (Debian default) or `serversideup/php:{version}-{variation}-{os}` (Alpine/specific OS).

## Verification

There is no automated test suite for image logic. To verify changes:
1. Build the affected variation locally with `scripts/dev.sh`
2. Run the built image and confirm the change works: `docker run --rm -it serversideup/php:8.4-fpm-nginx-bookworm sh`
3. For entrypoint script changes, test on both Debian and Alpine builds
4. Run `shellcheck` on any modified shell scripts when available

## Key Design Decisions

- **Unprivileged by default**: Images run as `www-data`, not root. Web servers listen on `8080`/`8443` (unprivileged ports).
- **Lightweight images**: Only install dependencies that are truly necessary. See `docs/content/docs/1.getting-started/6.default-configurations.md` for what's included and why. When adding packages or extensions, justify the inclusion and keep image size minimal.
- **Environment-variable-driven**: All PHP/FPM/web server configuration is controlled via env vars -- no config file editing at runtime.
- **S6 Overlay** manages multiple processes in web server variations (FPM + web server).
- **Laravel automations** (migrations, caching, etc.) are opt-in via `AUTORUN_ENABLED`.
- **SSL support** is built-in with `SSL_MODE` (off/full) and self-signed cert generation.
- **One Dockerfile per variation**: OS-specific logic belongs in helper scripts, not Dockerfile conditionals or duplicate files.

## Documentation

The documentation and marketing site lives in `docs/` and has its own `docs/AGENTS.md` with guidelines specific to the Nuxt 4 content site. When working in `docs/`, follow that file instead of this one.

## Reference

When you need details beyond what's in this file, read these local sources rather than guessing:

- **Environment variables** (the canonical reference for ALL env vars, their defaults, and which variations they apply to): `docs/content/docs/8.reference/1.environment-variable-specification.md`
- **Default configurations** (what packages, extensions, and settings ship with each image): `docs/content/docs/1.getting-started/6.default-configurations.md`
- **All documentation**: `docs/content/docs/` contains the full docs in markdown. Browse this directory for guides on image variations, framework integrations, deployment, customization, and troubleshooting. There is also a dedicated `docs/AGENTS.md` file for the documentation site itself
- **LLM-optimized docs** (for AI tools that can fetch URLs): https://serversideup.net/open-source/docker-php/llms.txt and https://serversideup.net/open-source/docker-php/llms-full.txt to view the latest stable versions of the documentation.
