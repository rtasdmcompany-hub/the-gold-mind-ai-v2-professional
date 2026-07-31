# OWNER_ACTION_REQUIRED.md

**Product:** THE GOLD MIND PROFESSIONAL 1.0.0  
**Updated:** 2026-07-31  

**Credential progress:** Resend API key verified on the existing company Resend account. Google OAuth client credentials verified. Local gitignored `.env.production` uses **THE GOLD MIND** placeholder emails (`@thegoldmind.ai`). Values must be pasted into Vercel.

**Brand separation:** Customer-facing identity is THE GOLD MIND only. Shared infra accounts (Resend/Google/Paddle/Upstash) remain allowed. See `BRAND_SEPARATION_REPORT.md`.

---

## 1. Code Signing Certificate

**Status:** Waiting for Owner  

Provide Authenticode certificate; authorize signed Setup rebuild.

---

## 2. Production Domain DNS

**Status:** Waiting for Owner (only if using a custom hostname instead of current Vercel URL)  

Point custom domain (planned: `thegoldmind.ai`) to Vercel and update `AUTH_URL` / `NEXTAUTH_URL` / `NEXT_PUBLIC_APP_URL`.  
If remaining on `https://the-gold-mind-ai-v2-professional.vercel.app`, this item is optional for the portal host — but email domain verification (item 3d) is still required for branded mail.

---

## 3. Vercel Production Environment Paste

**Status:** Waiting for Owner / deploy access  

Paste from local `.env.production` into Vercel Production:

**Ready now (configured locally — brand placeholders):**

- `RESEND_API_KEY` (same Resend account; API key unchanged)
- `RESEND_FROM_EMAIL` = `THE GOLD MIND PROFESSIONAL <noreply@thegoldmind.ai>`
- `SUPPORT_EMAIL` / `SUPPORT_INBOX_EMAIL` = `support@thegoldmind.ai`
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
- Owner provides: production admin roster emails (prefer `@thegoldmind.ai` or Owner-owned mailboxes)  
- Cursor then: verify `/portal/admin` role elevation

### 3d. Resend — verify `thegoldmind.ai` (brand separation)

- Add and verify domain **`thegoldmind.ai`** on the **existing** Resend account (SPF/DKIM/DMARC as Resend instructs)
- Until verified, keep placeholders in env; do **not** send customer mail with another product’s From domain
- Optional interim: mailbox forwarding from `support@` / `billing@` / `license@` / `admin@`thegoldmind.ai to Owner inbox

---

## 4. Google Cloud Console — Redirect URI Allowlist

**Status:** Waiting for Owner (existing company project)  

On the **existing** OAuth client, confirm Authorized JavaScript origins + redirect URIs include:

- `https://the-gold-mind-ai-v2-professional.vercel.app`
- `https://the-gold-mind-ai-v2-professional.vercel.app/api/auth/callback/google`
- localhost equivalents for dev if needed  

No new Google account/project required. OAuth **consent screen** product name should read **THE GOLD MIND PROFESSIONAL** (not RTAS Studio). Details in `GOOGLE_OAUTH_REPORT.md`.

---

## 5. Legal Approval

**Status:** Waiting for Owner  

Counsel sign-off on published legal drafts (now THE GOLD MIND publisher identity).

---

## Removed from Owner blockers (completed)

- **Resend API key validity** — PASS (shared company account OK)  
- **Google OAuth client ID/secret validity** — PASS  
- **Customer-facing brand separation code** — PASS (see `BRAND_SEPARATION_REPORT.md`)  

See `RESEND_REPORT.md`, `GOOGLE_OAUTH_REPORT.md`, `PRODUCTION_CONFIGURATION_REPORT.md`, `BRAND_SEPARATION_REPORT.md`.
