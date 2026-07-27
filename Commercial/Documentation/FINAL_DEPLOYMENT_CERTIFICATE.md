# FINAL_DEPLOYMENT_CERTIFICATE.md

**Product:** THE GOLD MIND AI v2.0 PROFESSIONAL  
**Certification date:** 2026-07-27  
**Commit:** `225f8e5`  
**Core Trading Engine:** UNTOUCHED · SHA `75002e46e3c200292c3696b2767bba20f2dd4200c74078555f84bc1f54a033ce`

---

## Deployment record

| Field | Value |
|-------|-------|
| Platform | Vercel (`rtas-group/the-gold-mind-ai-v2-professional`) |
| GitHub repo | `rtasdmcompany-hub/the-gold-mind-ai-v2-professional` |
| Branch | `main` |
| Deployment ID | `5621118144` |
| Deployment state | **success** |
| Build command | `npm run build` |
| Root directory | `Commercial/CustomerPortal/web` |

---

## Gate checklist

| Gate | Status |
|------|--------|
| Lint | **PASS** |
| Production build | **PASS** |
| Git push to main | **PASS** |
| Vercel deploy triggered | **PASS** |
| Core SHA frozen | **PASS** |
| Enterprise UI deployed in build | **PASS** |
| Public alias reachable | **FAIL** — `the-gold-mind-ai-v2-professional.vercel.app` returns 404 |
| Deployment Protection | **BLOCKED** — team URLs require Vercel SSO |
| Live customer E2E on production | **BLOCKED** — pending Owner Vercel config |

---

## Prior production verification (commit `3cd9867`)

The following were verified before enterprise UI deploy and remain valid at application level:

- `/login` 200, no redirect loop
- `/api/health` 200 healthy
- Demo auth → `/portal` 200
- All portal routes 200
- License create API 200

---

## Accompanying RC reports

1. `FINAL_RELEASE_REPORT.md`
2. `FINAL_UI_REPORT.md`
3. `FINAL_SECURITY_REPORT.md`
4. `FINAL_PERFORMANCE_REPORT.md`
5. `INSTALLER_REPORT.md`
6. `MT5_VALIDATION_REPORT.md`
7. `CUSTOMER_FLOW_REPORT.md`
8. `FINAL_QA_REPORT.md`
9. `OWNER_CONFIGURATION_CHECKLIST.md`

---

## CERTIFICATION

# OWNER ACTION REQUIRED

Application build and deployment pipeline are certified. Public commercial access requires Owner to configure Vercel production domain and disable Deployment Protection. See `OWNER_CONFIGURATION_CHECKLIST.md`.
