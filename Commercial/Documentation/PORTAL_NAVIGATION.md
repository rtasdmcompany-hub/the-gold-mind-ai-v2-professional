# PORTAL_NAVIGATION.md

**Phase:** 9 · Sprint 2  
**Source of truth in code:** `Commercial/CustomerPortal/web/src/lib/nav.ts`

---

## Routes

| Path | Section |
|------|---------|
| `/login` | Public sign-in |
| `/portal` | Dashboard |
| `/portal/licenses` | My Licenses |
| `/portal/downloads` | Downloads |
| `/portal/subscriptions` | Subscriptions |
| `/portal/devices` | Devices |
| `/portal/invoices` | Invoices |
| `/portal/orders` | Orders |
| `/portal/support` | Support |
| `/portal/knowledge-base` | Knowledge Base |
| `/portal/announcements` | Announcements |
| `/portal/account` | Account Settings |
| `/portal/security` | Security |

`/` redirects to `/portal` (then auth middleware).

---

## Active state

Left nav highlights exact section; Dashboard active only on `/portal`.

---

## Responsive behaviour

≤960px: nav becomes horizontal wrap under brand; content stacks to single column.

---

*End of PORTAL_NAVIGATION.md*
