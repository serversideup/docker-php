# AI Agent Guidelines

This repo builds the `serversideup/php` Docker images: official PHP plus production defaults, hardening, and configuration through environment variables. Images publish to Docker Hub and GHCR. The docs site lives in `docs/` and has its own `docs/AGENTS.md`.

`docs/content/docs/8.security/1.how-images-are-built.md` summarizes for users how the images are built, tested, and published. The workflow files in `.github/workflows/` are the source of truth; this file only lists the rules that are easy to break.

## Project structure

```
src/
  variations/           # One Dockerfile per variation (cli, fpm, fpm-apache, fpm-nginx, frankenphp)
  common/               # Copied into every variation (entrypoint, helpers, entrypoint.d/)
  s6/                   # S6 Overlay services (fpm-apache, fpm-nginx)
  php-fpm.d/            # PHP-FPM pool templates
  utilities-webservers/ # Shared web server utilities (SSL)
scripts/                # Build tooling (Bash)
  conf/php-versions-base-config.yml  # OS bases, variations, and every pinned dependency version
docs/                   # Nuxt 4 docs site
.oss-scanner/           # Image for Anthropic's OSS Scanner
```

## Shell scripts

There are two shell environments. Mixing them up breaks images.

- **`src/`** runs inside containers on Debian and Alpine (BusyBox): POSIX `/bin/sh` only. No `[[ ]]`, arrays, `local -n`, or process substitution. Use `command -v`, not `which`, and `$(...)`, not backticks. Detect the OS with `[ -f /etc/alpine-release ]` or `[ -f /etc/debian_version ]`.
- **`scripts/`** is Bash and must work on macOS, Linux, and WSL2.

Naming: container helpers are `docker-php-serversideup-*`, health checks are `healthcheck-*`, and `entrypoint.d/` scripts have a number prefix that sets their order (`sort -V`).

## Image rules

- **One Dockerfile per variation**, shared by Debian and Alpine. OS differences go in helper scripts (`docker-php-serversideup-dep-install-debian`, `-alpine`), never in duplicate Dockerfiles.
- **Never call `curl` in a Dockerfile or build script.** Use `docker-php-serversideup-download <url> [output-file]`, which retries; the whole matrix starts at once and transient 5xx errors are common. Download archives to a file before extracting.
- **Dependency versions live only in `scripts/conf/php-versions-base-config.yml`.** Each key under `dependencies` is passed as a build arg of the same name. Dockerfiles declare the `ARG` with no default. To add one: a config line with a `# renovate:` comment, plus an `ARG` in each stage that uses it.
- **Never edit `scripts/conf/php-versions.yml`.** It is generated. A minor's `patch_versions` in the base config pins or holds back a release.
- **Keep docker-library/php's Dockerfile untouched** apart from what `scripts/prepare-php-base.sh` already changes. Matching the official images is the point. The `redis` extension builds from GitHub source so no default step depends on PECL.
- **S6 services register** with an empty file in `etc/s6-overlay/user-bundles.d/user/contents.d/`. The older `s6-rc.d/user/contents.d/` makes rc.init write to `/etc` and fails as the unprivileged user.
- Images run as `www-data` and listen on 8080/8443. Every setting is an environment variable; no runtime config editing. Justify any new package or extension: image size matters.

## PHP versions and releases

- `scripts/get-php-versions.sh` merges php.net's active releases with the base config into `php-versions.yml`. `scripts/assemble-docker-tags.sh` builds the tag list from it.
- **Release candidates** (`8.6-rc`) resolve through `scripts/get-php-release-candidate.sh` and ship with the weekly rebuild or a release, never the hourly check, which looks only for stable patches. When php.net lists no RC, the run skips it with a warning. Remove the `-rc` minor once the final release is out.
- **When docker-library changes or drops a version**: `php_base_overrides` on a minor swaps the upstream variant a variation builds on (8.6 has no `zts`, so `frankenphp: cli`), and `docker_library_ref` pins a dropped version to the last commit that had it (8.1).
- **NGINX signing keys**: Debian checks `SIGNING_FINGERPRINT`; Alpine checks `SIGNING_ALPINE_RSA_PUB_SHA256`, the SHA-256 of the DER-encoded `nginx_signing.rsa.pub`. To rotate, list the new and old hashes comma-separated, then drop the old one. Compute a hash with `openssl rsa -pubin -in nginx_signing.rsa.pub -outform DER | sha256sum`.

## Adding an environment variable

`docs/content/data/env-vars.yml` is the only place a variable is documented. `scripts/check-env-var-docs.sh` fails CI when it and `src/` disagree, so add or change both in the same change.

