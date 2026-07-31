# OWNER_ACTION_REQUIRED.md

**Product:** THE GOLD MIND PROFESSIONAL 1.0.0  
**Updated:** 2026-07-31  
**Credential scan:** Repository + runtime — **no live secrets found** for Resend, Google OAuth, Paddle, Upstash, Admin emails, or Auth secrets.  
**Templates ready:** `Commercial/CustomerPortal/web/.env.production` (gitignored) and `.env.production.example`.

Only items that require Owner identity, purchased certificates, DNS ownership, live PSP dashboards, or legal counsel remain.

---

## A. Non-credential Owner blockers

### A1. Code Signing Certificate

**Status:** Waiting for Owner  

**Owner must provide:** Authenticode Standard or EV certificate (+ password/thumbprint).  
**Cursor will then:** Rebuild/sign `Setup.exe` / `TheGoldMindSetup.exe`, refresh SHA256 / SBOM / release notes, republish github-assets.

### A2. Production Domain DNS

**Status:** Waiting for Owner  

**Owner must provide:** Production hostname pointed at Vercel (HTTPS working).  
**Cursor will then:** Set/verify `AUTH_URL`, `NEXTAUTH_URL`, `NEXT_PUBLIC_APP_URL` against that hostname and re-check OAuth callback URLs.

### A3. Legal Approval

**Status:** Waiting for Owner  

**Owner must provide:** Counsel sign-off on published drafts (Privacy, Terms, EULA, Refund, Cookies, Disclaimer, Risk).  
**Cursor will then:** Remove “OWNER REVIEW REQUIRED” banners after written approval and mark legal gate PASS.

---

## B. Per-service credential checklist

### B1. Resend

| Question | Answer |
|----------|--------|
| Credential missing? | **YES** |
| Credential already present? | **NO** |
| Configuration incomplete? | **YES** (cannot complete without keys + DNS) |
| Exactly which values are missing? | `RESEND_API_KEY`, `RESEND_FROM_EMAIL` (recommended: `SUPPORT_EMAIL` / `SUPPORT_INBOX_EMAIL`) |
| Exactly what Owner must provide? | 1) Resend API key 2) Verified from-address 3) SPF/DKIM for sending domain in DNS |
| Exactly what Cursor will automatically complete after that? | Paste into Vercel env; verify `isResendConfigured()`; run admin test-email; confirm license/welcome/billing email paths call Resend; remove Resend from this checklist |

---

### B2. Google OAuth

| Question | Answer |
|----------|--------|
| Credential missing? | **YES** |
| Credential already present? | **NO** |
| Configuration incomplete? | **YES** (optional for email/password-only launch; required if Google login is offered) |
| Exactly which values are missing? | `GOOGLE_CLIENT_ID` **or** `AUTH_GOOGLE_ID`; `GOOGLE_CLIENT_SECRET` **or** `AUTH_GOOGLE_SECRET` |
| Exactly what Owner must provide? | Google Cloud OAuth client for production origin; authorized redirect URI = `{AUTH_URL}/api/auth/callback/google` |
| Exactly what Cursor will automatically complete after that? | Enable Google provider (code already gates on valid client); verify callback/login path; remove Google OAuth from this checklist |

---

### B3. Paddle

| Question | Answer |
|----------|--------|
| Credential missing? | **YES** |
| Credential already present? | **NO** |
| Configuration incomplete? | **YES** (software fail-closed is ready; live mode not configured) |
| Exactly which values are missing? | `PADDLE_VENDOR_ID`, `PADDLE_PRICE_ID`, `PADDLE_API_KEY`, `PADDLE_WEBHOOK_SECRET` |
| Exactly what Owner must provide? | Live Paddle vendor/price/API/webhook secret; enable **Live** mode; register webhook → `{AUTH_URL}/api/billing/webhooks/paddle`; confirm live approval if still pending in Paddle |
| Exactly what Cursor will automatically complete after that? | Wire env on Vercel; verify checkout provider resolves to Paddle; verify webhook signature path; smoke license issuance after payment event; if only “Live Approval” remains pending in Paddle dashboard, leave **only that** line under Paddle |

