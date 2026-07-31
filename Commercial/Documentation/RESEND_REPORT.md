# RESEND_REPORT.md

**Product:** THE GOLD MIND PROFESSIONAL  
**Date:** 2026-07-31  
**Account:** Existing company Resend account (rtasstudio.com) — no new Resend company account created  

---

## Verification

| Check | Result |
|-------|--------|
| API key valid | **PASS** (domains + send APIs accepted key) |
| Sending domain | `rtasstudio.com` — **verified** |
| Sending capability | **enabled** |
| DKIM (`resend._domainkey`) | **verified** |
| SPF (`send` TXT/MX) | **verified** |
| Dedicated FROM identity | `THE GOLD MIND PROFESSIONAL <noreply@rtasstudio.com>` |
| Support mailbox vars | `SUPPORT_EMAIL` / `SUPPORT_INBOX_EMAIL` = `support@rtasstudio.com` |

---

## Delivery tests (Resend accepted)

Sent to Resend test sink `delivered@resend.dev` from production FROM identity:

| Template path | HTTP | Message id |
|---------------|------|------------|
| License delivery | 200 | `40059838-691a-43d4-b1ed-9181ff4be190` |
| Password reset | 200 | `0c5fd4bf-f886-416e-a8e0-3a7b5c3d18df` |
| Welcome / email verification | 200 | `ca99218d-d79e-4bf8-9d4f-844f331a6cfa` |
| Contact / support | 200 | `d774c26b-67f2-489b-b711-ed2de93b90ce` |
| Billing receipt | 200 | `b3262159-9f4f-4424-91f0-8da71e205dbe` |

Portal code paths already use Resend for license, password reset, verification, contact, and billing delivery (`sendTransactionalEmail` / `deliverBillingEmail`) when env is set.

---

## Configuration applied (local secure env — not committed)

- `RESEND_API_KEY` = set in `.env.production` / `.env.local` (gitignored)
- `RESEND_FROM_EMAIL` = `THE GOLD MIND PROFESSIONAL <noreply@rtasstudio.com>`

**Owner must still paste these two values into Vercel Production Environment Variables** (secrets cannot be pushed from this agent to Vercel without Vercel auth).

---

## Owner action remaining for Resend?

**NO for API/domain/SPF/DKIM/sender identity** — company domain already verified.  

**YES (ops paste only):** Add `RESEND_API_KEY` + `RESEND_FROM_EMAIL` to **Vercel Production** so the deployed portal uses them (cannot be done here without Vercel project access).
