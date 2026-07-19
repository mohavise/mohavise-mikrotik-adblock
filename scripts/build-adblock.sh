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
MAX_DROP_PERCENT="${MAX_DROP_PERCENT:-20}"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

fetch_domains() {
    local source_url="$1"
    local output_file="$2"

    if [[ -f "$source_url" ]]; then
        cat -- "$source_url"
    else
        curl --fail --silent --show-error --location \
            --retry 3 --retry-delay 2 --connect-timeout 20 --max-time 180 \
            "$source_url"
    fi |
        awk '
            {
                line = tolower($0)
                sub(/\r$/, "", line)
                gsub(/^[[:space:]]+|[[:space:]]+$/, "", line)
                sub(/\.$/, "", line)
                if (line != "" && line !~ /^#/) print line
            }
        ' |
        LC_ALL=C sort -u > "$output_file"
}

validate_domains() {
    local file="$1"
    local minimum="$2"
    local label="$3"

    python3 - "$file" "$minimum" "$label" <<'PY'
import ipaddress
import pathlib
import re
import sys

path = pathlib.Path(sys.argv[1])
minimum = int(sys.argv[2])
label = sys.argv[3]
lines = path.read_text(encoding="utf-8").splitlines()

if len(lines) < minimum:
    raise SystemExit(f"{label}: {len(lines)} domains is below minimum {minimum}")

label_re = re.compile(r"^[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?$")
seen = set()
for number, domain in enumerate(lines, 1):
    if domain != domain.strip() or domain != domain.lower():
        raise SystemExit(f"{label}: non-normalized entry at line {number}: {domain!r}")
    if domain in seen:
        raise SystemExit(f"{label}: duplicate entry at line {number}: {domain}")
    seen.add(domain)
    if len(domain) > 253 or "." not in domain:
        raise SystemExit(f"{label}: invalid domain at line {number}: {domain}")
    try:
        ipaddress.ip_address(domain)
    except ValueError:
        pass
    else:
        raise SystemExit(f"{label}: IP address found at line {number}: {domain}")
    if any(not label_re.fullmatch(part) for part in domain.split(".")):
        raise SystemExit(f"{label}: invalid domain at line {number}: {domain}")

print(len(lines))
PY
}

validate_drop() {
    local new_file="$1"
    local old_file="$2"
    local label="$3"

    [[ -f "$old_file" ]] || return 0

    local new_count old_count minimum_allowed
    new_count="$(wc -l < "$new_file" | tr -d ' ')"
    old_count="$(wc -l < "$old_file" | tr -d ' ')"
    (( old_count > 0 )) || return 0

    minimum_allowed=$(( old_count * (100 - MAX_DROP_PERCENT) / 100 ))
    if (( new_count < minimum_allowed )); then
        echo "$label: count dropped from $old_count to $new_count (more than ${MAX_DROP_PERCENT}%); refusing update." >&2
        exit 1
    fi
}

validate_subset() {
    local child_file="$1"
    local combined_file="$2"
    local label="$3"

    if comm -23 "$child_file" "$combined_file" | grep -q .; then
        echo "$label contains domains missing from combined core; refusing update." >&2
        comm -23 "$child_file" "$combined_file" | head -20 >&2
        exit 1
    fi
}

write_hosts_file() {
    local input_file="$1"
    local output_file="$2"
    awk '{ print "0.0.0.0 " $0 }' "$input_file" > "$output_file"
}

fetch_domains "$CORE_URL" "$TMP_DIR/combined.txt"
fetch_domains "$CORE_ADBLOCK_URL" "$TMP_DIR/adblock.txt"
fetch_domains "$CORE_ADULT_URL" "$TMP_DIR/adult.txt"

combined_count="$(validate_domains "$TMP_DIR/combined.txt" "$MIN_DOMAIN_COUNT" "Combined core")"
adblock_count="$(validate_domains "$TMP_DIR/adblock.txt" "$MIN_ADBLOCK_DOMAIN_COUNT" "Adblock core")"
adult_count="$(validate_domains "$TMP_DIR/adult.txt" "$MIN_ADULT_DOMAIN_COUNT" "Adult core")"

validate_subset "$TMP_DIR/adblock.txt" "$TMP_DIR/combined.txt" "Adblock core"
validate_subset "$TMP_DIR/adult.txt" "$TMP_DIR/combined.txt" "Adult core"

validate_drop "$TMP_DIR/combined.txt" "$MIKROTIK_COMBINED_DOMAINS_FILE" "Combined core"
validate_drop "$TMP_DIR/adblock.txt" "$MIKROTIK_ADBLOCK_DOMAINS_FILE" "Adblock core"
validate_drop "$TMP_DIR/adult.txt" "$MIKROTIK_ADULT_DOMAINS_FILE" "Adult core"

# All validation is complete before any published output is replaced.
cp -- "$TMP_DIR/combined.txt" "$DOMAIN_OUTPUT_FILE"
cp -- "$TMP_DIR/combined.txt" "$MIKROTIK_COMBINED_DOMAINS_FILE"
cp -- "$TMP_DIR/adblock.txt" "$MIKROTIK_ADBLOCK_DOMAINS_FILE"
cp -- "$TMP_DIR/adult.txt" "$MIKROTIK_ADULT_DOMAINS_FILE"

write_hosts_file "$TMP_DIR/combined.txt" "$HOST_OUTPUT_FILE"
write_hosts_file "$TMP_DIR/combined.txt" "$MIKROTIK_COMBINED_HOSTS_FILE"
write_hosts_file "$TMP_DIR/adblock.txt" "$MIKROTIK_ADBLOCK_HOSTS_FILE"
write_hosts_file "$TMP_DIR/adult.txt" "$MIKROTIK_ADULT_HOSTS_FILE"

{
    echo "# managed-by=mohavise-mikrotik-adblock"
    echo "# project=mohavise-adlist-block"
    echo "# do-not-edit-manually"
    echo '/ip dns static remove [/ip dns static find comment~"managed-by=mohavise-mikrotik-adblock"]'
    awk -v list_name="$LIST_NAME" '{
        printf ":do { /ip dns static add name=%s address=0.0.0.0 type=A comment=\"managed-by=mohavise-mikrotik-adblock list=%s\" } on-error={}\n", $0, list_name
    }' "$TMP_DIR/combined.txt"
} > "$RSC_OUTPUT_FILE"

echo "Generated combined MikroTik outputs with $combined_count blocked domains."
echo "Generated adblock MikroTik outputs with $adblock_count blocked domains."
echo "Generated adult MikroTik outputs with $adult_count blocked domains."
