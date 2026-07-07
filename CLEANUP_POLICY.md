# Cleanup Policy

This repository is part of the Mohavise adblock pipeline. Do not delete files only because they look duplicated, old, large, or generated.

## Safe cleanup rule

A file can be removed only when all of these are true:

```text
not used by a GitHub Actions workflow
not used by a build script
not documented as an output
not used by an installer or device-side process
not used as a raw URL endpoint
not kept for compatibility or fallback
not needed for future scheduled generation
```

If any item is false or unknown, keep the file.

## Required review before deletion

Before deleting any file:

1. Check `.github/workflows/` for `git add`, script calls, and output references.
2. Check `scripts/` for input and output variables.
3. Check `README.md` for documented public URLs and compatibility notes.
4. Check RouterOS installer files for referenced URLs.
5. Prepare a removal report with risk level.
6. Delete only after explicit approval.

## Current intentional files

These files are intentional and must not be removed without a full process change:

```text
adblock-domains.rsc
adblock-domains.txt
adblock-hosts.txt
install-mohavise-adblock.rsc
install-mohavise-adult-adblock.rsc
mikrotik-adblock-domains.txt
mikrotik-adblock-hosts.txt
mikrotik-adult-domains.txt
mikrotik-adult-hosts.txt
mikrotik-combined-domains.txt
mikrotik-combined-hosts.txt
safe-install-mohavise-adblock.rsc
safe-install-mohavise-adult-adblock.rsc
scripts/build-adblock.sh
.github/workflows/update-adblock-prototype.yml
```

## Notes

`adblock-hosts.txt`, `adblock-domains.txt`, and `adblock-domains.rsc` are compatibility/fallback outputs.

The `mikrotik-*` files are platform-specific category and combined outputs used for production, review, and future expansion.

The normal adblock installer and the adult installer are separate RouterOS processes. Do not merge or delete one only because the other exists.
