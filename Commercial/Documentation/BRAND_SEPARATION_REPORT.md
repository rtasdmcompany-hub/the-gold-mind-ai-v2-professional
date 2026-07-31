# BRAND_SEPARATION_REPORT.md

**Product:** THE GOLD MIND PROFESSIONAL  
**Date:** 2026-07-31  
**Policy:** THE GOLD MIND is a **separate commercial product**. Shared infrastructure accounts are allowed. Customer-facing branding must be THE GOLD MIND only.

---

## Verdict

**PASS — customer-facing brand separation complete in code and published commercial surfaces.**

Infrastructure API accounts (Resend, Google Cloud, Paddle, Upstash) were **not** changed.  
Only product identity, emails, portal chrome, legal copy, metadata/SEO, notifications/signatures, and related commercial docs were updated.

Final domain cutover remains an Owner ops step: verify `thegoldmind.ai` on Resend and update DNS/env when the custom domain is live.

---

## Separation rules applied

| Allowed | Forbidden in customer-facing surfaces |
|---------|----------------------------------------|
| Same Resend / Google / Paddle / Upstash accounts | RTAS Studio product name |
| Same Vercel/GitHub org as hosting | RTAS Group / RTAS Digital badges or lockups |
| Internal infra project slugs | `@rtasstudio.com` / `@rtas.group` From or support addresses |
| Historical internal path notes in scripts | Publisher/legal entity named RTAS in portal legal pages |

---

## Canonical brand constants

File: `Commercial/CustomerPortal/web/src/lib/brand.ts`

| Constant | Value |
|----------|-------|
| Product | THE GOLD MIND PROFESSIONAL |
| Email domain | `thegoldmind.ai` (placeholder until DNS cutover) |
| support | `support@thegoldmind.ai` |
| admin | `admin@thegoldmind.ai` |
| billing | `billing@thegoldmind.ai` |
| license | `license@thegoldmind.ai` |
| noreply / Resend From | `THE GOLD MIND PROFESSIONAL <noreply@thegoldmind.ai>` |

Mailer falls back to `BRAND_RESEND_FROM` when `RESEND_FROM_EMAIL` is unset. Contact intake defaults to `BRAND_EMAILS.support`.

---

## Surfaces updated

### Email sender / support / billing / license / admin

- Local gitignored `.env.production` / `.env.local`: From + support → `@thegoldmind.ai`
- `.env.production.example`: Gold Mind placeholders
- License emails signatures: THE GOLD MIND PROFESSIONAL
- Billing mail footer: THE GOLD MIND PROFESSIONAL
- i18n `regional.support.contact` → `partners@thegoldmind.ai · support@thegoldmind.ai`
- Demo/local assignees: `@thegoldmind.local` (non-production seeds)

### Portal branding / footer / metadata / SEO

- Root layout authors/publisher/keywords/Open Graph: THE GOLD MIND
- Twitter description: THE GOLD MIND (no RTAS)
- `site.webmanifest` description: THE GOLD MIND
- Enterprise footer: Gold Mind logo only; copyright THE GOLD MIND PROFESSIONAL
- Portal layout: parent-company badges removed
- `BrandLogo.tsx`: RTAS badge components removed from customer UI
- About / Company / Contact / Login eyebrows and copy: THE GOLD MIND
- Admin portal subtitle: THE GOLD MIND commercial operations center
- i18n `common.brand`: THE GOLD MIND (all locales)

### Legal documents

- Privacy, Terms, EULA, Refund, Disclaimer, Cookies: publisher / grants / liability = THE GOLD MIND
- Contact product line: support + billing `@thegoldmind.ai`

### Notifications / partner / compliance strings

- Website-launch notification signatures: — THE GOLD MIND
- Partner desk issuer: THE GOLD MIND Partner Desk
- Market compliance copyright: THE GOLD MIND
- Mobile companion package id placeholder: `com.thegoldmind.companion`

### Installer (customer-visible)

- Inno `AppPublisher` → THE GOLD MIND
- Payload EULA summary → THE GOLD MIND (+ support@thegoldmind.ai)
- Windows `AppId` string left unchanged for upgrade continuity (not shown as brand chrome)

### Commercial packaging / identity

- `Commercial/PRODUCT_IDENTITY.json` — parent/group → THE GOLD MIND; brandEmails block added
- Release notes contact → `support@thegoldmind.ai`
- SBOM publisher → THE GOLD MIND
- Market Edition listing/manifest/disclaimer → THE GOLD MIND
- `BRAND_STANDARD.md`, `COMMUNICATION_TEMPLATES.md`, Assets README, Owner/Resend/Production config docs aligned

---

## Infrastructure intentionally unchanged

| Service | Status |
|---------|--------|
| Resend API account / API key | Unchanged (shared OK) |
| Google OAuth client IDs | Unchanged (shared OK) |
| Paddle / Upstash account wiring | Unchanged |
| Vercel project slug / GitHub org paths | Unchanged (infra naming) |
| Trading Engine / MT5 strategy / Core | Untouched |

---

## Domain cutover checklist (Owner — only values to change later)

When `thegoldmind.ai` is ready:

1. Verify domain on **existing** Resend account (SPF/DKIM).
2. Confirm mailboxes or forwarding: `support@` `admin@` `billing@` `license@` `noreply@`.
3. Set Vercel Production:
   - `RESEND_FROM_EMAIL=THE GOLD MIND PROFESSIONAL <noreply@thegoldmind.ai>`
   - `SUPPORT_EMAIL` / `SUPPORT_INBOX_EMAIL=support@thegoldmind.ai`
4. Point portal DNS / update `AUTH_URL` · `NEXTAUTH_URL` · `NEXT_PUBLIC_APP_URL` if using custom host.
5. If domain string ever changes, update **one** constant: `BRAND_EMAIL_DOMAIN` in `src/lib/brand.ts` (plus env).
6. Re-run Resend delivery tests from the Gold Mind From address.
7. Confirm Google OAuth consent screen product name is THE GOLD MIND PROFESSIONAL.

---

## Residual non-customer references (acceptable)

| Location | Why kept |
|----------|----------|
| Build scripts with historical Windows paths containing “RTAS Softwear” | Local path strings; not shipped UI |
| Asset pipeline filenames `rtas-*-badge.png` on disk | Not rendered in portal footer/chrome after separation |
| Docs describing isolation from “RTAS Studio AI” as a forbidden peer product | Negative allowlist / isolation policy |
| Vercel/GitHub org slug `rtas-group` / `rtasdmcompany-hub` | Infrastructure account naming |

Customer-visible portal `src/`, locales, public manifest, legal routes, and transactional email copy: **no RTAS Studio / RTAS Group customer branding remaining.**

---

## Owner follow-ups

See `OWNER_ACTION_REQUIRED.md` §3d and `RESEND_REPORT.md`:

- Verify `thegoldmind.ai` on Resend  
- Paste updated From/support env into Vercel  
- Legal counsel sign-off on THE GOLD MIND publisher drafts  

---

## Summary

THE GOLD MIND customer identity is fully separated from RTAS Studio / RTAS Group customer-facing branding. Shared infra accounts remain. Placeholders are centralized so only final domain values need updating at cutover.
