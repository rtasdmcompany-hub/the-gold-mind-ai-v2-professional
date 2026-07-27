# OWNER_CONFIGURATION_CHECKLIST.md

**Product:** THE GOLD MIND AI v2.0 PROFESSIONAL  
**Date:** 2026-07-27  
**Commit:** `225f8e5`

Complete this checklist before public commercial launch. Items marked **Required** block customer access. Items marked **Optional** enable live provider integrations; the app runs without them using demo auth, sandbox payments, and file stores.

---

## CRITICAL — Vercel production access

- [ ] **Required** — Fix production alias: `https://the-gold-mind-ai-v2-professional.vercel.app` currently returns **404**
  - Vercel Dashboard → Project → Settings → Domains → assign production domain
- [ ] **Required** — Disable **Deployment Protection** on production (or configure `VERCEL_AUTOMATION_BYPASS_SECRET`)
  - Team URLs currently show Vercel SSO login wall instead of the app
- [ ] **Required** — Confirm `NEXTAUTH_URL` matches the live production URL after alias fix
- [ ] **Required** — Re-run production acceptance test after above changes

---

## Authentication

- [ ] **Optional** — `GOOGLE_CLIENT_ID` + `GOOGLE_CLIENT_SECRET`
- [ ] **Optional** — Google OAuth authorized redirect URI:
  `https://<production-domain>/api/auth/callback/google`
- [x] **Done** — `AUTH_SECRET` / `NEXTAUTH_SECRET` (configured in Vercel)
- [x] **Done** — Demo auth enabled for controlled testing (`PORTAL_DEMO_AUTH`)

---

## Payments

- [ ] **Optional** — `PADDLE_VENDOR_ID`, `PADDLE_API_KEY`, `PADDLE_WEBHOOK_SECRET`
- [ ] **Optional** — `PAYPAL_CLIENT_ID`, `PAYPAL_CLIENT_SECRET`, `PAYPAL_WEBHOOK_SECRET`
- [ ] **Optional** — Set `PAYMENT_MODE=live` when ready for real transactions
- [x] **Done** — `PAYMENT_MODE=sandbox` (current)

---

## Email

- [ ] **Optional** — `RESEND_API_KEY`
- [ ] **Optional** — `RESEND_FROM_EMAIL` (verified sender domain)
- [ ] **Optional** — Email domain DNS records (SPF, DKIM, DMARC)

---

## Database & cache

- [ ] **Optional** — `NEXT_PUBLIC_SUPABASE_URL`, `NEXT_PUBLIC_SUPABASE_ANON_KEY`
- [ ] **Optional** — `SUPABASE_SERVICE_ROLE_KEY`, `SUPABASE_JWT_SECRET`
- [ ] **Optional** — `UPSTASH_REDIS_REST_URL`, `UPSTASH_REDIS_REST_TOKEN`

---

## Domain & SSL

- [ ] **Optional** — Custom domain (e.g. `portal.thegoldmind.ai`)
- [ ] **Optional** — DNS A/CNAME records pointing to Vercel
- [ ] **Optional** — SSL certificate (auto-provisioned by Vercel when domain added)

---

## Installer & desktop

- [ ] **Required for desktop sales** — Place `Setup.exe` at `Commercial/Releases/1.0.0/installer/Setup.exe`
- [ ] **Required for desktop sales** — Run `Validate-Installer.ps1` on a Windows machine with MT5
- [ ] **Optional** — Code-sign Setup.exe (see `SIGNING_WORKFLOW.md`)

---

## Brand assets (optional enhancements)

- [ ] Upload hero background video → `/public/media/hero-institutional.mp4`
- [ ] Upload official product screenshots for SoftwareShowcase
- [ ] Upload live MT5 terminal screenshots for marketing / MQL5 Market

---

## Webhook secrets (when going live)

- [ ] Paddle webhook endpoint secret
- [ ] PayPal webhook verification secret

---

## Verification commands (after Vercel fix)

```powershell
# From Commercial/CustomerPortal/web
npm run lint
npm run build

# Production smoke (replace URL after alias fix)
Invoke-WebRequest https://<production-domain>/api/health
Invoke-WebRequest https://<production-domain>/login
```

---

## Status summary

| Category | App ready? | Owner config needed? |
|----------|------------|---------------------|
| Application code | **YES** | No |
| Enterprise website | **YES** | No |
| Portal / auth / billing | **YES** | Optional live providers |
| Vercel production URL | **NO** | **YES — critical** |
| Desktop installer binary | **Partial** | **YES — Setup.exe** |
| Custom domain | **NO** | Optional |

---

**When all Required items are complete, re-run production acceptance and update `FINAL_DEPLOYMENT_CERTIFICATE.md` to READY FOR COMMERCIAL RELEASE.**
