# PRODUCTION_TEST_MODE.md

**Status:** NOT ACTIVE — blocked on missing Vercel deployment URL  
**Intent:** Point commercial platform + installer at existing Vercel deployment instead of `https://thegoldmind.ai`  
**Core rule:** No Trading Engine / Risk / Recovery / trading-logic changes  

---

## Blocker

Project deployment configuration does **not** contain a readable production Vercel URL:

- No `.vercel/project.json`
- No `vercel.json` with production host
- No `VERCEL_URL` / `*.vercel.app` in portal env files
- Vercel CLI unavailable on this machine

Mission constraint: **Do NOT guess the URL.**

---

## What remains on custom domain (installer)

| Artifact | Value |
|----------|-------|
| Build default | `-PortalBase https://thegoldmind.ai` |
| Payload `config/portal.json` | `https://thegoldmind.ai` |
| Payload `config/version.json` | `https://thegoldmind.ai` |

## What portal uses today (local)

| Setting | Value |
|---------|-------|
| `NEXTAUTH_URL` | `http://localhost:3000` |
| Google OAuth secrets | Empty in `.env.local` |
| Demo auth | `PORTAL_DEMO_AUTH=true` |

---

## Activation criteria (when URL is supplied)

Production Test Mode becomes ACTIVE only when all are true:

1. Verified Vercel base URL recorded in deployment config or Owner-supplied env file  
2. `NEXTAUTH_URL` (and public app URL) = that Vercel base (https, no trailing slash inconsistency)  
3. Google callback = `{NEXTAUTH_URL}/api/auth/callback/google` registered in Google Cloud Console  
4. Installer rebuilt with `-PortalBase <vercel-url>`  
5. Smoke checks in `VERCEL_DEPLOYMENT_REPORT.md` Task 5 all pass  

Until then: **Production Test Mode = OFF**.
