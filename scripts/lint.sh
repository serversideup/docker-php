#!/bin/bash
###################################################
# Usage: lint.sh [check...]
###################################################
# Runs the checks CI runs before it builds any image. With no arguments, runs every
# check and reports each failure at the end. Each job in service_lint.yml runs one.
#
# Tool versions live in the env block of service_lint.yml, where Renovate updates them.
# CI exports them; locally they're read from the workflow with yq.
set -uo pipefail

cd "$(dirname "$0")/.." || exit 1

LINT_WORKFLOW=".github/workflows/service_lint.yml"
ALL_CHECKS="actionlint zizmor shellcheck hadolint scripts"

usage() {
    echo "Usage: $0 [check...]"
    echo "Checks: $ALL_CHECKS (default: all)"
}

tool_version() {
    local name="$1"
    if [ -n "${!name:-}" ]; then
        echo "${!name}"
    else
        yq -r ".env.$name" "$LINT_WORKFLOW"
    fi
}

check_actionlint() {
    docker run --rm -v "$PWD:/repo" -w /repo "rhysd/actionlint:$(tool_version ACTIONLINT_VERSION)" -color
}

# GH_TOKEN is passed only when it's set. With it, zizmor also checks that every
# pinned SHA belongs to its repository.
check_zizmor() {
    docker run --rm -e GH_TOKEN -v "$PWD:/repo:ro" -w /repo \
        "ghcr.io/zizmorcore/zizmor:$(tool_version ZIZMOR_VERSION)" --color=always .github/workflows
}

check_shellcheck() {
    local files=(
        scripts/*.sh
        scripts/tests/*.sh
        scripts/tests/image/*.sh
        src/common/usr/local/bin/*
        src/s6/usr/local/bin/*
        .oss-scanner/run-variation
    )
    local file
    while IFS= read -r file; do
        files+=("$file")
    done < <(find src -path '*entrypoint.d*' -name '*.sh')

    docker run --rm -v "$PWD:/repo" -w /repo "koalaman/shellcheck:$(tool_version SHELLCHECK_VERSION)" \
        --color=always --severity=warning "${files[@]}"
}

check_hadolint() {
    docker run --rm -v "$PWD:/repo" -w /repo "hadolint/hadolint:$(tool_version HADOLINT_VERSION)" \
        hadolint src/variations/*/Dockerfile .oss-scanner/Dockerfile
}

# The whole build matrix starts at once and transient 5xx errors are common, so Dockerfiles
# download with docker-php-serversideup-download, which retries. HEALTHCHECK runs curl in the
# finished container, so it's allowed.
verify_dockerfile_downloads() {
    local calls
    calls=$(grep -nE '(^|[^-[:alnum:]])curl[[:space:]]+(-|https?:|"|\$)' \
        src/variations/*/Dockerfile .oss-scanner/Dockerfile | grep -v 'CMD \[')
    [ -z "$calls" ] && return 0
    echo "❌ Use docker-php-serversideup-download instead of curl in a Dockerfile:"
    echo "$calls"
    return 1
}

check_scripts() {
    bash scripts/tests/run.sh &&
        bash scripts/check-env-var-docs.sh &&
        bash scripts/check-command-docs.sh &&
        verify_dockerfile_downloads
}

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
    usage
    exit 0
fi

checks="${*:-$ALL_CHECKS}"
for check in $checks; do
    case " $ALL_CHECKS " in
        *" $check "*) ;;
        *)
            echo "❌ Unknown check: $check"
            usage
            exit 1
            ;;
    esac
done

failed=""
for check in $checks; do
    echo "▶ $check"
    if "check_$check"; then
        echo "✅ $check passed"
    else
        echo "❌ $check failed"
        failed="$failed $check"
    fi
    echo
done

if [ -n "$failed" ]; then
    echo "❌ Failed:$failed"
    exit 1
fi
echo "✅ All checks passed."
