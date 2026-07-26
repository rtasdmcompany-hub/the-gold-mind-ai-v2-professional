# VERCEL_DEPLOYMENT_REPORT.md

**Date:** 2026-07-26  
**Mode:** Production Test Mode (Vercel)  
**Core Trading Engine:** NOT MODIFIED  

---

## TASK 1 — Locate Vercel URL from deployment configuration

| Source checked | Result |
|----------------|--------|
| `Commercial/CustomerPortal/web/.vercel/project.json` | **NOT FOUND** |
| `Commercial/CustomerPortal/web/vercel.json` | **NOT FOUND** |
| `Commercial/CustomerPortal/web/.env.production` | **NOT FOUND** |
| `Commercial/CustomerPortal/web/.env.local` | Present — `NEXTAUTH_URL=http://localhost:3000` only (no `*.vercel.app`) |
| `VERCEL_URL` in local env files | **NOT FOUND** |
| Vercel CLI (`vercel whoami` / `vercel ls`) | **NOT FOUND** (CLI not installed / not on PATH) |
| `Commercial/Documentation/PRODUCTION_DEPLOYMENT.md` | States Vercel PASS only when `VERCEL_URL` present; **no concrete URL recorded** |
| Documentation search for `*.vercel.app` | **NOT FOUND** |

### Hardcoded `https://thegoldmind.ai` (found; NOT replaced)

Per mission rule: **Do NOT guess the URL.** Replacement was **blocked** until a verified Vercel URL exists in deployment configuration.

| File | Current value |
|------|----------------|
| `Commercial/Installer/Professional/scripts/Build-CommercialRelease.ps1` | Default `-PortalBase "https://thegoldmind.ai"` |
| `Commercial/Installer/Professional/inno/payload/config/portal.json` | `"portalBase": "https://thegoldmind.ai"` |
| `Commercial/Installer/Professional/inno/payload/config/version.json` | `"portalBase": "https://thegoldmind.ai"` |

Portal application code primarily uses `process.env.NEXTAUTH_URL` (not hardcoded `thegoldmind.ai`).

---

## TASK 2 — Service URL verification

| Surface | Uses | Points to Vercel? |
|---------|------|-------------------|
| Google OAuth | NextAuth Google provider when `GOOGLE_CLIENT_ID/SECRET` set | **NO** — local `NEXTAUTH_URL=http://localhost:3000`; Google secrets empty in `.env.local` |
| NextAuth | `NEXTAUTH_URL` | **NO** — localhost |
| License API | Relative `/api/licenses/*` on app origin | **NO** — origin not Vercel |
| Portal Login | `/login` on app origin | **NO** |
| Activation | Installer → `portalBase` + `/api/licenses/actions` | **NO** — `thegoldmind.ai` |
| Renew / Bind Device | Portal APIs on app origin | **NO** |
| Customer / Admin Portal | Same origin | **NO** |
| Email callbacks | Derived from `NEXTAUTH_URL` where used | **NO** |

---

## TASK 3 — Environment variables

| Variable | In `.env.local` | Points to Vercel? |
|----------|-----------------|-------------------|
| `NEXTAUTH_URL` | `http://localhost:3000` | **NO** |
| `APP_URL` | **NOT SET** | **NO** |
| `PUBLIC_APP_URL` / `NEXT_PUBLIC_APP_URL` | **NOT SET** in `.env.local` | **NO** |
| `LICENSE_SERVER_URL` | **NOT SET** | **NO** |
| `GOOGLE_CALLBACK_URL` | **NOT SET** (NextAuth uses `{NEXTAUTH_URL}/api/auth/callback/google`) | **NO** |
| `VERCEL_URL` | **NOT SET** locally | **NO** |

---

## TASK 4 — Installer rebuild

**NOT EXECUTED** — rebuilding Setup.exe with an unverified URL would violate “Do NOT guess the URL.”

Current packaged installer still embeds `https://thegoldmind.ai` in `portal.json`.

---

## TASK 5 — Deployment verification

| Check | Result |
|-------|--------|
| Portal opens (Vercel) | **NOT VERIFIED** — URL unknown |
| Google Login opens | **NOT VERIFIED** |
| License page loads | **NOT VERIFIED** |
| Activation endpoint responds | **NOT VERIFIED** |
| Device binding works | **NOT VERIFIED** |
| Customer dashboard loads | **NOT VERIFIED** |
| Admin dashboard loads | **NOT VERIFIED** |

---

## Owner action required (minimum)

1. Link the portal to Vercel (`vercel link` in `Commercial/CustomerPortal/web`) **or** provide the live `https://<project>.vercel.app` URL in writing / `.vercel` / env.  
2. Set production env on Vercel: `NEXTAUTH_URL`, `NEXT_PUBLIC_APP_URL` (or `PUBLIC_APP_URL`), OAuth secrets, license store secrets.  
3. Re-run packaging:  
   `Build-CommercialRelease.ps1 -PortalBase https://<verified-vercel-host>`  
4. Re-run this verification checklist.

**Trading Engine / Risk / Recovery:** untouched.
