# CLOUD_ARCHITECTURE.md

**Phase:** 9 · Sprint 6  
**Root:** `Commercial/CustomerPortal/web/src/server/cloud/`  
**Final rule:** Cloud is a commercial service layer. It must **never** directly control or modify the Trading Engine.

---

## Design goals

Scalability · Security · Reliability · Maintainability — for Website Edition customers worldwide.

---

## Independently deployable services

| Service | Base path | Role |
|---------|-----------|------|
| API Gateway | `/api` | Cross-cutting authz / RL / standards |
| Customer Portal | `/portal` | UI |
| License Service | `/api/licenses` | Licenses / devices |
| Subscription Service | `/api/billing` | Plans / payments |
| Update Service | `/api/releases` | Packages / updater |
| Notification Service | `/api/cloud/notifications` | Email outbox |
| Analytics Service | `/api/cloud/analytics` | Commercial metrics |
| Support Service | `/api/cloud/support` | Tickets |
| Audit Service | `/api/cloud/audit` | Central audit |
| Cache Service | Upstash / memory | Sessions · RL · config |

Registry: `services.ts` · Admin UI: `/portal/admin/cloud`

---

## Isolation diagram

```
┌─────────────────────────────────────────────┐
│  Commercial Cloud (Website Edition)         │
│  Portal · Gateway · License · Billing · …   │
└──────────────────┬──────────────────────────┘
                   │ optional approved services
                   ▼
┌─────────────────────────────────────────────┐
│  Core Trading Engine (CERTIFIED · FROZEN)   │
│  Fully operational if cloud is unavailable  │
└─────────────────────────────────────────────┘
```

**Cloud failures must never stop local trading operations.**

---

## Not this sprint

`Include/Cloud/**` is the Phase 6 **MQL5 EA** cloud stack — separate runtime. Do not merge into the portal.

---

*End of CLOUD_ARCHITECTURE.md*
