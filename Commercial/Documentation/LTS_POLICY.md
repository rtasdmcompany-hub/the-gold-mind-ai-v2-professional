# LTS_POLICY.md

**Product:** THE GOLD MIND PROFESSIONAL / MARKET  
**Core rule:** Trading Engine remains frozen unless a separately certified Core program is opened.

## Versioning strategy

- **Core:** SemVer aligned to certified tags (e.g. 2.0.x). Commercial packaging may bump portal/installer versions independently (`0.9.x-phase10`).
- **Channels:** `development` · `rc` · `stable`

## Release schedule

| Cadence | Scope |
|---------|--------|
| Monthly (or as needed) | Portal/security patches |
| Quarterly | Controlled feature commercial releases (no Core behaviour change) |
| Ad-hoc | Security hotfixes within 72h of confirmed Critical |

## Patch policy

- Commercial / portal / installer patches only by default.
- Core patches require new SHA certification + board approval.

## Security update policy

- Rotate secrets per dual-read strategy.
- Dependency CVEs: triage within 7 days; Critical within 48h.

## Hotfix procedure

1. Reproduce · classify severity.  
2. Patch commercial layer only unless Core emergency program authorized.  
3. Smoke test · deploy · notify customers.  
4. Postmortem within 48h.

## End-of-life policy

- Announce EOL ≥ 90 days for major commercial editions.
- Market listings follow MetaQuotes rules independently.
- Core LTS: supported while commercial SKU is active; SHA archive retained.
