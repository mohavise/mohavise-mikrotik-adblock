#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"

CORE_URL="${CORE_URL:-https://raw.githubusercontent.com/mohavise/mohavise-adblock-core/main/core-domains.txt}"
CORE_ADBLOCK_URL="${CORE_ADBLOCK_URL:-https://raw.githubusercontent.com/mohavise/mohavise-adblock-core/main/core-adblock-domains.txt}"
CORE_ADULT_URL="${CORE_ADULT_URL:-https://raw.githubusercontent.com/mohavise/mohavise-adblock-core/main/core-adult-domains.txt}"

DOMAIN_OUTPUT_FILE="${DOMAIN_OUTPUT_FILE:-$REPO_DIR/adblock-domains.txt}"
HOST_OUTPUT_FILE="${HOST_OUTPUT_FILE:-$REPO_DIR/adblock-hosts.txt}"
RSC_OUTPUT_FILE="${RSC_OUTPUT_FILE:-$REPO_DIR/adblock-domains.rsc}"

MIKROTIK_COMBINED_DOMAINS_FILE="${MIKROTIK_COMBINED_DOMAINS_FILE:-$REPO_DIR/mikrotik-combined-domains.txt}"
MIKROTIK_ADBLOCK_DOMAINS_FILE="${MIKROTIK_ADBLOCK_DOMAINS_FILE:-$REPO_DIR/mikrotik-adblock-domains.txt}"
MIKROTIK_ADULT_DOMAINS_FILE="${MIKROTIK_ADULT_DOMAINS_FILE:-$REPO_DIR/mikrotik-adult-domains.txt}"
MIKROTIK_COMBINED_HOSTS_FILE="${MIKROTIK_COMBINED_HOSTS_FILE:-$REPO_DIR/mikrotik-combined-hosts.txt}"
MIKROTIK_ADBLOCK_HOSTS_FILE="${MIKROTIK_ADBLOCK_HOSTS_FILE:-$REPO_DIR/mikrotik-adblock-hosts.txt}"
MIKROTIK_ADULT_HOSTS_FILE="${MIKROTIK_ADULT_HOSTS_FILE:-$REPO_DIR/mikrotik-adult-hosts.txt}"

LIST_NAME="${LIST_NAME:-mohavise-adblock}"
MIN_DOMAIN_COUNT="${MIN_DOMAIN_COUNT:-10000}"
MIN_ADBLOCK_DOMAIN_COUNT="${MIN_ADBLOCK_DOMAIN_COUNT:-10000}"
MIN_ADULT_DOMAIN_COUNT="${MIN_ADULT_DOMAIN_COUNT:-1000}"

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
        awk '
            {
                line = tolower($0)
                gsub(/^[[:space:]]+|[[:space:]]+$/, "", line)
                if (line != "" && line !~ /^#/) print line
            }
        ' |
        sort -u > "$output_file"
}

validate_min_count() {
    local file="$1"
    local minimum="$2"
    local label="$3"
    local count

    count="$(wc -l < "$file" | tr -d ' ')"
    if (( count < minimum )); then
        echo "$label domain count $count is below minimum $minimum; refusing to overwrite outputs." >&2
        exit 1
    fi

    echo "$count"
}

write_hosts_file() {
    local input_file="$1"
    local output_file="$2"

    awk '{ print "0.0.0.0 " $0 }' "$input_file" > "$output_file"
}

fetch_domains "$CORE_URL" "$TMP_DIR/combined.txt"
fetch_domains "$CORE_ADBLOCK_URL" "$TMP_DIR/adblock.txt"
fetch_domains "$CORE_ADULT_URL" "$TMP_DIR/adult.txt"

combined_count="$(validate_min_count "$TMP_DIR/combined.txt" "$MIN_DOMAIN_COUNT" "Combined core")"
adblock_count="$(validate_min_count "$TMP_DIR/adblock.txt" "$MIN_ADBLOCK_DOMAIN_COUNT" "Adblock core")"
adult_count="$(validate_min_count "$TMP_DIR/adult.txt" "$MIN_ADULT_DOMAIN_COUNT" "Adult core")"

cp "$TMP_DIR/combined.txt" "$DOMAIN_OUTPUT_FILE"
cp "$TMP_DIR/combined.txt" "$MIKROTIK_COMBINED_DOMAINS_FILE"
cp "$TMP_DIR/adblock.txt" "$MIKROTIK_ADBLOCK_DOMAINS_FILE"
cp "$TMP_DIR/adult.txt" "$MIKROTIK_ADULT_DOMAINS_FILE"

write_hosts_file "$TMP_DIR/combined.txt" "$HOST_OUTPUT_FILE"
write_hosts_file "$TMP_DIR/combined.txt" "$MIKROTIK_COMBINED_HOSTS_FILE"
write_hosts_file "$TMP_DIR/adblock.txt" "$MIKROTIK_ADBLOCK_HOSTS_FILE"
write_hosts_file "$TMP_DIR/adult.txt" "$MIKROTIK_ADULT_HOSTS_FILE"

{
    echo "# managed-by=mohavise-mikrotik-adblock"
    echo "# project=mohavise-adlist-block"
    echo "# do-not-edit-manually"
    echo "# generated-at=$(date -u '+%Y-%m-%d %H:%M:%S UTC')"
    echo '/ip dns static remove [/ip dns static find comment~"managed-by=mohavise-mikrotik-adblock"]'
    awk -v list_name="$LIST_NAME" '{
        printf ":do { /ip dns static add name=%s address=0.0.0.0 type=A comment=\"managed-by=mohavise-mikrotik-adblock list=%s\" } on-error={}\n", $0, list_name
    }' "$TMP_DIR/combined.txt"
} > "$RSC_OUTPUT_FILE"

echo "Generated combined MikroTik outputs with $combined_count blocked domains."
echo "Generated adblock MikroTik outputs with $adblock_count blocked domains."
echo "Generated adult MikroTik outputs with $adult_count blocked domains."
