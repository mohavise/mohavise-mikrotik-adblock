# Mohavise MikroTik Adblock

This repository is the MikroTik child/output repo of the main Mohavise adblock core project.

It builds RouterOS-ready DNS Adlist outputs from the validated parent core lists.
Source lists, upstream changes, custom blocks, allowlists, and data validation are managed in the parent core repo:

```text
https://github.com/mohavise/mohavise-adblock-core
```

## Relationship

```text
mohavise-adblock-core
        ↓
mohavise-mikrotik-adblock
        ↓
MikroTik RouterOS DNS Adlist
```

## Daily Timing

GitHub Actions runs at `00:00 UTC`, which is `03:30 Asia/Tehran`.

MikroTik runs locally at `04:10`.

This gives time for the parent core repo to build first, then this child repo builds MikroTik-ready outputs, then RouterOS reloads them.

## Output Strategy

This repo now supports separate endpoint lists.

```text
adblock list = ads / trackers
adult list   = adult / NSFW domains
combined     = adblock + adult together
```

For normal production use, the MikroTik installer adds the two separate DNS Adlist URLs:

```text
mikrotik-adblock-hosts.txt
mikrotik-adult-hosts.txt
```

This is better than only one combined list because you can later disable, troubleshoot, or manage adblock and adult blocking separately.

## Materials / Output Files

| File | Format | Main Use |
| --- | --- | --- |
| `mikrotik-adblock-hosts.txt` | Hosts format: `0.0.0.0 domain.com` | RouterOS DNS Adlist for ads / trackers |
| `mikrotik-adult-hosts.txt` | Hosts format: `0.0.0.0 domain.com` | RouterOS DNS Adlist for adult / NSFW domains |
| `mikrotik-combined-hosts.txt` | Hosts format: `0.0.0.0 domain.com` | Optional combined RouterOS DNS Adlist |
| `mikrotik-adblock-domains.txt` | Plain domain list | Adblock category review/debug output |
| `mikrotik-adult-domains.txt` | Plain domain list | Adult category review/debug output |
| `mikrotik-combined-domains.txt` | Plain domain list | Combined review/debug output |
| `adblock-hosts.txt` | Hosts format | Compatibility combined file; kept for old installs |
| `adblock-domains.txt` | Plain domain list | Compatibility combined domain file |
| `adblock-domains.rsc` | RouterOS script format | Optional fallback using `/ip dns static` records |

Simple explanation:

```text
mikrotik-adblock-hosts.txt = main adblock DNS Adlist file
mikrotik-adult-hosts.txt   = main adult DNS Adlist file
adblock-hosts.txt          = old combined compatibility file
adblock-domains.rsc        = optional DNS static fallback
```

## Use In MikroTik

Run this once on MikroTik:

```routeros
/tool fetch url="https://raw.githubusercontent.com/mohavise/mohavise-mikrotik-adblock/main/safe-install-mohavise-adblock.rsc" dst-path=safe-install-mohavise-adblock.rsc mode=https
/import file-name=safe-install-mohavise-adblock.rsc
/file remove [find name=safe-install-mohavise-adblock.rsc]
```

The installer creates or updates:

```text
/system script     mohavise-adblock-update
/system scheduler  mohavise-adblock-daily
```

The updater adds these two RouterOS DNS Adlist URLs if they are missing:

```text
https://raw.githubusercontent.com/mohavise/mohavise-mikrotik-adblock/main/mikrotik-adblock-hosts.txt
https://raw.githubusercontent.com/mohavise/mohavise-mikrotik-adblock/main/mikrotik-adult-hosts.txt
```

Then it runs:

```routeros
/ip dns adlist reload
```

## Manual DNS Adlist Add

If you do not want to use the installer, add both URLs manually:

```routeros
/ip dns adlist add url="https://raw.githubusercontent.com/mohavise/mohavise-mikrotik-adblock/main/mikrotik-adblock-hosts.txt" ssl-verify=no
/ip dns adlist add url="https://raw.githubusercontent.com/mohavise/mohavise-mikrotik-adblock/main/mikrotik-adult-hosts.txt" ssl-verify=no
/ip dns adlist reload
```

## Files

| File | Purpose |
| --- | --- |
| `safe-install-mohavise-adblock.rsc` | Fetches, imports, and removes the installer file safely |
| `install-mohavise-adblock.rsc` | Creates the MikroTik updater script and daily scheduler |
| `scripts/build-adblock.sh` | Downloads category core lists and builds MikroTik outputs |
| `.github/workflows/update-adblock-prototype.yml` | Daily GitHub Actions build workflow |

## Build

```bash
./scripts/build-adblock.sh
```

The build script reads:

```text
core-domains.txt
core-adblock-domains.txt
core-adult-domains.txt
```

and generates MikroTik-ready combined, adblock-only, and adult-only outputs.

## Signature

Generated and managed items use this signature:

```text
managed-by=mohavise-mikrotik-adblock
project=mohavise-adlist-block
```

The signature makes future updates safer because scripts can identify only the items managed by this project.

## Update-Ready Approach

```text
Parent/core repo validates and publishes category lists.
Child repo converts category lists into MikroTik-ready outputs.
Device-side script refreshes the final output on schedule.
Managed items are marked with a clear signature.
Future changes should update managed items only, not unrelated user configuration.
```

The installer adds DNS Adlist URLs only if they are missing, then runs `/ip dns adlist reload`.
It does not delete DNS static records or unrelated adlist entries.

## Future Vision

```text
One clean parent system.
Separate category outputs.
Multiple child platform outputs.
Same timing.
Same signature style.
Safe daily updates.
Easy rollback and future category expansion.
```

Planned future categories can include malware, gambling, social media, crypto, telemetry, and other DNS/security feeds.

## Logic

```text
core-adblock-domains.txt → mikrotik-adblock-hosts.txt
core-adult-domains.txt   → mikrotik-adult-hosts.txt
core-domains.txt         → mikrotik-combined-hosts.txt + compatibility adblock-hosts.txt
```

## Cleanup Policy

Before removing any file from this repository, read `CLEANUP_POLICY.md`.

Generated outputs, compatibility files, RouterOS fallback files, installers, workflows, and scripts are intentional parts of the process. Do not delete them only because they look duplicated, old, large, or generated.
