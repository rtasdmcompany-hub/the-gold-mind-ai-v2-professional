# PRODUCTION_CONFIGURATION_REPORT.md

**Product:** THE GOLD MIND PROFESSIONAL 1.0.0  
**Date:** 2026-07-31  

---

## Credentials configured locally (gitignored)

| Variable | Status |
|----------|--------|
| `GOOGLE_CLIENT_ID` | SET |
| `GOOGLE_CLIENT_SECRET` | SET |
| `AUTH_GOOGLE_ID` / `AUTH_GOOGLE_SECRET` | SET (aliases) |
| `RESEND_API_KEY` | SET |
| `RESEND_FROM_EMAIL` | SET (`THE GOLD MIND PROFESSIONAL <noreply@rtasstudio.com>`) |
| `SUPPORT_EMAIL` / `SUPPORT_INBOX_EMAIL` | SET (`support@rtasstudio.com`) |
| `AUTH_URL` / `NEXTAUTH_URL` / `NEXT_PUBLIC_APP_URL` | SET to current Vercel app URL |
| `AUTH_SECRET` / `NEXTAUTH_SECRET` / `LICENSE_STORE_SECRET` | GENERATED locally (gitignored) |

Files: `Commercial/CustomerPortal/web/.env.production` and `.env.local` (**not committed**).

---

## Service results

| Service | Result | Notes |
|---------|--------|-------|
| Resend | **PASS** | Domain `rtasstudio.com` verified; SPF/DKIM verified; delivery tests PASS |
| Google OAuth client | **PASS** (credentials) | Console redirect URI allowlist still needs Owner confirmation |
| Portal production build | **PASS** | `BUILD_ID=3tHydF9iICckU3ZynMbWs` |
| Trading Engine | Untouched | No MQL5/strategy changes |

---

## Vercel deployment note

This environment has **no Vercel CLI auth**. Owner (or connected deploy pipeline) must copy the gitignored production values into **Vercel → Environment Variables (Production)** for the live site to use them.

Minimum to paste now:

1. `RESEND_API_KEY`
2. `RESEND_FROM_EMAIL`
3. `GOOGLE_CLIENT_ID`
4. `GOOGLE_CLIENT_SECRET`
5. `AUTH_SECRET` / `NEXTAUTH_SECRET` (from local `.env.production`)
6. `AUTH_URL` / `NEXTAUTH_URL` / `NEXT_PUBLIC_APP_URL`

---

## Owner actions still open (narrowed)

See `OWNER_ACTION_REQUIRED.md`:

1. Code Signing Certificate  
2. Production Domain DNS (custom hostname; optional if staying on Vercel URL)  
3. Vercel env paste for configured secrets + remaining missing services (Upstash, Paddle, Admin emails)  
4. Google Cloud Console redirect/origin allowlist confirmation  
5. Legal Approval  

Resend API/domain verification is **complete** (Vercel paste only).
