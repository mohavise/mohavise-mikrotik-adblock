# Mohavise MikroTik Adblock Prototype

This prototype builds a MikroTik DNS static block file every day from upstream adblock domain lists.

The first source is HaGeZi `light.txt`, which is a conservative starting point for MikroTik routers.
After testing, you can change `sources.txt` to HaGeZi `multi.txt` or `pro.txt` for stronger blocking.

## Daily Timing

GitHub Actions runs at `23:30 UTC`, which is `03:00 Asia/Tehran`.

MikroTik runs locally at `04:10`.

## Files

| File | Purpose |
| --- | --- |
| `adblock-domains.txt` | Generated plain domain list |
| `adblock-domains.rsc` | Generated final MikroTik block file |
| `install-mohavise-adblock.rsc` | Creates MikroTik script and daily scheduler |
| `config/sources.txt` | Upstream blocklist URLs |
| `config/allowlist-core.txt` | Domains that must not be blocked |
| `config/blocklist-custom.txt` | Your own blocked domains |
| `scripts/build-adblock.ps1` | Builds the final MikroTik files |

## Marker

All generated RouterOS items use this marker:

```text
managed-by=mohavise-mikrotik-adblock
```

This makes future updates safer because scripts can find only the items managed by this project.
