# ADMIN_LICENSE_CONSOLE.md

**Phase:** 9 · Sprint 3  
**Route:** `/portal/admin`  
**API:** `GET /api/admin/licensing?q=`  
**Access:** role `admin` or email `admin@goldmind.local`  
**Mode:** Read-only foundation this sprint

---

## Panels

| Panel | Content |
|-------|---------|
| License Lookup | id, customer, type, status, expiry (masked key only) |
| Customer Lookup | via search filter on email/name |
| Activation / Device History | device table with activation + last active |
| Subscription Status | plan + status + expiration |
| Search & Filters | query string `q` |
| Audit | recent licensing audit events |

Sign in with Demo email `admin@goldmind.local` for local admin access.

Mutating admin tools (revoke, force transfer) deferred.

---

*End of ADMIN_LICENSE_CONSOLE.md*
