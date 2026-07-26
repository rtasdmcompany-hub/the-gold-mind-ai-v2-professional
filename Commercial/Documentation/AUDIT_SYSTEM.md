# AUDIT_SYSTEM.md

**Phase:** 9 · Sprint 6  
**Code:** `server/cloud/audit.ts`  
**Store:** `.data/audit/audit.enc` (AES-256-GCM)  
**API:** `GET /api/cloud/audit` (support/admin)  
**UI:** `/portal/admin/cloud`

---

## Tracked actions

Login · Logout · Login failed · License activation · Payment events · Device registration · Profile changes · Admin actions · Downloads · Updates · Support actions · API requests · Rate limited · Health checks

---

## Required fields (every entry)

| Field | Description |
|-------|-------------|
| Timestamp | `at` ISO |
| User | email or `system` / `anonymous` |
| Action | `AuditAction` |
| IP | masked |
| Result | success · failure · denied · error |

Optional: `detail` · `resource` · `meta`

---

## Retention

In-store cap: 10,000 newest entries. Export/backup via DB backup policy targets.

---

*End of AUDIT_SYSTEM.md*