---

### B4. Upstash

| Question | Answer |
|----------|--------|
| Credential missing? | **YES** |
| Credential already present? | **NO** |
| Configuration incomplete? | **YES** (required for durable licensing on Vercel) |
| Exactly which values are missing? | `UPSTASH_REDIS_REST_URL`, `UPSTASH_REDIS_REST_TOKEN` (also set `LICENSE_STORE_SECRET` — see Environment Variables) |
| Exactly what Owner must provide? | Permanent Upstash Redis REST URL + token for the production Vercel project |
| Exactly what Cursor will automatically complete after that? | Configure Vercel env; verify durable store assert passes; smoke license create/read against Redis; remove Upstash from this checklist |

---

### B5. Admin Emails

| Question | Answer |
|----------|--------|
| Credential missing? | **YES** (no production allow-list emails set) |
| Credential already present? | **NO** |
| Configuration incomplete? | **YES** |
| Exactly which values are missing? | **Required:** `PORTAL_SUPER_ADMIN_EMAILS`, `PORTAL_ADMIN_EMAILS`, `PORTAL_SUPPORT_EMAILS`, `PORTAL_AUDITOR_EMAILS`. Optional: `PORTAL_COMMERCIAL_MANAGER_EMAILS`, `PORTAL_FINANCE_EMAILS`, `PORTAL_QA_EMAILS` |
| Exactly what Owner must provide? | Real emails for Owner / Administrator / Support / ReadOnly Admin (see `PRODUCTION_ADMIN_LIST.md`) |
| Exactly what Cursor will automatically complete after that? | Apply env lists; document login steps; verify `/portal/admin` role resolution after those users sign in; remove Admin Emails from this checklist |

---

### B6. Environment Variables (core auth / URLs)

| Question | Answer |
|----------|--------|
| Credential missing? | **YES** for secrets/URLs (`NODE_ENV=production` alone is not sufficient) |
| Credential already present? | **NO** live secrets (template only) |
| Configuration incomplete? | **YES** |
| Exactly which values are missing? | `AUTH_SECRET`, `NEXTAUTH_SECRET`, `LICENSE_STORE_SECRET`, `AUTH_URL`, `NEXTAUTH_URL`, `NEXT_PUBLIC_APP_URL` |
| Exactly what Owner must provide? | Long random secrets for Auth/License store; production public URL (after Domain DNS is ready) |
| Exactly what Cursor will automatically complete after that? | Populate Vercel Production env from the provided values; verify login session issuance; align OAuth/Paddle webhook base URLs; remove this Environment Variables item when all six values are set |

---

## C. Summary matrix

| Service | Missing? | Present? | Incomplete? | Blocks open sales? |
|---------|----------|----------|-------------|--------------------|
| Resend | YES | NO | YES | YES (transactional email) |
| Google OAuth | YES | NO | YES | NO if email/password only; YES if Google login promised |
| Paddle | YES | NO | YES | YES (self-serve checkout) |
| Upstash | YES | NO | YES | YES (Vercel durable licenses) |
| Admin Emails | YES | NO | YES | YES (ops access) |
| Environment Variables | YES | NO | YES | YES (auth/sessions) |
| Code Signing | YES | NO | YES | YES (Trusted installer) |
| Domain DNS | YES | NO | YES | YES (production hostname) |
| Legal Approval | YES | Drafts only | YES | YES (counsel sign-off) |

---

## D. How to unblock Cursor automation

For each service above: paste the missing values into **Vercel → Project → Settings → Environment Variables (Production)** (or provide them securely to the agent), then reply with which service was filled. Cursor will run the “automatically complete” steps for that service only and strike it from this file.
