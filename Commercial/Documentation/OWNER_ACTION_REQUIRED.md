# OWNER_ACTION_REQUIRED.md

**Product:** THE GOLD MIND PROFESSIONAL 1.0.0  
**Updated:** 2026-07-31  

**Credential progress:** Resend API + company domain `rtasstudio.com` verified. Google OAuth client credentials verified. Values stored in local gitignored `.env.production` (must be pasted into Vercel).

---

## 1. Code Signing Certificate

**Status:** Waiting for Owner  

Provide Authenticode certificate; authorize signed Setup rebuild.

---

## 2. Production Domain DNS

**Status:** Waiting for Owner (only if using a custom hostname instead of current Vercel URL)  

Point custom domain to Vercel and update `AUTH_URL` / `NEXTAUTH_URL` / `NEXT_PUBLIC_APP_URL`.  
If remaining on `https://the-gold-mind-ai-v2-professional.vercel.app`, this item is optional.

---

## 3. Vercel Production Environment Paste

**Status:** Waiting for Owner / deploy access  

Paste from local `.env.production` into Vercel Production:

**Ready now (configured & verified locally):**

- `RESEND_API_KEY`
- `RESEND_FROM_EMAIL` = `THE GOLD MIND PROFESSIONAL <noreply@rtasstudio.com>`
- `GOOGLE_CLIENT_ID`
- `GOOGLE_CLIENT_SECRET`
- `AUTH_SECRET` / `NEXTAUTH_SECRET` / `LICENSE_STORE_SECRET` (generated locally)
- `AUTH_URL` / `NEXTAUTH_URL` / `NEXT_PUBLIC_APP_URL`

**Still missing (Owner must create/provide):**

### 3a. Upstash

- Missing: `UPSTASH_REDIS_REST_URL`, `UPSTASH_REDIS_REST_TOKEN`
- Owner provides: permanent Upstash Redis REST credentials  
- Cursor then: verify durable license store on Vercel

### 3b. Paddle

- Missing: `PADDLE_VENDOR_ID`, `PADDLE_PRICE_ID`, `PADDLE_API_KEY`, `PADDLE_WEBHOOK_SECRET`
- Owner provides: live Paddle credentials + webhook registration + live approval if pending  
- Cursor then: verify checkout/webhook/license mint

### 3c. Admin Emails

- Missing: real `PORTAL_SUPER_ADMIN_EMAILS`, `PORTAL_ADMIN_EMAILS`, `PORTAL_SUPPORT_EMAILS`, `PORTAL_AUDITOR_EMAILS`
- Owner provides: production admin roster emails  
- Cursor then: verify `/portal/admin` role elevation

---

## 4. Google Cloud Console — Redirect URI Allowlist

**Status:** Waiting for Owner (existing company project)  

On the **existing** OAuth client, confirm Authorized JavaScript origins + redirect URIs include:

- `https://the-gold-mind-ai-v2-professional.vercel.app`
- `https://the-gold-mind-ai-v2-professional.vercel.app/api/auth/callback/google`
- localhost equivalents for dev if needed  

No new Google account/project required. Details in `GOOGLE_OAUTH_REPORT.md`.

---

## 5. Legal Approval

**Status:** Waiting for Owner  

Counsel sign-off on published legal drafts.

---

## Removed from Owner blockers (completed)

- **Resend API key validity** — PASS  
- **Resend domain SPF/DKIM (`rtasstudio.com`)** — PASS  
- **Resend dedicated THE GOLD MIND FROM identity** — PASS  
- **Resend delivery tests (license/reset/welcome/support/billing)** — PASS  
- **Google OAuth client ID/secret validity** — PASS  

See `RESEND_REPORT.md`, `GOOGLE_OAUTH_REPORT.md`, `PRODUCTION_CONFIGURATION_REPORT.md`.