1. Set the default where the code reads it: an `ENV` line in the final stage of each variation that uses it, `: "${NAME:=default}"` in a script, or `{$NAME:default}` in a FrankenPHP Caddyfile.
2. Add the variable to `env-vars.yml`, sorted A-Z. The comment at the top of that file explains each field. Leave out `variations` when every variation reads it, and use `variation_defaults` when one variation's default differs.
3. A variable only build steps or internal scripts read, never users, goes in `INTERNAL_VARIABLES` in `scripts/check-env-var-docs.sh` instead.
4. Run `bash scripts/check-env-var-docs.sh`, and add an image test for the new behavior.

Docs pages link to the reference instead of repeating a variable's description. `docs/AGENTS.md` covers when a page may show a default.

## CI rules

- **Publishing is all or nothing**, and users pull exactly the digest that was tested. Don't add a path that publishes an untested image.
- **Don't raise `MAX_PARALLEL`** in `service_publish-images.yml`. GHCR allows 2,000 requests a minute per token and `depot push` doesn't retry a 429.
- **Don't rename or move `service_publish-images.yml`.** Users verify signatures against that path (`docs/content/docs/8.security/2.verifying-images.md`). Manual PR image runs pass `sign: false`.
- **Keep the scanner isolated.** In `service_scan-images.yml`, only the `alerts` job has `security-events: write`, and it never runs Grype. The scan job has no token or registry credentials.
- **`scheduled-task_scorecard.yml`** only publishes while it follows Scorecard's rules: no workflow-level `env`, `defaults`, or write permissions, and only Scorecard's approved actions.
- **New linters go in `scripts/lint.sh`**, with a job in `service_lint.yml` that runs them. Run `bash scripts/lint.sh` before calling a change done. Project decisions for zizmor and hadolint are in `.github/zizmor.yml` and `.hadolint.yaml`. Actions are pinned to a full commit SHA with the version in a comment.
- `trigger_auto-retry-failed-builds.yml` finds runs by workflow file, because `workflow_run.name` is the run title.
- Fork PRs build on the official `php:` images, so they never exercise changes to how PHP is compiled.

## Tests

- **Image tests:** `scripts/test-image.sh <image> [php-version]` runs `scripts/tests/image/`, one file per feature area, one `test_*` function per test, helpers in `lib.sh`, mounted files in `fixtures/`. Add tests to the matching area file (or a new file), never to `test-image.sh`. Keep tests generic across variations with `requires` (`healthcheck`, `web_server`, `https`, `frankenphp`, `fpm`). `TEST_ONLY=<file>` runs one area.
- **`scripts/build-summary.sh`** is tested by `scripts/tests/run.sh`; add an assertion with new behavior. Write jq with explicit parentheses (`a + b as $x | ...` parses differently across jq versions, and runners ship an older jq).

## OSS Scanner drift

`.oss-scanner/Dockerfile` mirrors the variation Dockerfiles, and nothing fails when they drift. Update it in the same change as:

- a variation's `COPY` layout or post-copy permission step: the matching stages in `.oss-scanner/Dockerfile`
- a new or removed web server variation: its stages, and its command in `.oss-scanner/run-variation` if it isn't `/init`
- a new default PHP version: `PHP_VERSION` in `.oss-scanner/Dockerfile`
- a new way for untrusted input to reach the image, a `SECURITY.md` scope change, or a new intentional default: `.oss-scanner/threat_model.md`

Then build it with `docker build -f .oss-scanner/Dockerfile -t oss-scanner .`, run `docker run --rm -it --privileged --network none --user root oss-scanner bash`, start `.oss-scanner/run-variation <variation> &`, and check `curl localhost:8080/healthcheck`.

## Build and verify

Requires Docker with buildx, and `yq`. If Docker isn't running, ask the user to start it.

```sh
scripts/dev.sh --variation fpm-nginx --version 8.5 --os bookworm
scripts/dev.sh --variation cli --version 8.5 --os alpine3.22 --no-cache
bash scripts/test-image.sh serversideup/php:8.5-fpm-nginx-bookworm
```

1. Build the affected variation and run `scripts/test-image.sh` against it. Add a test for new behavior.
2. Test entrypoint changes on both a Debian and an Alpine build.
3. Run `bash scripts/lint.sh`, the same checks CI runs before it builds anything.

## Reference

- Environment variables: `docs/content/data/env-vars.yml`. See [Adding an environment variable](#adding-an-environment-variable).
- Helper commands in `/usr/local/bin`: `docs/content/data/commands.yml`, checked the same way by `scripts/check-command-docs.sh`.
- What ships in each image: `docs/content/docs/1.getting-started/6.default-configurations.md`
- All docs: `docs/content/docs/`, or https://serversideup.net/open-source/docker-php/llms-full.txt
