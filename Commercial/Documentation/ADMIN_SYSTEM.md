# ADMIN_SYSTEM.md

**Product:** THE GOLD MIND PROFESSIONAL  
**Updated:** 2026-07-31  
**Scope:** Customer Portal commercial admin RBAC only — never grants Trading Engine access.

---

## Production admin titles

| Title | Portal role | Environment variable |
|-------|-------------|----------------------|
| Owner | `super_admin` | `PORTAL_SUPER_ADMIN_EMAILS` |
| Administrator | `super_admin` | `PORTAL_ADMIN_EMAILS` |
| Support | `support_agent` | `PORTAL_SUPPORT_EMAILS` |
| ReadOnly Admin | `auditor` | `PORTAL_AUDITOR_EMAILS` |

Additional optional roles: Commercial Manager, Finance Manager, QA Manager (see `roles.ts`).

Aliases accepted by `normalizeAdminRole`: `owner`, `administrator` → Owner/Admin; `support` → Support; `readonly` / `read_only` / `readonly_admin` → ReadOnly Admin.

---

## How to onboard production admins

1. Create the person as a normal portal user (email/password verified, or Google OAuth when configured).
2. Add their email to the matching `PORTAL_*_EMAILS` list on Vercel (comma-separated, lowercase).
3. Have them sign out and sign in again so JWT role refreshes.
4. Confirm `/portal/admin` is visible and permissions match the matrix at `/portal/admin/roles`.

There is **no** production auto-seed of admin users (by design). Fill `PRODUCTION_ADMIN_LIST.md` with the real roster and keep it out of public repos if it contains personal emails — or store only in Owner password manager and leave the template placeholders.

---

## Permission summary

- **Owner / Administrator:** full commercial admin console
- **Support:** customers/licenses read, support tickets read/write, limited launch/observability read
- **ReadOnly Admin:** broad read + audit export; no write/security/role management

---

## Security notes

- Dev bypass (`admin@goldmind.local`) is disabled in production unless `PORTAL_ALLOW_DEV_BYPASS=true` (do not enable).
- Demo license seeding is blocked when `NODE_ENV=production` or `VERCEL` is set.
- Admin console requires authenticated session + role permission checks on pages and server actions.
