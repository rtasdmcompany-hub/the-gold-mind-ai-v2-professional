# ADMIN_CONSOLE_ARCHITECTURE.md

**Phase:** 9 · Sprint 7  
**UI:** `/portal/admin/*`  
**Services:** `src/server/admin/`  
**Rule:** Communicates only with commercial services — never Trading Engine

---

## Operations Hub KPIs

Active Customers · Active Licenses · Subscriptions · Revenue Overview · Daily Activations · New Registrations · Support Tickets · Latest Releases · System Health · Platform Status

---

## Modules

| Module | Route | Permission |
|--------|-------|------------|
| Operations Hub | `/portal/admin` | `admin.dashboard` |
| Customers | `/portal/admin/customers` | `admin.customers.read` |
| Licenses | `/portal/admin/licenses` | `admin.licenses.read` |
| Support Console | `/portal/admin/support` | `admin.support.read` |
| Business Intelligence | `/portal/admin/bi` | `admin.bi.read` |
| Audit Center | `/portal/admin/audit` | `admin.audit.read` |
| Billing | `/portal/admin/billing` | `admin.billing.read` |
| Releases | `/portal/admin/releases` | `admin.releases.read` |
| Cloud Health | `/portal/admin/cloud` | `admin.cloud.read` |
| Admin Security | `/portal/admin/security` | `admin.security.manage` |
| Roles | `/portal/admin/roles` | `admin.roles.manage` |

Layout: `admin/layout.tsx` — permission-filtered nav · idle timeout guard.

API: `GET /api/admin/ops?view=dashboard|bi|customers`

---

## Isolation

```
Admin Console → Commercial services (license/billing/releases/cloud/audit/support)
            ✗ → Trading Engine / Strategy / Risk / Recovery / Execution / Magic / AI
```

Every sensitive admin action is permission-checked and audited.

---

*End of ADMIN_CONSOLE_ARCHITECTURE.md*
