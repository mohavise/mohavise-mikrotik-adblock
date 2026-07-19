# Mohavise MikroTik Adblock

RouterOS-ready DNS Adlist outputs generated from the validated parent repository:

```text
mohavise-adblock-core
        ↓
mohavise-mikrotik-adblock
        ↓
MikroTik RouterOS DNS Adlist
```

Source validation, allowlists, custom blocks, and upstream management are handled in:

```text
https://github.com/mohavise/mohavise-adblock-core
```

## Output Files

| File | Purpose |
| --- | --- |
| `mikrotik-adblock-hosts.txt` | Ads and trackers DNS Adlist |
| `mikrotik-adult-hosts.txt` | Optional adult/NSFW DNS Adlist |
| `mikrotik-combined-hosts.txt` | Combined adblock and adult list |
| `mikrotik-adblock-domains.txt` | Plain adblock domains |
| `mikrotik-adult-domains.txt` | Plain adult domains |
| `mikrotik-combined-domains.txt` | Plain combined domains |
| `adblock-hosts.txt` | Compatibility combined hosts file |
| `adblock-domains.txt` | Compatibility combined domain file |
| `adblock-domains.rsc` | Optional `/ip dns static` fallback |

## Install Normal Adblock

```routeros
/tool fetch url="https://raw.githubusercontent.com/mohavise/mohavise-mikrotik-adblock/main/safe-install-mohavise-adblock.rsc" dst-path="safe-install-mohavise-adblock.rsc" check-certificate=yes-without-crl
/import file-name="safe-install-mohavise-adblock.rsc"
/file remove [find name="safe-install-mohavise-adblock.rsc"]
```

Creates or updates:

```text
/system script     mohavise-adblock-update
/system scheduler  mohavise-adblock-daily
/ip dns adlist     mikrotik-adblock-hosts.txt URL
```

## Remove Normal Adblock

```routeros
/tool fetch url="https://raw.githubusercontent.com/mohavise/mohavise-mikrotik-adblock/main/safe-remove-mohavise-adblock.rsc" dst-path="safe-remove-mohavise-adblock.rsc" check-certificate=yes-without-crl
/import file-name="safe-remove-mohavise-adblock.rsc"
/file remove [find name="safe-remove-mohavise-adblock.rsc"]
```

The remover deletes only:

```text
/system script     mohavise-adblock-update
/system scheduler  mohavise-adblock-daily
/ip dns adlist     exact normal-adblock repository URL
```

## Install Optional Adult Adblock

```routeros
/tool fetch url="https://raw.githubusercontent.com/mohavise/mohavise-mikrotik-adblock/main/safe-install-mohavise-adult-adblock.rsc" dst-path="safe-install-mohavise-adult-adblock.rsc" check-certificate=yes-without-crl
/import file-name="safe-install-mohavise-adult-adblock.rsc"
/file remove [find name="safe-install-mohavise-adult-adblock.rsc"]
```

Creates or updates:

```text
/system script     mohavise-adult-adblock-update
/system scheduler  mohavise-adult-adblock-daily
/ip dns adlist     mikrotik-adult-hosts.txt URL
```

## Remove Optional Adult Adblock

```routeros
/tool fetch url="https://raw.githubusercontent.com/mohavise/mohavise-mikrotik-adblock/main/safe-remove-mohavise-adult-adblock.rsc" dst-path="safe-remove-mohavise-adult-adblock.rsc" check-certificate=yes-without-crl
/import file-name="safe-remove-mohavise-adult-adblock.rsc"
/file remove [find name="safe-remove-mohavise-adult-adblock.rsc"]
```

The normal and adult components are independent. Installing, updating, or removing one does not modify the other.

## Verify on MikroTik

```routeros
/ip dns adlist print where url~"mohavise-mikrotik-adblock"
/system script print where name~"mohavise.*adblock"
/system scheduler print where name~"mohavise.*adblock"
```

