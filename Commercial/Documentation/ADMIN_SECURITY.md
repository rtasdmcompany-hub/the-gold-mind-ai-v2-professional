# ADMIN_SECURITY.md

**Phase:** 9 · Sprint 7  
**Code:** `src/server/admin/security.ts` · `AdminIdleGuard`  
**UI:** `/portal/admin/security`

---

## Controls

| Control | Implementation |
|---------|----------------|
| Admin Session Timeout | Idle logout (`ADMIN_IDLE_TIMEOUT_MINUTES`, default 30) |
| Two-Factor Authentication | Architecture ready (TOTP / WebAuthn / email OTP) — enrollment path documented |
| IP Logging | Audit entries + hashed IP meta |
| Permission Validation | `hasPermission` / gateway `permission` / `requirePermission` |
| Sensitive Action Confirmation | Short-lived confirm tokens (5 min) |
| Security Event Logging | Audit with `meta.security=1` |

Trading Engine access: **false** (hard policy).

---

*End of ADMIN_SECURITY.md*
