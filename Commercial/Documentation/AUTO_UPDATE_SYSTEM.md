# AUTO_UPDATE_SYSTEM.md

**Phase:** 9 · Sprint 5  
**Client:** `Update-TheGoldMindProfessional.ps1`  
**APIs:** `/api/releases/check` · `/api/releases/download/[id]` · `/api/releases/report`

---

## Pipeline

```
Version Check
  → Update Notification (console + portal)
  → Release Notes Viewer
  → Background Download (BITS / IWR)
  → Download Progress
  → SHA-256 Checksum Validation
  → Digital Signature Verification (when required)
  → Package Verification
  → Safe Installation (bin only)
  → Telemetry Report
  → Restart Prompt
  → Rollback on any failure
```

---

## Client usage

```powershell
# Check only
.\Update-TheGoldMindProfessional.ps1 -PortalBase https://portal.example -Channel stable

# Apply after verification
.\Update-TheGoldMindProfessional.ps1 -PortalBase https://portal.example -Channel stable -Apply -CustomerEmail you@company.com
```

Env: `UPDATE_REPORT_SECRET` (must match portal in production).

---

## Fail-closed rule

If **any** of the following fail:

- Non-HTTPS package URL (non-localhost)
- Checksum mismatch
- Required Authenticode invalid
- Extract / apply error

Then:

1. **Cancel** installation  
2. **Restore** `rollback/previous`  
3. **Inform** customer (console)  
4. **Report** `rollback` / `fail` to portal  

Previous version and user `config` / `logs` remain intact.

---

## Channels

| Channel | Purpose |
|---------|---------|
| `stable` | Production customers |
| `rc` | Release candidates |
| `development` | Internal / nightly |

---

## Portal pairing

| Surface | Role |
|---------|------|
| `/portal/updates` | Version check UI · notes · checksum · signature |
| `/portal/downloads` | Installer download · history · compatibility |
| `/portal/admin/releases` | Success rate · rollbacks · events |

---

*End of AUTO_UPDATE_SYSTEM.md*
