#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"

CORE_URL="${CORE_URL:-https://raw.githubusercontent.com/mohavise/mohavise-adblock-core/main/core-adblock-domains.txt}"
HOST_OUTPUT_FILE="${HOST_OUTPUT_FILE:-$REPO_DIR/mikrotik-adblock-hosts.txt}"
MIN_DOMAIN_COUNT="${MIN_DOMAIN_COUNT:-10000}"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

fetch_domains() {
    local source_url="$1"
    local output_file="$2"

    if [[ -f "$source_url" ]]; then
        cat "$source_url"
    else
        curl -fsSL "$source_url"
    fi |
        awk '{
            line = tolower($0)
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", line)
            if (line != "" && line !~ /^#/) print line
        }' |
        sort -u > "$output_file"
}

fetch_domains "$CORE_URL" "$TMP_DIR/domains.txt"

count="$(wc -l < "$TMP_DIR/domains.txt" | tr -d ' ')"
if (( count < MIN_DOMAIN_COUNT )); then
    echo "Domain count $count is below minimum $MIN_DOMAIN_COUNT; refusing to overwrite output." >&2
    exit 1
fi

awk '{ print "0.0.0.0 " $0 }' "$TMP_DIR/domains.txt" > "$HOST_OUTPUT_FILE"

echo "Generated MikroTik DNS Adlist output with $count blocked domains."
