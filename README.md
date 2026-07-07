# Mohavise MikroTik Adblock

MikroTik child/output repo for the Mohavise adblock system.

It converts the validated core domain list into one RouterOS DNS Adlist hosts file.

## Source

```text
https://github.com/mohavise/mohavise-adblock-core
```

## Output

```text
mikrotik-adblock-hosts.txt
```

Raw URL:

```text
https://raw.githubusercontent.com/mohavise/mohavise-mikrotik-adblock/main/mikrotik-adblock-hosts.txt
```

## Install on MikroTik

```routeros
/tool fetch url="https://raw.githubusercontent.com/mohavise/mohavise-mikrotik-adblock/main/safe-install-mohavise-adblock.rsc" dst-path=safe-install-mohavise-adblock.rsc mode=https
/import file-name=safe-install-mohavise-adblock.rsc
/file remove [find name=safe-install-mohavise-adblock.rsc]
```

## Manual add

```routeros
/ip dns adlist add url="https://raw.githubusercontent.com/mohavise/mohavise-mikrotik-adblock/main/mikrotik-adblock-hosts.txt" ssl-verify=no
/ip dns adlist reload
```

## Files

```text
safe-install-mohavise-adblock.rsc
install-mohavise-adblock.rsc
scripts/build-adblock.sh
.github/workflows/update-adblock-prototype.yml
mikrotik-adblock-hosts.txt
```
