# PENETRATION_TEST_REPORT.md

**Phase:** 10 · Sprint 6  
**UI:** `/portal/admin/pentest`  
**Method:** Controlled in-process adversarial checks (commercial only)  
**Penetration Testing Score:** **100**  

---

## Results by target

| Target | Severity focus | Result |
|--------|----------------|--------|
| Authentication | High | PASS — demo auth production gate |
| Session Management | Medium | PASS — JWT 8h / updateAge 30m |
| JWT Handling | Critical | PASS — no client secret exposure |
| RBAC | Critical | PASS — least-privilege matrix |
| API Endpoints / CSRF | High | PASS — prod fail-closed without Origin |
| Rate Limiting | Medium | PASS — gateway + brute-force lockout |
| Webhook Endpoints | High | PASS — HMAC; prod rejects default secret |
| File Downloads | High | PASS — session required in production default |
| Admin Routes | High | PASS — middleware + layout + API auth |

## Findings by severity

| Severity | Open | Mitigated / Pass / Accepted |
|----------|-----:|-----------------------------|
| Critical | 0 | Privilege escalation checks PASS |
| High | 0 | Demo bypass, download auth, CSRF, webhooks mitigated |
| Medium | — | RC demo auth accepted for Controlled Launch |
| Low / Info | — | Timing-safe compares verified |

## Rule

No Critical or High finding remains **open** unresolved. Accepted Medium items require Owner conditions before open Stable (legal pack, 2FA enrollment, live PSP).
