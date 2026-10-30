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
  conf/              # PHP version matrix, base config, and every pinned dependency version (YAML)
  prepare-php-base.sh # Prepares docker-library/php's Dockerfile to compile a PHP patch
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

**Never call `curl` directly in a Dockerfile or build script.** Use `docker-php-serversideup-download <url> [output-file]` from `src/common/`, which retries with backoff. The whole matrix starts at once and unretried downloads fail on transient 5xx responses from GitHub and other hosts. Download archives to a file before extracting them so a retry never feeds a partial stream to `tar`.

Services register with s6-overlay by adding an empty file to `etc/s6-overlay/user-bundles.d/user/contents.d/` (s6-overlay 3.2.3+ layout). The older `s6-rc.d/user/contents.d/` location makes rc.init try to write to `/etc` at startup, which fails as the unprivileged user and leaves the container unhealthy.

Each variation Dockerfile uses multi-stage builds:
1. Shared assets are `COPY`ed from `src/common/`, `src/s6/`, `src/php-fpm.d/`, and `src/utilities-webservers/`
2. Variation-specific configs live in `src/variations/<variation>/etc/`
3. The build context is the **project root** (not `src/`), so COPY paths are relative to root: `COPY --chmod=755 src/common/ /`

### Build args used across Dockerfiles
- `PHP_VERSION`, `BASE_OS_VERSION`, `PHP_VARIATION` -- set by CI matrix or `scripts/dev.sh`
- `BASE_IMAGE` -- the compiled PHP base from the Depot Registry in CI. Defaults to the official `php:` image, which local builds and fork PRs use.
- Every key under `dependencies` in `scripts/conf/php-versions-base-config.yml` (`S6_VERSION`, `PHPREDIS_VERSION`, `FRANKENPHP_VERSION`, ...) -- passed as a build arg of the same name by CI and `scripts/dev.sh`. Dockerfiles declare them with no default and helper scripts fail when one is missing, so the config is the only place a version lives. To add a dependency, add a line there with a `# renovate:` comment and an `ARG` in each stage that uses it.
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
1. `scripts/get-php-versions.sh` fetches the latest active PHP releases from `https://www.php.net/releases/active.php`. There is no Docker Hub check: we compile PHP ourselves, so a release builds as soon as php.net lists it.
2. The fetched versions are merged with the base config (`scripts/conf/php-versions-base-config.yml`) which defines OS bases, variations, dependency versions, and NGINX versions. A minor's `patch_versions` in the base config replaces php.net's, which pins or holds back a release.
3. The merged result is written to `scripts/conf/php-versions.yml` -- this is the source of truth for CI builds
4. `scripts/generate-matrix.sh` reads the final YAML and produces the GitHub Actions matrix JSON, including each image's `php_base_tag` and `docker_library_ref`

