# OWNER_ACTION_REQUIRED.md

**Product:** THE GOLD MIND AI v2.0 PROFESSIONAL  
**Mode:** RELEASE CANDIDATE / PRODUCTION CLOSURE  
**Generated:** 2026-07-31  

---

## 1. Code Signing Certificate

**Status:** Waiting for Owner

Provide Authenticode Standard or EV certificate (and password/thumbprint). Authorize signed rebuild of `Setup.exe` / `TheGoldMindSetup.exe`.

---

## 2. Paddle Live Approval

**Status:** Waiting for Owner

Provide production `PADDLE_VENDOR_ID`, `PADDLE_PRICE_ID`, `PADDLE_API_KEY`, `PADDLE_WEBHOOK_SECRET`. Confirm live webhook endpoint in the Paddle dashboard.

---

## 3. Resend DNS

**Status:** Waiting for Owner

Create Resend sending domain. Publish SPF/DKIM DNS records. Set `RESEND_API_KEY` and `RESEND_FROM_EMAIL` on production.

---

## 4. Domain DNS

**Status:** Waiting for Owner

Point production portal/marketing hostname(s) to the live Vercel deployment. Confirm HTTPS and redirects.

---

## 5. Production Environment Variables

**Status:** Waiting for Owner

Configure production secrets on Vercel (non-exhaustive): `AUTH_SECRET`, `AUTH_URL`, `NEXTAUTH_URL`, Upstash Redis URL/token, billing/mail/OAuth keys, and related production flags.

---

## 6. Google OAuth Credentials

**Status:** Waiting for Owner

Create Google Cloud OAuth client for the production portal origin/callback. Set Google client ID/secret env vars.

---

## 7. Legal Approval

**Status:** Waiting for Owner

Counsel sign-off on Terms, Privacy, EULA, and customer-facing commercial copy.

---

## 8. Upstash Redis (Permanent)

**Status:** Waiting for Owner

Claim/configure permanent Upstash Redis for Vercel. Set `UPSTASH_REDIS_REST_URL` and `UPSTASH_REDIS_REST_TOKEN`.

---

## 9. Admin Email Allow-lists

**Status:** Waiting for Owner

Set `PORTAL_SUPER_ADMIN_EMAILS` and `PORTAL_ADMIN_EMAILS` (and related role allow-lists). Local privilege defaults are removed.

---

## 10. Windows SmartScreen Reputation

**Status:** Waiting for Owner

After code signing, accumulate publisher reputation / submit for SmartScreen if warnings persist for first customers.
