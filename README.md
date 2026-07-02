# Mohavise MikroTik Adblock Prototype

This project builds MikroTik DNS Adlist outputs from the shared Mohavise adblock core list.

Source and allowlist changes are managed in the core repo:

```text
https://github.com/mohavise/mohavise-adblock-core
```

## Daily Timing

GitHub Actions runs at `23:30 UTC`, which is `03:00 Asia/Tehran`.

MikroTik runs locally at `04:10`.

## Files

| File | Purpose |
| --- | --- |
| `safe-install-mohavise-adblock.rsc` | Fetches, imports, and removes the installer file |
| `adblock-domains.txt` | Generated plain domain list |
| `adblock-hosts.txt` | Generated hosts-format file used by RouterOS DNS Adlist |
| `adblock-domains.rsc` | Generated DNS static import fallback |
| `install-mohavise-adblock.rsc` | Creates MikroTik adlist updater script and daily scheduler |
| `scripts/build-adblock.sh` | Downloads the core list and builds the final MikroTik files |

## Build

```bash
./scripts/build-adblock.sh
```

## Marker

All generated RouterOS items use this marker:

```text
managed-by=mohavise-mikrotik-adblock
```

This makes future updates safer because scripts can find only the items managed by this project.

The installer adds the RouterOS DNS Adlist URL only if it is missing, then runs `/ip dns adlist reload`.
It does not delete DNS static records or adlist entries.

## Install

Run this once on MikroTik:

```routeros
/tool fetch url="https://raw.githubusercontent.com/mohavise/mohavise-mikrotik-adblock/main/safe-install-mohavise-adblock.rsc" dst-path=safe-install-mohavise-adblock.rsc mode=https
/import file-name=safe-install-mohavise-adblock.rsc
/file remove [find name=safe-install-mohavise-adblock.rsc]
```