## Manual DNS Adlist Add

Normal adblock:

```routeros
/ip dns adlist add url="https://raw.githubusercontent.com/mohavise/mohavise-mikrotik-adblock/main/mikrotik-adblock-hosts.txt" ssl-verify=yes
/ip dns adlist reload
```

Optional adult adblock:

```routeros
/ip dns adlist add url="https://raw.githubusercontent.com/mohavise/mohavise-mikrotik-adblock/main/mikrotik-adult-hosts.txt" ssl-verify=yes
/ip dns adlist reload
```

## RouterOS Security and Safety

The safe install and safe removal wrappers perform:

```text
Remove stale temporary file
→ secure HTTPS fetch with certificate verification
→ RouterOS verbose dry-run import
→ real import
→ remove temporary file
```

The installed updater scripts:

```text
Add the managed DNS Adlist URL if missing
→ force ssl-verify=yes on existing managed entries
→ reload DNS Adlist
→ log success or failure
```

The removal scripts are idempotent and remove only exact project-owned scheduler names, script names, and repository URLs. They do not remove unrelated DNS Adlist entries or DNS static records.

RouterOS uses its built-in certificate trust store for secure fetch and DNS Adlist certificate verification.

## Repository Validation

`scripts/build-adblock.sh` completes all checks before replacing any published output.

Checks include:

- HTTPS source download failure handling, retries, and timeouts
- lowercase and whitespace normalization
- duplicate removal and deterministic sorting
- minimum counts for combined, adblock, and adult lists
- strict domain syntax validation
- rejection of IP addresses and malformed records
- confirmation that adblock and adult entries exist in the combined list
- protection against an entry-count reduction greater than 20%
- deterministic output generation without timestamps

Current minimums:

| List | Minimum domains |
| --- | ---: |
| Combined | 10,000 |
| Adblock | 10,000 |
| Adult | 1,000 |

If any validation fails, the workflow stops before changing the published files.

## Daily Timing

| Process | Time |
| --- | --- |
| GitHub Actions build | `00:00 UTC` |
| Normal MikroTik adblock | `04:10` local router time |
| Optional adult adblock | `04:15` local router time |

Both updater scripts and schedulers use:

```routeros
policy=read,write,test
```

The GitHub workflow prevents overlapping runs, has a 15-minute timeout, and rebases before pushing to reduce update conflicts.

## Repository Files

| File | Purpose |
| --- | --- |
| `safe-install-mohavise-adblock.rsc` | Secure normal-adblock installer wrapper |
| `install-mohavise-adblock.rsc` | Creates normal updater and scheduler |
| `safe-remove-mohavise-adblock.rsc` | Secure normal-adblock removal wrapper |
| `remove-mohavise-adblock.rsc` | Removes only normal managed resources |
| `safe-install-mohavise-adult-adblock.rsc` | Secure optional-adult installer wrapper |
| `install-mohavise-adult-adblock.rsc` | Creates adult updater and scheduler |
| `safe-remove-mohavise-adult-adblock.rsc` | Secure optional-adult removal wrapper |
| `remove-mohavise-adult-adblock.rsc` | Removes only adult managed resources |
| `scripts/build-adblock.sh` | Builds and validates RouterOS outputs |
| `.github/workflows/update-adblock-prototype.yml` | Daily GitHub Actions workflow |

## Build

```bash
./scripts/build-adblock.sh
```

The build reads:

```text
core-domains.txt
core-adblock-domains.txt
core-adult-domains.txt
```

and produces separate adblock, adult, and combined RouterOS outputs.

## Managed Signature

```text
managed-by=mohavise-mikrotik-adblock
project=mohavise-adlist-block
component=adblock
component=adult
```

## Cleanup Policy

Before removing repository files, read `CLEANUP_POLICY.md`. Generated outputs, compatibility files, fallback files, installers, removers, workflows, and scripts are intentional parts of the project.
