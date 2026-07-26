# FINAL_TEST_READY.md

**Date:** 2026-07-26  
**Decision:** NOT READY  

---

## Gate summary

| Gate | Status |
|------|--------|
| Vercel URL readable from project deployment configuration | **FAIL** — NOT FOUND |
| Hardcoded `thegoldmind.ai` replaced with Vercel URL | **FAIL** — blocked (no guess) |
| Env vars (`NEXTAUTH_URL`, `APP_URL`, `PUBLIC_APP_URL`, `LICENSE_SERVER_URL`, Google callback) on Vercel | **FAIL** — not configured locally / URL unknown |
| Setup.exe rebuilt for Vercel | **FAIL** — not rebuilt without verified URL |
| Portal / Google / License / Activation / Device / Dashboards verified on Vercel | **FAIL** — not verified |
| Core Trading Engine unmodified | **PASS** |

---

## Why NOT READY

Production Test Mode requires a **known** Vercel deployment URL from project configuration.  
None was found (no `.vercel` link, no CLI, no `*.vercel.app` in env/docs).

Replacing `https://thegoldmind.ai` with an invented host would violate mission rules.

---

## Unblock checklist (Owner)

1. Provide live Vercel URL **or** run `vercel link` under `Commercial/CustomerPortal/web` so `.vercel/project.json` exists.  
2. Set Vercel project env: `NEXTAUTH_URL`, public app URL, `NEXTAUTH_SECRET`, Google OAuth, license/billing secrets.  
3. Register Google redirect URI: `{VERCEL_URL}/api/auth/callback/google`.  
4. Rebuild installer with `-PortalBase <verified-url>`.  
5. Re-run smoke tests; expect decision flip to READY FOR VERCEL TESTING.

---

## Companion reports

- `VERCEL_DEPLOYMENT_REPORT.md`
- `PRODUCTION_TEST_MODE.md`
- `INSTALLER_CONFIGURATION.md`
