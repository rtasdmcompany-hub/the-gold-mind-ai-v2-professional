# SECURITY_AUDIT_REPORT.md

**Phase:** 10 · Sprint 6  
**Scope:** Commercial portal / cloud / infrastructure only  
**Core:** FROZEN · not imported by security suite  
**Portal:** `0.9.1-phase10.s6`  
**Run:** `npm run security:sprint6`  

---

## Assessment surfaces

| Surface | Rating |
|---------|--------|
| Customer Portal | strong |
| Authentication | adequate (demo RC-gated) |
| Authorization / RBAC | strong (prod bypass off) |
| API Gateway | strong |
| License Service | strong |
| Payment Layer | adequate |
| Admin Console | strong |
| Support Portal | adequate |
| Cloud Infrastructure | adequate |
| File Downloads | adequate / strong in production |

## Hardening applied (Sprint 6)

- Demo credentials blocked in production unless `PORTAL_ALLOW_DEMO_IN_PROD=true`
- `admin@goldmind.local` RBAC bypass disabled in production (`isDevAdminBypass`)
- Package downloads require session in production (`RELEASE_DOWNLOAD_AUTH`)
- CSRF fails closed in production when Origin/Referer absent
- License integrity MAC uses timing-safe compare
- Sandbox webhook rejects default secret in production
- Stripe webhook HMAC path when `STRIPE_WEBHOOK_SECRET` set (else fail-closed)
- Draft legal pages: `/privacy` `/terms` `/cookies` `/refund` `/risk`

## Scores

| Metric | Value |
|--------|------:|
| Security Score | **80** |
| Overall Security Score | **89** |
| Open Critical | **0** |
| Open High | **0** |
| Production Security Readiness | **READY_WITH_CONDITIONS** |

## Surfaces

| Surface | Path |
|---------|------|
| Executive Security Audit | `/portal/admin/security-audit` |
| API | `/api/admin/security-audit` |
| CLI | `npm run security:sprint6` |
