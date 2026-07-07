# Mohavise MikroTik Adblock

This repository is the MikroTik child/output repo of the main Mohavise adblock core project.

It builds RouterOS-ready DNS Adlist outputs from the shared core domain list.
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

## Materials / Output Files

This repo generates three domain-related files from the same core list. They contain the same blocking material, but each one is prepared for a different MikroTik use case.

| File | Format | Main Use |
| --- | --- | --- |
| `adblock-domains.txt` | Plain domain list | Clean base output for review, debugging, and future converters |
| `adblock-hosts.txt` | Hosts format: `0.0.0.0 domain.com` | Main file used by MikroTik RouterOS DNS Adlist |
| `adblock-domains.rsc` | RouterOS script format | Fallback import method using `/ip dns static` records |

Simple explanation:

```text
adblock-domains.txt  = clean domain output
adblock-hosts.txt    = main MikroTik DNS Adlist file
adblock-domains.rsc  = RouterOS DNS static fallback script
```

For normal MikroTik RouterOS v7 DNS Adlist usage, use `adblock-hosts.txt`.

The `.rsc` file is optional and should be used only when DNS Adlist is not suitable or a DNS static fallback is needed.

The parent repo is responsible for cleaning and validating the data before this repo builds the MikroTik outputs.

## Use In MikroTik

Run this once on MikroTik:

```routeros
/tool fetch url="https://raw.githubusercontent.com/mohavise/mohavise-mikrotik-adblock/main/safe-install-mohavise-adblock.rsc" dst-path=safe-install-mohavise-adblock.rsc mode=https
/import file-name=safe-install-mohavise-adblock.rsc
/file remove [find name=safe-install-mohavise-adblock.rsc]
```

The installer creates or updates a RouterOS script and scheduler. The scheduler refreshes the DNS Adlist daily.

## Files

| File | Purpose |
| --- | --- |
| `safe-install-mohavise-adblock.rsc` | Fetches, imports, and removes the installer file |
| `install-mohavise-adblock.rsc` | Creates MikroTik adlist updater script and daily scheduler |
| `adblock-domains.txt` | Generated plain domain list |
| `adblock-hosts.txt` | Generated hosts-format file used by RouterOS DNS Adlist |
| `adblock-domains.rsc` | Generated DNS static import fallback |
| `scripts/build-adblock.sh` | Downloads the core list and builds the final MikroTik files |

## Build

```bash
./scripts/build-adblock.sh
```

## Signature

Generated items use this signature:

```text
managed-by=mohavise-mikrotik-adblock
project=mohavise-adlist-block
```

The signature makes future updates safer because scripts can identify only the items managed by this project.

## Update-Ready Approach

```text
Parent/core repo validates and publishes the canonical list.
Child repo converts the canonical list into MikroTik-ready outputs.
Device-side script refreshes the final output on schedule.
Managed items are marked with a clear signature.
Future changes should update managed items only, not unrelated user configuration.
```

The installer adds the RouterOS DNS Adlist URL only if it is missing, then runs `/ip dns adlist reload`.
It does not delete DNS static records or unrelated adlist entries.

## Future Vision

```text
One clean parent list.
Multiple child outputs.
Same structure.
Same timing.
Same signature style.
Safe daily updates.
Easy rollback and future platform expansion.
```

Planned child/output targets can include MikroTik, Pi-hole, FortiGate, and other DNS/security platforms that can consume domain feeds.

## Logic

```text
mohavise-adblock-core/core-domains.txt = validated canonical source
mohavise-mikrotik-adblock/adblock-hosts.txt = MikroTik DNS Adlist output
mohavise-mikrotik-adblock/adblock-domains.rsc = MikroTik DNS static fallback
```
