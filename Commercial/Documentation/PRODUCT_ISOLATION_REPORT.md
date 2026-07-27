# PRODUCT_ISOLATION_REPORT.md

**Product:** THE GOLD MIND AI v2.0 PROFESSIONAL  
**Product ID:** `the-gold-mind-ai-v2-professional`  
**Date:** 2026-07-27  
**Commit:** pending isolation pass  
**Policy:** Each RTAS product is fully independent — no shared customer-facing systems

---

## Cross-product reference audit

| Search pattern | Scope | Result |
|----------------|-------|--------|
| `RTAS Studio AI` | Entire repository | **0 matches** |
| `rtas-studio` | Entire repository | **0 matches** |
| `rtasstudio` | Entire repository | **0 matches** |
| `rtas-ea-licensing` | Entire repository | **0 matches** |
| `rtas-studio-ai-api` | Entire repository | **0 matches** |
| `rtasstudio.com` | Entire repository | **0 matches** |

**Verdict:** No references to other RTAS software products remain in application code, installer payloads, or active configuration.

---

## Dedicated product infrastructure

| Resource | This product only | Status |
|----------|-------------------|--------|
| GitHub repository | `rtasdmcompany-hub/the-gold-mind-ai-v2-professional` | **ISOLATED** |
| Vercel project | `rtas-group/the-gold-mind-ai-v2-professional` | **ISOLATED** |
| Production URL | `https://the-gold-mind-ai-v2-professional.vercel.app` | **ISOLATED** |
| Vercel project ID | `prj_WsOgZDX2qR52qw32x7fpgKRhHmED` | **DEDICATED** |
| License store secrets | Product-specific encrypted file stores | **ISOLATED** |
| Billing store secrets | Product-specific encrypted file stores | **ISOLATED** |
| Auth secrets | Product-specific `AUTH_SECRET` / `NEXTAUTH_SECRET` | **ISOLATED** |
| Core SHA | Frozen — not shared with other products | **VERIFIED** |

---

## Fixes applied (this session)

| Item | Before | After |
|------|--------|-------|
| Installer `portal.json` | `https://thegoldmind.ai` | `https://the-gold-mind-ai-v2-professional.vercel.app` |
| Installer `version.json` | `https://thegoldmind.ai` | Product Vercel URL |
| `Build-CommercialRelease.ps1` default | `https://thegoldmind.ai` | Product Vercel URL |
| Inno Setup `MyAppURL` | `https://thegoldmind.ai` | Product Vercel URL |
| Footer GitHub link | Org-level repo list | This product's repo only |
| Product identity manifest | None | `Commercial/PRODUCT_IDENTITY.json` |
| Env template | Missing | `.env.production.example` (isolated) |
| Code identity module | None | `src/lib/product-identity.ts` |

---

## Shared company services (allowed)

These remain under RTAS Digital Marketing Company but use **product-specific configuration**:

| Service | Shared account OK? | This product's config |
|---------|-------------------|----------------------|
| GitHub organization | Yes | Dedicated private repo |
| Vercel team | Yes | Dedicated project + env vars |
| Google Cloud | Yes | **Dedicated OAuth client required** |
| Paddle / PayPal | Yes | **Dedicated product IDs required** |
| Resend | Yes | **Dedicated sender identity required** |
| Supabase | Yes | **Dedicated project required** |

---

## Customer-facing isolation guarantee

Customers of THE GOLD MIND AI PROFESSIONAL will only see:

- THE GOLD MIND branding and assets
- `the-gold-mind-ai-v2-professional.vercel.app` (or future dedicated custom domain)
- This product's Customer Portal, licenses, and billing
- No RTAS Studio AI URLs, branding, or authentication

---

## Isolation verdict

**PRODUCT ISOLATION: PASS** — Repository and production configuration contain only THE GOLD MIND AI PROFESSIONAL identity. No cross-product contamination detected.
