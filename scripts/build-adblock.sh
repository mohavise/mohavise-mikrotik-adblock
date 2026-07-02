#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"

CORE_URL="${CORE_URL:-https://raw.githubusercontent.com/mohavise/mohavise-adblock-core/main/core-domains.txt}"
DOMAIN_OUTPUT_FILE="${DOMAIN_OUTPUT_FILE:-$REPO_DIR/adblock-domains.txt}"
HOST_OUTPUT_FILE="${HOST_OUTPUT_FILE:-$REPO_DIR/adblock-hosts.txt}"
RSC_OUTPUT_FILE="${RSC_OUTPUT_FILE:-$REPO_DIR/adblock-domains.rsc}"
LIST_NAME="${LIST_NAME:-mohavise-adblock}"
MIN_DOMAIN_COUNT="${MIN_DOMAIN_COUNT:-10000}"

TMP_FILE="$(mktemp)"
trap 'rm -f "$TMP_FILE"' EXIT

if [[ -f "$CORE_URL" ]]; then
    cat "$CORE_URL"
else
    curl -fsSL "$CORE_URL"
fi |
    awk '
        {
            line = tolower($0)
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", line)
            if (line != "" && line !~ /^#/) print line
        }
    ' |
    sort -u > "$TMP_FILE"

domain_count="$(wc -l < "$TMP_FILE" | tr -d ' ')"
if (( domain_count < MIN_DOMAIN_COUNT )); then
    echo "Core domain count $domain_count is below minimum $MIN_DOMAIN_COUNT; refusing to overwrite outputs." >&2
    exit 1
fi

cp "$TMP_FILE" "$DOMAIN_OUTPUT_FILE"
awk '{ print "0.0.0.0 " $0 }' "$TMP_FILE" > "$HOST_OUTPUT_FILE"

{
    echo "# managed-by=mohavise-mikrotik-adblock"
    echo "# project=mohavise-adlist-block"
    echo "# do-not-edit-manually"
    echo "# generated-at=$(date -u '+%Y-%m-%d %H:%M:%S UTC')"
    echo '/ip dns static remove [/ip dns static find comment~"managed-by=mohavise-mikrotik-adblock"]'
    awk -v list_name="$LIST_NAME" '{
        printf ":do { /ip dns static add name=%s address=0.0.0.0 type=A comment=\"managed-by=mohavise-mikrotik-adblock list=%s\" } on-error={}\n", $0, list_name
    }' "$TMP_FILE"
} > "$RSC_OUTPUT_FILE"

echo "Generated $DOMAIN_OUTPUT_FILE, $HOST_OUTPUT_FILE, and $RSC_OUTPUT_FILE with $domain_count blocked domains."
