# UPDATE_SECURITY.md

**Phase:** 9 · Sprint 5  
**Principle:** Every update must be **Safe · Verified · Recoverable · Secure**

---

## Controls

| Control | Implementation |
|---------|----------------|
| Package integrity | ZIP magic check + SHA-256 of full artifact |
| Checksum | Client compares `Get-FileHash` to API `sha256` |
| Digital signature | Authenticode when `signatureRequired=true` |
| Secure download | HTTPS-only (localhost exception for lab) |
| Update authorization | Report API secret · portal session for admin |
| Tamper detection | Hash mismatch → cancel + rollback |
| Failed update recovery | `rollback/previous` restore |
| HTTPS gate (server) | Download route rejects non-HTTPS in production |

---

## Public updater endpoints

| Route | Auth |
|-------|------|
| `GET /api/releases/check` | Public (optional session for email tagging) |
| `GET /api/releases/download/[id]` | Public (download counted; prefer logged-in portal) |
| `POST /api/releases/report` | `x-tgm-update-secret` / Bearer `UPDATE_REPORT_SECRET` |

Middleware allows these paths without Customer Portal login so the desktop updater can operate.

---

## Fail-closed customer promise

```
IF verification fails THEN
  Cancel installation
  Keep previous version
  Inform the customer
  Report rollback/fail telemetry
END
```

No update may change Trading Engine behavior without explicit executive approval (`coreFrozen` + Owner Core tag process).

---

## Production checklist

- [ ] `UPDATE_REPORT_SECRET` set  
- [ ] Public Stable packages Authenticode-signed (`signatureRequired=true`)  
- [ ] Portal served only via HTTPS  
- [ ] Artifact hashes match signed binaries before Stable publish  

---

*End of UPDATE_SECURITY.md*
