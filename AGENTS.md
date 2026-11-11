# AI Agent Guidelines

This repo builds the `serversideup/php` Docker images: official PHP plus production defaults, hardening, and configuration through environment variables. Images publish to Docker Hub and GHCR. The docs site lives in `docs/` and has its own `docs/AGENTS.md`.

This file lists only the rules that are easy to break. The code, config comments, and workflow files in `.github/workflows/` are the source of truth. When this file disagrees with them, trust the code and fix this file in the same change.

## Shell scripts

There are two shell environments. Mixing them up breaks images.

- **`src/`** runs inside containers on Debian and Alpine (BusyBox): POSIX `/bin/sh` only. Shellcheck in `scripts/lint.sh` catches bashisms through the `#!/bin/sh` shebang, but not `which` or backticks: use `command -v` and `$(...)`. Detect the OS with `[ -f /etc/alpine-release ]` or `[ -f /etc/debian_version ]`.
- **`scripts/`** is Bash and must work on macOS, Linux, and WSL2.

Naming: container helpers are `docker-php-serversideup-*`, health checks are `healthcheck-*`, and `entrypoint.d/` scripts have a number prefix that sets their order (`sort -V`).

## Image rules

- **One Dockerfile per variation**, shared by Debian and Alpine. OS differences go in helper scripts (`docker-php-serversideup-dep-install-debian`, `-alpine`), never in duplicate Dockerfiles.
- **Dockerfiles download with `docker-php-serversideup-download <url> [output-file]`**, never `curl`, because it retries. `scripts/lint.sh` fails on a `curl` call. Download archives to a file before extracting.
- **Dependency versions live only in `scripts/conf/php-versions-base-config.yml`.** The comments at the top of that file explain how they reach the Dockerfiles. To add one: a config line with a `# renovate:` comment, plus an `ARG` with no default in each stage that uses it.
- **Web servers install from vendor apt repositories**, not Debian's: NGINX from nginx.org, Apache from packages.sury.org (Debian's layout, so `a2enmod` and `/etc/apache2` stay the same). Each one's signing key fingerprint is checked in its Dockerfile, and its version is pinned per OS as `nginx_version` and `apache_version` under `operating_systems`.
- **Don't edit `scripts/conf/php-versions.yml`.** It is generated. A minor's `patch_versions` in the base config pins or holds back a release.
- **Keep docker-library/php's Dockerfile untouched** apart from what `scripts/prepare-php-base.sh` already changes. Matching the official images is the point. The `redis` extension builds from GitHub source so no default step depends on PECL.
- **S6 services register** with an empty file in `etc/s6-overlay/user-bundles.d/user/contents.d/`. The older `s6-rc.d/user/contents.d/` makes rc.init write to `/etc` and fails as the unprivileged user.
- Every setting is an environment variable; no runtime config editing. Justify any new package or extension: image size matters.

## PHP versions and releases

- **Release candidates** (`8.6-rc`) resolve through `scripts/get-php-release-candidate.sh` and ship with the weekly rebuild or a release, never the hourly check, which looks only for stable patches. When php.net lists no RC, the run skips it with a warning. Remove the `-rc` minor once the final release is out.
- **When docker-library changes or drops a version**, set `php_base_overrides` or `docker_library_ref` on that minor in the base config. Its comments show the current uses.

## Adding an environment variable

`docs/content/data/env-vars.yml` is the only place a variable is documented. `scripts/check-env-var-docs.sh` fails CI when it and `src/` disagree, so add or change both in the same change.

1. Set the default where the code reads it: an `ENV` line in the final stage of each variation that uses it, `: "${NAME:=default}"` in a script, or `{$NAME:default}` in a FrankenPHP Caddyfile.
2. Add the variable to `env-vars.yml`, sorted A-Z. The comment at the top of that file explains each field. Leave out `variations` when every variation reads it, and use `variation_defaults` when one variation's default differs.
3. A variable only build steps or internal scripts read, never users, goes in `INTERNAL_VARIABLES` in `scripts/check-env-var-docs.sh` instead.
4. Run `bash scripts/check-env-var-docs.sh`, and add an image test for the new behavior.

Helper commands in `/usr/local/bin` work the same way with `docs/content/data/commands.yml` and `scripts/check-command-docs.sh`. Docs pages link to the reference instead of repeating a variable's description. `docs/AGENTS.md` covers when a page may show a default.

## CI rules

- **Publishing is all or nothing**, and users pull exactly the digest that was tested. Don't add a path that publishes an untested image.
- **Don't raise `MAX_PARALLEL`** in `service_publish-images.yml`. GHCR allows 2,000 requests a minute per token and `depot push` doesn't retry a 429.
- **Don't rename or move `service_publish-images.yml`.** Users verify signatures against that path (`docs/content/docs/8.security/2.verifying-images.md`). Manual PR image runs pass `sign: false`.
- **Keep the scanner isolated.** In `service_scan-images.yml`, only the `alerts` job has `security-events: write`, and it never runs Grype. The scan job has no token or registry credentials.
- **`scheduled-task_scorecard.yml`** only publishes while it follows Scorecard's rules: no workflow-level `env`, `defaults`, or write permissions, and only Scorecard's approved actions.
- **New linters go in `scripts/lint.sh`**, with a job in `service_lint.yml` that runs them. Project decisions for zizmor and hadolint are in `.github/zizmor.yml` and `.hadolint.yaml`. Actions are pinned to a full commit SHA with the version in a comment.
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
scripts/dev.sh --variation cli --version 8.5 --os alpine3.24 --no-cache
bash scripts/test-image.sh serversideup/php:8.5-fpm-nginx-bookworm
```

Pick `--os` from that minor's `base_os` list in the base config.

1. Build the affected variation and run `scripts/test-image.sh` against it. Add a test for new behavior.
2. Test entrypoint changes on both a Debian and an Alpine build.
3. Run `bash scripts/lint.sh`, the same checks CI runs before it builds anything.
