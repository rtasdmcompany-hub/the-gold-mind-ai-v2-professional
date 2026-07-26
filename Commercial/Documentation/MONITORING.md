# MONITORING.md

**Phase:** 9 · Sprint 6  
**Code:** `server/cloud/monitoring.ts`  
**Endpoints:** `GET /api/health` · `GET /api/health?detailed=1`  
**Admin:** `/portal/admin/cloud`

---

## Monitored surfaces

| Check | ID |
|-------|-----|
| API Health | `api` |
| Customer Portal Health | `portal` |
| License Service Health | `license` |
| Subscription / Billing | `subscription` |
| Update Service | `update` |
| Email / Notification | `email` |
| Cache | `cache` |
| Audit | `audit` |
| Background Workers | `workers` |
| Database / Persistence | `database` |

System metrics: uptime · audit count · cache backend · rate-limit backend.

Statuses: `healthy` · `degraded` · `unhealthy` (HTTP 503 when unhealthy).

---

## Isolation note

Monitoring failures or cloud outages **must not** stop local Trading Engine operations. Health is commercial observability only.

---

*End of MONITORING.md*
