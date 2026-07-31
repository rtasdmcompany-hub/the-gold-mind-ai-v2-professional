# RESEND_REPORT.md

**Product:** THE GOLD MIND PROFESSIONAL  
**Date:** 2026-07-31  
**Account:** Existing company Resend account (shared infrastructure OK) — no new Resend company account created  
**Brand policy:** Customer-facing From/support addresses must be THE GOLD MIND only (`thegoldmind.ai` placeholders until domain cutover).

---

## Verification (prior)

| Check | Result |
|-------|--------|
| API key valid | **PASS** (domains + send APIs accepted key) |
| Prior sending domain | `rtasstudio.com` — verified on shared account (infra only; **not** for customer From after brand separation) |
| Sending capability | **enabled** |
| DKIM / SPF on prior domain | **verified** |

---

## Brand separation — required From identity

| Item | Value |
|------|-------|
| Dedicated FROM identity | `THE GOLD MIND PROFESSIONAL <noreply@thegoldmind.ai>` |
| Support mailbox vars | `SUPPORT_EMAIL` / `SUPPORT_INBOX_EMAIL` = `support@thegoldmind.ai` |
| Billing / license / admin placeholders | `billing@` · `license@` · `admin@thegoldmind.ai` |
| Code constants | `src/lib/brand.ts` → `BRAND_RESEND_FROM` / `BRAND_EMAILS` |

**Owner action:** Add and verify domain **`thegoldmind.ai`** on the existing Resend account (SPF/DKIM). Until then, production customer mail must not use a non–Gold Mind From domain.

---

## Delivery tests (historical — prior From domain)

Sent to Resend test sink `delivered@resend.dev` (accepted) while validating the API key:

| Template path | HTTP | Message id |
|---------------|------|------------|
| License delivery | 200 | `40059838-691a-43d4-b1ed-9181ff4be190` |
| Password reset | 200 | `0c5fd4bf-f886-416e-a8e0-3a7b5c3d18df` |
| Welcome / email verification | 200 | `ca99218d-d79e-4bf8-9d4f-844f331a6cfa` |
| Contact / support | 200 | `d774c26b-67f2-489b-b711-ed2de93b90ce` |
| Billing receipt | 200 | `b3262159-9f4f-4424-91f0-8da71e205dbe` |

Re-run delivery tests from `noreply@thegoldmind.ai` after domain verification.

Portal code paths use Resend for license, password reset, verification, contact, and billing delivery (`sendTransactionalEmail` / `deliverBillingEmail`) when env is set. Mailer falls back to `BRAND_RESEND_FROM` if env From is empty.

---

## Configuration applied (local secure env — not committed)

- `RESEND_API_KEY` = set in `.env.production` / `.env.local` (gitignored)
- `RESEND_FROM_EMAIL` = `THE GOLD MIND PROFESSIONAL <noreply@thegoldmind.ai>`
- `SUPPORT_EMAIL` / `SUPPORT_INBOX_EMAIL` = `support@thegoldmind.ai`

**Owner must paste into Vercel Production** and complete `thegoldmind.ai` domain verification on Resend.

---

## Owner action remaining for Resend?

| Item | Status |
|------|--------|
| API key | DONE |
| Verify `thegoldmind.ai` on Resend | **WAITING ON OWNER** |
| Paste env to Vercel | **WAITING ON OWNER** |
| Re-test delivery from Gold Mind From | After domain verify |
