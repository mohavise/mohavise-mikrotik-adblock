#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"

fail() {
    echo "RouterOS control-flow validation failed: $1" >&2
    exit 1
}

mapfile -t routeros_files < <(find "$REPO_DIR" -maxdepth 1 -type f -name '*.rsc' -print | sort)

if grep -En ':return[[:space:]]*([;}]|$)' "${routeros_files[@]}"; then
    fail 'value-less :return found'
fi

if grep -En 'mode=https|ssl-verify=no' "${routeros_files[@]}"; then
    fail 'insecure RouterOS download setting found'
fi

for file in "$REPO_DIR"/safe-*.rsc; do
    grep -q 'check-certificate=yes-without-crl' "$file" || fail "missing certificate verification in $file"
    grep -q 'verbose=yes dry-run' "$file" || fail "missing import preflight in $file"
done

grep -q 'ssl-verify=yes' "$REPO_DIR/install-mohavise-adblock.rsc" || fail 'normal adlist SSL verification is disabled'
grep -q 'ssl-verify=yes' "$REPO_DIR/install-mohavise-adult-adblock.rsc" || fail 'adult adlist SSL verification is disabled'

printf 'RouterOS adblock control flow is valid\n'
