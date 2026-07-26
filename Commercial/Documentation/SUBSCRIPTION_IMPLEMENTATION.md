# SUBSCRIPTION_IMPLEMENTATION.md

**Phase:** 9 · Sprint 3  
**Module:** `subscription-service.ts` + Portal `/portal/subscriptions`

---

## States

`trialing` · `active` · `grace` · `cancelled` · `expired` · `renewed`

Mirrored from license lifecycle where applicable.

## Fields

- Renewal date  
- Expiration date  
- Grace period end  
- Cancelled / Renewed timestamps  
- `pendingPlanChange` — foundation for future upgrade/downgrade  

## Customer actions

- **Renew** — extends period via `renewLicense`  
- **Cancel** — sets cancelled (access until period end policy via status)  

Payment provider webhooks remain a later queue step (BC-PAYLIC).

---

*End of SUBSCRIPTION_IMPLEMENTATION.md*
