# Email delivery + Chrome “Dangerous” (Owner live-test)

**Product:** THE GOLD MIND PROFESSIONAL 1.0.0  
**Updated:** 2026-08-01  
**Production:** https://the-gold-mind-ai-v2-professional.vercel.app

---

## Why signup said “email sent” but Gmail got nothing

Two production blockers were found:

1. **`RESEND_API_KEY` was missing from Vercel Production**  
   Portal queued mail to the outbox only and showed the verify link on the page as a fallback.

2. **`thegoldmind.ai` is not verified on Resend** (and DNS does not resolve yet)  
   Even with an API key, Resend rejects `noreply@thegoldmind.ai` until the domain is added + SPF/DKIM verified.  
   Only shared infra domain `rtasstudio.com` is currently verified on the Resend account.

### Interim fix applied

| Variable | Production value (intent) |
|----------|---------------------------|
| `RESEND_API_KEY` | Set on Vercel Production |
| `RESEND_FROM_EMAIL` | `THE GOLD MIND PROFESSIONAL <noreply@rtasstudio.com>` (verified cutover From) |

Display name remains **THE GOLD MIND PROFESSIONAL**. Shared Resend/infra domain is temporary until brand DNS is ready.

### Owner follow-up (brand mail)

1. Point DNS for `thegoldmind.ai` at your registrar / Vercel.
2. In Resend → Domains → add + verify `thegoldmind.ai` (SPF/DKIM).
3. Switch Production `RESEND_FROM_EMAIL` back to:  
   `THE GOLD MIND PROFESSIONAL <noreply@thegoldmind.ai>`
4. Re-test signup → real inbox delivery.

### Immediate workaround (already on screen)

If the register page shows a yellow **Verification link**, open it directly — the account activates without waiting for Gmail. Or use **Google Sign-In** (creates a verified account).

---

## Why Chrome shows “Dangerous” next to the URL

Chrome Safe Browsing can flag new `*.vercel.app` hosts that look like login / financial / trading portals, especially before a custom domain and reputation exist. This is **not** an application crash and is separate from HTTPS (the lock/TLS can still be valid).

### What reduces / clears the flag

1. **Attach a real custom domain** (e.g. `thegoldmind.ai` or `portal.thegoldmind.ai`) to this Vercel project and use that URL publicly.
2. Open [Google Safe Browsing Status](https://transparencyreport.google.com/safe-browsing/search) for the URL; if flagged, submit a **review request** from Search Console / Safe Browsing.
3. Prefer the custom domain in marketing, Setup.exe portal base, and OAuth redirect URIs — stop sharing only the long `vercel.app` hostname once DNS is live.

Until then, Owner can proceed via the on-page verify link or Google Sign-In even if Chrome shows the warning.
