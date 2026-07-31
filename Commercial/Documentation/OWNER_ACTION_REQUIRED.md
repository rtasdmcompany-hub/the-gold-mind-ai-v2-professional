# OWNER_ACTION_REQUIRED.md

**Product:** THE GOLD MIND PROFESSIONAL 1.0.0  
**Updated:** 2026-07-31  
**Rule:** Only items that cannot be completed without Owner identity, purchased certificates, DNS ownership, live PSP approval, or legal counsel.

**Credential scan result:** No Resend / Google / Upstash / Paddle / Auth secrets were present in the repository or runtime environment. Those cannot be auto-configured.

---

## 1. Code Signing Certificate

**Status:** Waiting for Owner

Provide Authenticode Standard or EV certificate. Authorize signed rebuild of `Setup.exe` / `TheGoldMindSetup.exe` and refresh published SHA256 hashes. Monitor SmartScreen after first customer installs.

---

## 2. Production Domain DNS

**Status:** Waiting for Owner

Point the commercial hostname to Vercel and confirm HTTPS. Set `AUTH_URL`, `NEXTAUTH_URL`, and `NEXT_PUBLIC_APP_URL` to that hostname.

---

## 3. Production Credentials and Live Service Activation

**Status:** Waiting for Owner

No live secrets were available to apply automatically. Using  
`Commercial/CustomerPortal/web/.env.production` / `.env.production.example` as the checklist, Owner must create and paste:

1. `AUTH_SECRET` / `NEXTAUTH_SECRET` / `LICENSE_STORE_SECRET`
2. Upstash Redis URL + token
3. Admin emails (`PORTAL_SUPER_ADMIN_EMAILS`, `PORTAL_ADMIN_EMAILS`, `PORTAL_SUPPORT_EMAILS`, `PORTAL_AUDITOR_EMAILS`) — see `PRODUCTION_ADMIN_LIST.md`
4. Resend API key + from-address, plus SPF/DKIM for the sending domain
5. Paddle live vendor/price/API/webhook secrets, enable live mode, register webhook URL
6. Google OAuth client for the production origin (if offering Google login)

Until these values exist in Vercel Production, open self-serve sales and durable licensing on Vercel remain blocked.

---

## 4. Legal Approval

**Status:** Waiting for Owner

Production drafts are published for Privacy, Terms, EULA, Refund, Cookies, Disclaimer, and Risk.  
Counsel must review and approve before open commercial launch.