### How PHP is compiled
Each variation's `php_base` (`cli`, `fpm`, or `zts`) names the docker-library/php variant it builds on; a minor's `php_base_overrides` swaps it (8.6 has no `zts` variant, so FrankenPHP uses `cli`). A `-rc` version such as `8.6-rc` builds the newest release candidate from php.net's release-candidates feed and docker-library's `8.6-rc` directory. `scripts/prepare-php-base.sh` downloads docker-library/php at `DOCKER_LIBRARY_PHP_REF` (or the minor's own `docker_library_ref`, as 8.1 has), sets the PHP version, URL, and php.net SHA256, removes `pecl update-channels`, and sets `PHP_BUILD_PROVIDER` to Server Side Up (shown as "Built by" in `php -v`). It checks the result, so a layout change upstream fails loudly. Keep every other line of upstream's Dockerfile untouched: matching the official images' structure is the point. The `redis` extension is built from its GitHub source (with the `liblzf` submodule downloaded separately) so no default build step depends on PECL.

When modifying the version pipeline, the base config (`php-versions-base-config.yml`) is the file you edit. Never edit `php-versions.yml` directly -- it's generated.

## CI/CD

- Builds run via GitHub Actions using **Depot** (`depot/build-push-action`) for multi-arch (`linux/amd64` + `linux/arm64/v8`). Depot builds both architectures natively on its own builders; the GitHub runner only orchestrates, so runner size and architecture do not affect build speed.
- Publishing is three phases, each a reusable workflow the callers (`action_publish-images-*.yml`) chain: `service_setup-matrix.yml` generates the matrix once; `service_build-php-base.yml` compiles each PHP base (one job per PHP version, base OS, and `php_base`) and saves it to the Depot Registry as `<run_id>-php-base-<patch>-<php_base>-<os>`, always with `no-cache` so OS security fixes (a patched libbrotli or OpenSSL) land on the next run instead of when Debian or Alpine publish a new base image; `service_build-images.yml` builds one variation and saves every image to the Depot Registry (nothing public yet), recording the Depot build ID and digest; `service_test-images.yml` pulls the saved images on native amd64 and arm64 Depot runners (Depot sponsors the project, so they are free here and have no concurrency cap), one job per PHP version and base OS so the variations that share base layers share one pull, and runs `scripts/test-image.sh` against each; `service_publish-images.yml` promotes the tested builds with `depot push`, which copies the saved image to every Docker Hub and GHCR tag server-side (no image bytes touch the runner), one job per variation, and fails if the published digest is not the tested one. GHCR allows 2,000 requests a minute per token and `depot push` does not retry a 429, so the publish job pushes only two images at a time and retries a failed push with a growing pause; raising `MAX_PARALLEL` gets every variation's job rate limited at once. `service_report.yml` renders the run table last. Jobs render as `build cli / 8.4.25-bookworm`, `test / 8.4.25-bookworm arm64`, `publish / cli`.
- A broken image can never reach a public tag: what users pull is byte-for-byte what the tests ran. Publishing is all or nothing: if any image fails to build or fails its test, no image from that run is published, including on the weekly rebuilds. Saved images live in the Depot Registry until the project's retention setting removes them.
- Build jobs that save images attach an SPDX SBOM and SLSA provenance (`mode=max`) to the image index. After the digest check, `service_publish-images.yml` signs each registry's copy of the index (one signature per registry, covering every tag) with cosign keyless signing through the workflow's OIDC token, so there is no key to store. Users verify against the identity `.github/workflows/service_publish-images.yml@refs/heads/main` or `@refs/tags/v*`; the commands are in `docs/content/docs/5.guide/7.verifying-images.md`. Images published before this have provenance only.
- `service_scan-images.yml` runs after every production publish (and by hand for the latest one). Grype scans the `linux/amd64` image of every published tag, pulled anonymously from GHCR. The scan job has no token and no registry credentials, and Grype runs in its own container, so a compromised scanner has nothing to steal or publish. Every image's counts go to the run summary, which is public. Findings with a fix become code scanning alerts: the `alerts` job (the only one with `security-events: write`, and it never runs Grype) uploads one SARIF run per variation, category `grype/<variation>`, always against `main` so release and weekly scans share one alert list. Code scanning allows 20 runs per SARIF file, hence one merged run per variation. Grype gives every image the same file path, which would merge alerts across images, so each finding's path and fingerprint are rewritten under `<php minor>-<os>`, which also keeps an alert stable across PHP patches.
- The build matrix is generated from the PHP version pipeline described above.
- `scheduled-task_watch-php-releases.yml` runs hourly, resolves the active patches with `scripts/get-php-versions.sh`, and starts a production run when a patch's `cli` tag on its first OS is missing from Docker Hub, so new PHP patches publish within about an hour of php.net listing them. A Docker Hub lookup that is neither found nor not found is skipped, and no run starts if a production run started in the last 6 hours. Like the weekly rebuild (Tuesday 08:00 UTC, which delivers OS package updates), it only moves floating tags; `-vX.Y.Z` tags come only from the GitHub release.
- Dependencies are monitored by Renovate (`renovate.json`), which replaced Dependabot. It reads the `# renovate:` comments in the base config and `service_lint.yml`, the `nginx_version` lines (from the nginx.org package listings), docker-library/php `master` (weekly, merged automatically once every check passes; every other pin waits for a manual merge), GitHub Actions, and one docs npm package. Every action is pinned to a full commit SHA with its version in a comment (`helpers:pinGitHubActionDigests`), and releases from GitHub and Docker datasources wait 3 days (`minimumReleaseAge`) before Renovate proposes them, so a hijacked or broken release is usually caught first. Merged bumps reach the published images with the next release; PHP patches need no release because they are resolved from php.net at run time.
- Image tags follow the pattern: `serversideup/php:{version}-{variation}` (Debian default) or `serversideup/php:{version}-{variation}-{os}` (Alpine/specific OS).
- Fork PRs skip the base phase and build on the official `php:` images, so they can fail in the hours after a PHP release, and they never exercise changes to how PHP is compiled.
- Depot authentication: the project ID lives in `depot.json` (not a secret). Same-repo runs authenticate through a Depot OIDC trust relationship (`id-token: write`). Pull requests from forks have no OIDC token, so Depot falls back to its open-source pull request flow (https://depot.dev/blog/github-actions-oss-fork-builds): the full matrix builds on ephemeral builders without the project cache, nothing is saved, and each build job loads its amd64 image onto the runner and runs `scripts/test-image.sh` there instead, so the build check still means a tested image. A maintainer publishes a fork's images to `serversideup/php-dev`, and gets the arm64 tests, by running the "Docker Publish (PR Images)" workflow manually with the PR number.
- The CI helper script `scripts/build-summary.sh` is checked by `scripts/tests/run.sh`, a single file of plain assertions over sample images. Run it after changing the script and add an assertion when you add behavior. Keep jq programs explicit with parentheses: `a + b as $x | ...` parses differently across jq versions, and runners ship an older jq than most laptops.
- The project is enrolled in Anthropic's OSS Scanner (`projects/serversideup-php` in anthropics/oss-scanner), which builds `.oss-scanner/Dockerfile` from `main` and audits it offline. That Dockerfile copies `src/` over each published web server image with the same `COPY` lines as `src/variations/*/Dockerfile`, and `.oss-scanner/run-variation` starts each one the way `docker run` would. Nothing fails when these drift, so update them in the same change as:
  - a variation's `COPY` layout or post-copy permission step: the matching overlay and runtime stages in `.oss-scanner/Dockerfile`
  - a new or removed web server variation: its stages in `.oss-scanner/Dockerfile`, and its default command in `run-variation` if it is not `/init`
  - a new default PHP version: `PHP_VERSION` in `.oss-scanner/Dockerfile`
  - a new way for untrusted input to reach the image (a web server location, a healthcheck, a workflow trigger), a change to `SECURITY.md` scope, or a new intentional default the scanner should not report: `.oss-scanner/threat_model.md`

  After changing any of these, build it with `docker build -f .oss-scanner/Dockerfile -t oss-scanner .`, then confirm the affected variations start with no network: `docker run --rm -it --privileged --network none --user root oss-scanner bash`, then `.oss-scanner/run-variation <variation> &` and `curl localhost:8080/healthcheck`.
- Every PR run starts with `service_lint.yml` (script tests, actionlint and zizmor for workflows with zizmor's project decisions recorded in `.github/zizmor.yml`, hadolint for `src/variations/*/Dockerfile` and `.oss-scanner/Dockerfile` with project decisions recorded in `.hadolint.yaml`, ShellCheck at warning severity for `scripts/*.sh`, `scripts/tests/image/*.sh`, `src/common/usr/local/bin/*`, `src/s6/usr/local/bin/*`, `.oss-scanner/run-variation`, and `entrypoint.d/*.sh`) before any image builds. New linters go there. The local commands are in the contributing docs.
- `scripts/test-image.sh <image> [php-version]` runs the image tests in `scripts/tests/image/`: one file per feature area (`php.sh`, `fpm.sh`, `security.sh`, `entrypoint.sh`, `laravel-automations.sh`, `permissions.sh`, `lifecycle.sh`, `web-server.sh`, `ssl.sh`, `trusted-proxy.sh`, `frankenphp.sh`, `octane.sh`), each `test_*` function one test, shared helpers and image facts in `lib.sh`, mounted files in `fixtures/` (`laravel/artisan` records commands instead of running Laravel). Every test runs even after one fails. Add a test to the file for its area, or a new file for a new area; never add checks to `scripts/test-image.sh` itself. Keep tests generic across variations: a file or test declares what it needs with `requires` (`healthcheck`, `web_server`, `https`, `frankenphp`, `fpm`), detected from the image's environment variables rather than its name. Run it locally against any image before opening a PR that touches startup behavior; `TEST_ONLY=<file>` runs one area.
- Every build job records its image details (tags, Depot Registry reference, build ID, digest) as an `image-details-*` artifact; the publish job adds a `.published.json` record with the compressed size per architecture. `service_report.yml` merges them with `scripts/build-summary.sh` (the published record wins) into one table on the run summary and in the PR comment.
- `scheduled-task_scorecard.yml` runs OpenSSF Scorecard on pushes to `main`, weekly, and on branch protection changes, and publishes the score behind the README badge. Publishing only works while the workflow follows Scorecard's rules: no workflow-level `env`, `defaults`, or write permissions, and only Scorecard's approved actions in the job.
- `fail-fast` is off, so one failed image never cancels the others. `trigger_auto-retry-failed-builds.yml` re-runs the failed jobs of a production, beta, or PR run once when only a few jobs failed and no newer run exists. It also handles runs that end `cancelled` because a Depot runner never connected, but skips a run cancelled by hand (no failed jobs). It finds runs by workflow file, because `workflow_run.name` is the run's `run-name` title. If that also fails, or too many jobs failed to look transient, it opens a `ci-failure` issue assigned to the maintainer with the failed jobs, their first error annotation, the log tail, and a link to re-run. Only production and beta runs open issues; PR runs have the PR comment. GitHub's own failure emails do not cover this case reliably: scheduled runs notify whoever last edited the cron line, and re-run attempts are triggered by the Actions bot.

## Verification

To verify image changes:
1. Build the affected variation locally with `scripts/dev.sh`
2. Run `bash scripts/test-image.sh <tag>` against it, and add a test in `scripts/tests/image/` for new behavior
3. Run the built image and confirm the change works: `docker run --rm -it serversideup/php:8.4-fpm-nginx-bookworm sh`
4. For entrypoint script changes, test on both Debian and Alpine builds
5. Run `shellcheck` on any modified shell scripts when available

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
