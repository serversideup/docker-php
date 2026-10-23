#!/bin/bash
set -eo pipefail

###################################################
# Usage: check-upstream-php.sh [ref]
###################################################
# Compares the docker-library/php files vendored in src/base/upstream with the same files
# upstream at ref (default: master). Prints the upstream commit, then a unified diff of
# every vendored file that changed. Exits 0 when nothing changed and 1 when something did.
# See src/base/UPSTREAM for how to pull the changes in.

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
VENDORED_DIR="$(dirname "$SCRIPT_DIR")/src/base/upstream"
ref="${1:-master}"

commit=$(curl -fsSL --retry 5 --retry-delay 3 --retry-all-errors \
    -H "Accept: application/vnd.github.sha" "https://api.github.com/repos/docker-library/php/commits/$ref")
work_dir=$(mktemp -d)
trap 'rm -rf "$work_dir"' EXIT
curl -fsSL --retry 5 --retry-delay 3 --retry-all-errors -o "$work_dir/php.tar.gz" \
    "https://codeload.github.com/docker-library/php/tar.gz/$commit"
tar -xzf "$work_dir/php.tar.gz" -C "$work_dir" --strip-components 1

echo "docker-library/php $commit"
changed=0
for vendored in "$VENDORED_DIR"/*; do
    [ -f "$vendored" ] || continue
    file=$(basename "$vendored")
    if ! diff -u --label "vendored/$file" --label "upstream/$file" "$vendored" "$work_dir/$file"; then
        changed=1
    fi
done
exit "$changed"
