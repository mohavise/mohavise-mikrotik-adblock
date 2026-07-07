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

MikroTik adblock runs locally at `04:10`.

Optional MikroTik adult adblock runs locally at `04:15` only if the adult installer is imported.

This gives time for the parent core repo to build first, then this child repo builds MikroTik-ready outputs, then RouterOS reloads the selected DNS Adlist endpoints.

## Output Strategy

This repo supports separate endpoint lists.

```text
adblock list = ads / trackers
adult list   = adult / NSFW domains
combined     = adblock + adult together
```

The important design rule is:

```text
separate endpoint
separate installer
separate RouterOS script
separate RouterOS scheduler
```

The normal adblock process does not manage the adult process.

## Materials / Output Files

| File | Format | Main Use |
| --- | --- | --- |
| `mikrotik-adblock-hosts.txt` | Hosts format: `0.0.0.0 domain.com` | RouterOS DNS Adlist for ads / trackers |
| `mikrotik-adult-hosts.txt` | Hosts format: `0.0.0.0 domain.com` | Optional RouterOS DNS Adlist for adult / NSFW domains |
| `mikrotik-combined-hosts.txt` | Hosts format: `0.0.0.0 domain.com` | Optional combined RouterOS DNS Adlist |
| `mikrotik-adblock-domains.txt` | Plain domain list | Adblock category review/debug output |
| `mikrotik-adult-domains.txt` | Plain domain list | Adult category review/debug output |
| `mikrotik-combined-domains.txt` | Plain domain list | Combined review/debug output |
| `adblock-hosts.txt` | Hosts format | Compatibility combined file; kept for old installs |
| `adblock-domains.txt` | Plain domain list | Compatibility combined domain file |
| `adblock-domains.rsc` | RouterOS script format | Optional fallback using `/ip dns static` records |

Simple explanation:

```text
mikrotik-adblock-hosts.txt = main adblock DNS Adlist endpoint
mikrotik-adult-hosts.txt   = optional adult DNS Adlist endpoint
adblock-hosts.txt          = old combined compatibility file
adblock-domains.rsc        = optional DNS static fallback
```

## MikroTik Install Modes

This repo has two separate MikroTik install processes.

### Normal adblock install

This installs only the normal ad/tracker DNS Adlist process.

```routeros
/tool fetch url="https://raw.githubusercontent.com/mohavise/mohavise-mikrotik-adblock/main/safe-install-mohavise-adblock.rsc" dst-path=safe-install-mohavise-adblock.rsc mode=https
/import file-name=safe-install-mohavise-adblock.rsc
/file remove [find name=safe-install-mohavise-adblock.rsc]
```

It creates or updates:

```text
/system script     mohavise-adblock-update
/system scheduler  mohavise-adblock-daily
```

Endpoint:

```text
https://raw.githubusercontent.com/mohavise/mohavise-mikrotik-adblock/main/mikrotik-adblock-hosts.txt
```

### Optional adult install

This installs only the adult/NSFW DNS Adlist process.

Run this only if you want adult/NSFW blocking on MikroTik:

```routeros
/tool fetch url="https://raw.githubusercontent.com/mohavise/mohavise-mikrotik-adblock/main/safe-install-mohavise-adult-adblock.rsc" dst-path=safe-install-mohavise-adult-adblock.rsc mode=https
/import file-name=safe-install-mohavise-adult-adblock.rsc
/file remove [find name=safe-install-mohavise-adult-adblock.rsc]
```

It creates or updates:

```text
/system script     mohavise-adult-adblock-update
/system scheduler  mohavise-adult-adblock-daily
```

Endpoint:

```text
https://raw.githubusercontent.com/mohavise/mohavise-mikrotik-adblock/main/mikrotik-adult-hosts.txt
```

If the adult installer is not imported, the adult script and scheduler do not exist. Running the normal adblock updater will not add the adult list.

## Manual DNS Adlist Add

If you do not want to use installers, add only the endpoint you need.

Normal adblock:

```routeros
/ip dns adlist add url="https://raw.githubusercontent.com/mohavise/mohavise-mikrotik-adblock/main/mikrotik-adblock-hosts.txt" ssl-verify=no
/ip dns adlist reload
```

Optional adult:

```routeros
/ip dns adlist add url="https://raw.githubusercontent.com/mohavise/mohavise-mikrotik-adblock/main/mikrotik-adult-hosts.txt" ssl-verify=no
/ip dns adlist reload
```

## Remove Adult Process From MikroTik

If adult/NSFW blocking is no longer needed, remove only the adult process:

```routeros
/system scheduler remove [find name="mohavise-adult-adblock-daily"]
/system script remove [find name="mohavise-adult-adblock-update"]
/ip dns adlist remove [find url="https://raw.githubusercontent.com/mohavise/mohavise-mikrotik-adblock/main/mikrotik-adult-hosts.txt"]
/ip dns adlist reload
```

The normal adblock process stays active and will not recreate the adult process.

## Files

| File | Purpose |
| --- | --- |
| `safe-install-mohavise-adblock.rsc` | Safe installer for normal ad/tracker DNS Adlist |
| `install-mohavise-adblock.rsc` | Creates normal adblock updater script and scheduler |
| `safe-install-mohavise-adult-adblock.rsc` | Safe installer for optional adult/NSFW DNS Adlist |
| `install-mohavise-adult-adblock.rsc` | Creates optional adult updater script and scheduler |
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

RouterOS device-side components also include component markers:

```text
component=adblock
component=adult
```

The signature makes future updates safer because scripts can identify only the items managed by this project.

## Update-Ready Approach

```text
Parent/core repo validates and publishes category lists.
Child repo converts category lists into MikroTik-ready outputs.
Normal adblock and adult adblock are separate RouterOS processes.
Each process has its own script, scheduler, and endpoint.
Adult blocking is optional on the router.
Managed items are marked with a clear signature.
Future changes should update managed items only, not unrelated user configuration.
```

The normal installer adds the adblock DNS Adlist URL only if it is missing, then runs `/ip dns adlist reload`.
The adult installer adds the adult DNS Adlist URL only if it is missing, then runs `/ip dns adlist reload`.

Neither installer deletes DNS static records, unrelated adlist entries, or the other component.

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
