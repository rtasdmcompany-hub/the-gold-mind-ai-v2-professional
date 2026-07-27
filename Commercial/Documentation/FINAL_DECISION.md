# FINAL_DECISION.md

**Product:** THE GOLD MIND AI v2.0 PROFESSIONAL  
**Date:** 2026-07-27  
**Decision type:** Enterprise Product Isolation

---

# PRODUCT FULLY ISOLATED AND CERTIFIED

---

## Summary

THE GOLD MIND AI v2.0 PROFESSIONAL is verified as a fully isolated commercial product. Zero cross-references to RTAS Studio AI or any other RTAS software remain in application code, installer configuration, or production deployment settings.

## Isolated resources confirmed

- GitHub: `rtasdmcompany-hub/the-gold-mind-ai-v2-professional`
- Vercel: `rtas-group/the-gold-mind-ai-v2-professional`
- URL: `https://the-gold-mind-ai-v2-professional.vercel.app`
- License, billing, and audit stores: product-specific encrypted secrets
- Installer portal base: updated to this product's production URL

## Owner follow-up (product-specific credentials — not isolation failures)

These require **new credentials created for this product only** (never reused from other RTAS products):

1. **Google OAuth client** — `GOOGLE_CLIENT_ID` + `GOOGLE_CLIENT_SECRET`  
   Redirect: `https://the-gold-mind-ai-v2-professional.vercel.app/api/auth/callback/google`

2. **Supabase project** — when durable cross-instance persistence is required

3. **Paddle / PayPal product IDs** — when live billing is enabled

4. **Resend sender identity** — for transactional email

5. **Custom domain** — optional `thegoldmind.ai` DNS to this Vercel project

See `PRODUCTION_CONFIGURATION_REPORT.md` for full configuration details.
