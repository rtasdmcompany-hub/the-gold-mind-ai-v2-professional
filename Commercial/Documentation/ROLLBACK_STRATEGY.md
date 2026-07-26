# ROLLBACK_STRATEGY.md

**Phase:** 9 · Sprint 5  
**Client:** `Update-TheGoldMindProfessional.ps1`  
**Rule:** Never overwrite critical user data

---

## Before every update

1. **Configuration backup** → `backup/<timestamp>/config`  
2. **User settings backup** → included under config  
3. **Log preservation** → `backup/<timestamp>/logs`  
4. **Rollback package** → `rollback/previous/{bin,version.json,installed-manifest.json}`

User `config`, `logs`, and `backup` trees are **not** replaced by package apply. Only `bin/` (and selected manifest/readme) are updated on success.

---

## On failure

| Trigger | Action |
|---------|--------|
| Download missing | Report fail · keep current |
| Checksum mismatch | Restore previous · report rollback |
| Signature invalid | Restore previous · report rollback |
| Expand/apply error | Restore previous · report rollback |

Customer message: previous version restored; update cancelled.

---

## Restore previous version

```
rollback/previous/bin  →  InstallRoot/bin
rollback/previous/version.json → config/version.json
```

Manual restore: re-run restore logic or copy from latest `backup/<stamp>`.

---

## Uninstall interaction

Uninstall copies `backup/` aside to `%LOCALAPPDATA%\THE GOLD MIND PROFESSIONAL.backup.<stamp>` before removing the product root (unless `-KeepLogs`).

---

## Telemetry

Rollback events increment package `rollbackEvents` and appear on Admin Release Management.

---

*End of ROLLBACK_STRATEGY.md*
