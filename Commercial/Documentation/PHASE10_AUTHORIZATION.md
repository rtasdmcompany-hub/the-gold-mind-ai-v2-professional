# PHASE 10 AUTHORIZATION

**From:** Phase 9 Executive Board (Sprint 10)  
**To:** Owner / Release Engineering / Commercial  
**Date:** 2026-07-26  
**Subject:** Conditional authorization to begin Phase 10 — Controlled Public Launch  

---

## Authorization status

**STATUS: CONDITIONALLY AUTHORIZED**

Phase 10 **may begin** only as **Controlled Public Launch** under the conditions in `FINAL_EXECUTIVE_DECISION.md`.  
This is **not** authorization for unrestricted Stable public marketing.

---

## What Phase 10 may include (when conditions allow)

1. Provision production hosting for Customer Portal + admin  
2. Connect live Paddle/PayPal credentials (or documented Owner sandbox waiver for invite-only)  
3. Publish Legal Pack and brand assets  
4. Activate support KB (≥20 articles) and on-call  
5. Invite-limited / cohort customer acquisition  
6. Monitoring, incident response, backup drills  
7. MQL5 Market listing prep (if Market in launch window)  
8. Git remote, CI, tag `v2.0.0-rc.2` → later Stable tag  

## What Phase 10 must NOT include until conditions clear

- Unrestricted public ads / open storefront without Legal + Brand  
- Claims of “production SLA” without monitoring + DR  
- Modification of Core Trading Engine  
- Coupling MQL5 Market billing to Website PaymentPort  

---

## Prerequisites before first paying public customer

| # | Prerequisite | Gate |
|---|--------------|------|
| 1 | Privacy / Terms / Refund / Risk (Cookie if needed) live | BC-LEGAL |
| 2 | Brand assets in `Commercial/Assets/` | BC-BRAND |
| 3 | Live payment credentials **or** written Owner waiver for invite-only | BC-PAYLIC |
| 4 | Support Top-20 + intake live | BC-SUPPORT |
| 5 | Deploy + health green in prod | Release |
| 6 | Owner Core attestation signed (recommended) | BC-CORE |

---

## Hard stops

- Any Critical defect → freeze acquisition  
- Core hash drift → immediate halt + board review  
- Webhook secret compromise → rotate + revoke  

## Governing documents

- `FINAL_EXECUTIVE_DECISION.md`  
- `BOARD_CONDITIONS_TRACKER.md`  
- `PRODUCTION_READINESS.md`  
- `PRODUCTION_DEPLOYMENT_PLAN.md`  

**STOP:** Await Owner written approval before executing Phase 10 workstreams.
