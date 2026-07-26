# ADMIN_BILLING_DASHBOARD.md

**Phase:** 9 · Sprint 4  
**Route:** `/portal/admin/billing`  
**API:** `GET /api/admin/billing`  
**Access:** `role === "admin"` or `admin@goldmind.local`  
**Mode:** Read-only financial dashboard (+ email queue actions)

---

## Panels

| Panel | Content |
|-------|---------|
| Revenue Summary | Sum of succeeded payments (formatted) |
| Active Subscriptions | Count of `active` + `trialing` |
| Failed Payments | Count + underlying rows available via API |
| Recent Transactions | Latest payment ledger rows |
| Refunds | Refunded payments |
| Renewals | Payments tagged `note: renewal` |
| Subscriptions | Customer · plan · status · next billing · provider |
| Webhook Audit | Auth · type · HTTP status · duplicate · detail |

---

## Admin actions (non-mutating finance)

| Action | Effect |
|--------|--------|
| Queue renewal reminder emails | `sendRenewalReminders()` |
| Queue expiry notice emails | `sendExpiryNotices()` |

No manual revenue edits, refunds, or ledger rewrites in this sprint (read-only financial posture).

---

## Isolation

- Website Edition commercial data only.
- No Trading Engine metrics, equity, orders, or risk panels.
- No MQL5 Market sales data.

---

## Navigation

Portal nav: **Admin Billing** → `/portal/admin/billing`  
Companion: Admin Licensing Console `/portal/admin`

---

*End of ADMIN_BILLING_DASHBOARD.md*
