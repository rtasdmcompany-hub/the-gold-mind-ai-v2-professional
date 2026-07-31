# OWNER_ACTION_REQUIRED.md

**Product:** THE GOLD MIND PROFESSIONAL 1.0.0  
**Updated:** 2026-07-31  
**Rule:** Only items that require Owner identity, payment approval, legal approval, certificates, DNS ownership, or live external dashboards.

Internal software packaging, builds, hash verification, licensing code, installer artifacts, and automated tests are complete.

---

## 1. Code Signing Certificate

**Status:** Waiting for Owner

Provide Authenticode Standard or EV certificate (and password/thumbprint).  
Authorize signed rebuild of `Setup.exe` / `TheGoldMindSetup.exe`, then refresh published SHA256 hashes.  
After signing, monitor Windows SmartScreen reputation for first customers.

---

## 2. Production Domain DNS

**Status:** Waiting for Owner

Point the commercial hostname to the Vercel deployment and confirm HTTPS.  
Set production `AUTH_URL`, `NEXTAUTH_URL`, and `NEXT_PUBLIC_APP_URL` to that hostname.

---

## 3. Production Services and Secrets

**Status:** Waiting for Owner

Create/claim the live services below, then paste values into Vercel using  
`Commercial/CustomerPortal/web/.env.production.example` as the checklist:

1. **Upstash Redis** — `UPSTASH_REDIS_REST_URL`, `UPSTASH_REDIS_REST_TOKEN`, plus `LICENSE_STORE_SECRET`
2. **Auth** — `AUTH_SECRET` / `NEXTAUTH_SECRET`
3. **Admin allow-lists** — `PORTAL_SUPER_ADMIN_EMAILS`, `PORTAL_ADMIN_EMAILS` (and optional role lists)
4. **Paddle live** — `PADDLE_VENDOR_ID`, `PADDLE_PRICE_ID`, `PADDLE_API_KEY`, `PADDLE_WEBHOOK_SECRET`  
   Also in Paddle dashboard: enable live mode and register the production webhook URL
5. **Resend** — `RESEND_API_KEY`, `RESEND_FROM_EMAIL`  
   Also publish SPF/DKIM for the sending domain
6. **Google OAuth** (if offering Google login) — create OAuth client for the production origin; set `GOOGLE_CLIENT_ID` / `GOOGLE_CLIENT_SECRET`

---

## 4. Legal Approval

**Status:** Waiting for Owner

Counsel sign-off on Terms, Privacy, EULA, Risk disclosure, and customer-facing commercial copy.
