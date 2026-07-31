# PRODUCTION_UX_REPORT.md

**Product:** THE GOLD MIND AI v2.0 PROFESSIONAL  
**URL:** https://the-gold-mind-ai-v2-professional.vercel.app  
**Date:** 2026-07-27  

---

## Summary

Marketing UX (home, pricing, docs, legal, branding) is polished and on-brand.  
**Customer journey UX fails at the first authenticated step** because Sign-in / Customer Portal enter a redirect loop.

**UX readiness for live customers: NOT READY.**

---

## Observed journeys

### A) Anonymous visitor (PASS)

1. Land on home → brand hero “THE GOLD MIND / PROFESSIONAL” visible.  
2. Nav: Home, Pricing, Documentation, Developers, Contact, Risk, Customer Portal.  
3. Footer: official Gold Mind + RTAS Group + RTAS Digital badges.  
4. Pricing shows Trial / Monthly / Yearly / Lifetime clearly with risk disclaimer.  
5. Docs links to legal pages; public legal pages load.

### B) Sign-in attempt (FAIL)

1. User clicks **Sign in** / **Customer Portal**.  
2. Browser/network enters `/login` → `/portal` → `/login` loop.  
3. Login form never stably renders in production.  
4. Google OAuth button cannot be evaluated (auth config 500).

### C) Post-login product use (FAIL — blocked)

Cannot verify:

- Dashboard clarity  
- License list / activation wizard UX  
- Installer download UX  
- Device / MT5 detection messaging  
- Billing checkout UX  

---

## Branding UX

| Element | Result |
|---------|--------|
| Header logo | PASS |
| Hero lockup | PASS |
| Footer brand stack | PASS |
| Favicon / PWA icons | PASS |
| Pricing visual hierarchy | PASS |
| Risk messaging present | PASS |

---

## Accessibility / content notes

- Titles sometimes duplicate brand suffix (`Pricing — … · THE GOLD MIND PROFESSIONAL`) — minor polish.  
- Legal pages labeled draft in docs — acceptable for controlled test only if disclosed; not ideal for paying customers.  
- Ask AI widget present on home — anonymous surface OK.

---

## Mobile UX

- Public layouts use flex/wrap patterns suitable for mobile.  
- Full mobile PAT of portal screens **blocked by auth**.  
- Recommendation: after auth fix, re-test 375×812 and 768×1024 viewports on login + portal + downloads.

---

## UX blockers (priority)

1. Restore anonymous `/login` (HTTP 200) with visible Google and/or approved auth method.  
2. Ensure first-time customer can reach dashboard within 1 redirect.  
3. Provide clear empty-states for licenses/downloads when none purchased.  
4. Surface “payments not configured” only in admin — customers should see clean checkout when PSP ready.

---

## Verdict

Brochure UX: **good**.  
Customer product UX: **blocked**.
