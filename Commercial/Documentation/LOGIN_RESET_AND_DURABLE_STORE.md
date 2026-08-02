# Login / password reset failures (2026-08-02)

**Product:** THE GOLD MIND PROFESSIONAL  
**Production:** https://the-gold-mind-ai-v2-professional.vercel.app

## What customers saw

- Login with a previously working email → `CredentialsSignin` / “incorrect password”
- Forgot password → UI said “Check your email” but **no reset mail** arrived

## Root causes

1. **Vercel Upstash placeholders**  
   `UPSTASH_REDIS_REST_URL` and `UPSTASH_REDIS_REST_TOKEN` were set to the literal string `REPLACE_IF_AVAILABLE`.  
   The portal treated durable Redis as “configured”, Redis calls failed, and account/license state fell back to ephemeral `/tmp` + memory. **Redeploys / cold starts can drop password accounts**, so reset finds no account and silently sends nothing.

2. **Forgot-password UI always claimed success**  
   Anti-enumeration returned `ok: true` even when no mail was sent, and the page always said “we sent a link”.

3. **`RESEND_FROM_EMAIL` used unverified `noreply@thegoldmind.ai`**  
   Cutover From for the current Resend account is `noreply@rtasstudio.com` until `thegoldmind.ai` DNS + Resend verification are complete.

## Fixes shipped

- Reject placeholder / non-`*.upstash.io` Redis env values (`cache.ts`)
- Remove placeholder Upstash vars from Vercel Production
- Always return an **on-page reset link** when a reset token is created
- Honest forgot-password copy (`mailed=0|1`) + register / Google fallbacks
- Successful password reset also marks the email verified
- Clearer login errors: missing account / unverified / Google-only
- Production `RESEND_FROM_EMAIL` → `THE GOLD MIND PROFESSIONAL <noreply@rtasstudio.com>`

## Owner action required (durable accounts + licenses)

Create a real Upstash Redis database, then set on Vercel **Production**:

| Variable | Value |
|----------|--------|
| `UPSTASH_REDIS_REST_URL` | `https://….upstash.io` |
| `UPSTASH_REDIS_REST_TOKEN` | Upstash REST token |

Without this, **accounts and license keys will not reliably survive redeploys**.

## Customer recovery (now)

For affected emails (example: `atiqvilog@gmail.com`):

1. Prefer **Google Sign-In** with the same Gmail, **or**
2. **Register again** with the same email → confirm via on-page verify link if mail is delayed → sign in  
3. Or use **Forgot password** — if a reset token can be created, the **reset link appears on the page** even when inbox delivery fails
