# AUTHENTICATION.md

**Phase:** 9 · Sprint 6  
**Code:** `src/auth.ts` · `server/licensing/session.ts`

---

## Providers

| Method | Notes |
|--------|-------|
| Google OAuth | When `GOOGLE_CLIENT_*` set |
| Email Login | Credentials / Demo provider (`PORTAL_DEMO_AUTH`) |

---

## Session & tokens

| Item | Behavior |
|------|----------|
| Strategy | JWT (`session.strategy = "jwt"`) |
| Session maxAge | 8 hours |
| updateAge | 30 minutes (soft refresh / rotation on activity) |
| Session cache | `tgm:session:{email}` in Redis/memory |

Auth.js JWT session fulfills access + refreshable session token duties for the portal. Service-to-service updater uses `UPDATE_REPORT_SECRET` separately.

---

## RBAC roles

| Role | Access |
|------|--------|
| `customer` | Own licenses · billing · support tickets |
| `support` | Audit read · support tickets · customer assistance APIs |
| `admin` | Full admin consoles · cloud · billing · releases |

Assignment:

- `PORTAL_ADMIN_EMAILS` (default `admin@goldmind.local`)
- `PORTAL_SUPPORT_EMAILS` (default `support@goldmind.local`)
- Else `customer`

Helpers: `requireSession` · `requireSupport` · `requireAdmin`

---

## Brute-force protection

Cache counter `tgm:bf:{email}` · limit `AUTH_BRUTE_FORCE_LIMIT` (8) · window `AUTH_BRUTE_FORCE_WINDOW_SEC` (900).  
Failed attempts audited as `login_failed`.

---

## JWT validation

Session validated by Auth.js middleware + gateway `auth()` check on protected APIs.

---

*End of AUTHENTICATION.md*
