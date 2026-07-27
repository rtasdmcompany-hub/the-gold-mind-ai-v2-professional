# MISSING_PRODUCTION_SECRETS.md

**Product:** THE GOLD MIND AI v2.0 PROFESSIONAL  
**Production URL:** https://the-gold-mind-ai-v2-professional.vercel.app  
**Date:** 2026-07-27  
**Commit:** `3cd9867`  
**Status:** All recoverable application issues resolved. Only external provider credentials remain.

---

## Production verification summary (post-deploy)

| Workflow | Result |
|----------|--------|
| Public website | 200 OK |
| `/login` (no redirect loop) | 200 OK |
| `/portal` anonymous → login | 307 → `/login` |
| `/api/auth/providers` | 200 OK |
| `/api/auth/csrf` | 200 OK |
| `/api/health` | 200 · **healthy** |
| `/api/v1/health` | 200 OK |
| `/api/mobile/health` | 200 OK |
| Demo login → session | OK |
| `/portal` dashboard | 200 OK |
| `/portal/licenses` | 200 OK |
| `/portal/downloads` | 200 OK |
| `/portal/devices` (MT5) | 200 OK |
| `/portal/billing` | 200 OK |
| `/portal/support` | 200 OK |
| `/portal/account` | 200 OK |
| License create API | 200 OK |
| Lint | PASS |
| Vercel deploy | READY |

---

## Missing production secrets (Owner configuration only)

These are **not application bugs**. The platform runs without them using demo auth, sandbox payments, encrypted file stores, and billing email outbox.

| Variable Name | Reason Required | Where It Is Used | Can Application Run Without It? |
|---------------|-----------------|------------------|-------------------------------|
| `GOOGLE_CLIENT_ID` | Live Google OAuth sign-in for customers | `src/auth.ts` · Google provider registration | **Yes** (demo credentials provider active) |
| `GOOGLE_CLIENT_SECRET` | Live Google OAuth sign-in for customers | `src/auth.ts` · Google provider registration | **Yes** (demo credentials provider active) |
| `NEXTAUTH_SECRET` | JWT session signing | `src/auth.ts` · NextAuth | **No** — **already configured in Vercel production** |
| `AUTH_SECRET` | Auth.js v5 session signing (alias) | `src/auth.ts` · middleware | **No** — **already configured in Vercel production** |
| `NEXTAUTH_URL` | Canonical auth callback base URL | NextAuth · middleware CSRF | **No** — **already configured in Vercel production** |
| `NEXT_PUBLIC_SUPABASE_URL` | Durable Postgres-backed persistence | Performance/deployment checks · optional future DB | **Yes** (encrypted `/tmp` commercial stores) |
| `NEXT_PUBLIC_SUPABASE_ANON_KEY` | Client-side Supabase access | Optional Supabase client | **Yes** |
| `SUPABASE_SERVICE_ROLE_KEY` | Server-side Supabase admin ops | Optional Supabase integration | **Yes** |
| `SUPABASE_JWT_SECRET` | Supabase JWT validation | Optional Supabase auth bridge | **Yes** |
| `PADDLE_VENDOR_ID` | Live Paddle checkout | `src/server/billing/` · webhook handlers | **Yes** (`PAYMENT_MODE=sandbox`) |
| `PADDLE_API_KEY` | Live Paddle API calls | Billing checkout · subscription sync | **Yes** (`PAYMENT_MODE=sandbox`) |
| `PADDLE_WEBHOOK_SECRET` | Verify Paddle webhook signatures | `/api/billing/webhooks/[provider]` | **Yes** (sandbox / no live webhooks) |
| `PAYPAL_CLIENT_ID` | Live PayPal checkout | Billing · PayPal provider | **Yes** (`PAYMENT_MODE=sandbox`) |
| `PAYPAL_CLIENT_SECRET` | Live PayPal API auth | Billing · PayPal provider | **Yes** (`PAYMENT_MODE=sandbox`) |
| `PAYPAL_WEBHOOK_SECRET` | Verify PayPal webhook signatures | `/api/billing/webhooks/[provider]` | **Yes** (sandbox) |
| `RESEND_API_KEY` | Live outbound transactional email | Billing notifications · contact relay | **Yes** (outbox store; no external delivery) |
| `RESEND_FROM_EMAIL` | Verified sender domain for Resend | Email From header | **Yes** (outbox only) |
| `UPSTASH_REDIS_REST_URL` | Multi-instance shared cache/rate-limit | `src/server/cloud/cache.ts` | **Yes** (in-memory fallback) |
| `UPSTASH_REDIS_REST_TOKEN` | Upstash auth | Cache backend | **Yes** (in-memory fallback) |

**Note:** Prisma is not used in this product. Persistence is encrypted commercial file stores with serverless-safe `/tmp` paths on Vercel.

---

## Recommended Owner actions (priority order)

1. **Google OAuth** — `GOOGLE_CLIENT_ID` + `GOOGLE_CLIENT_SECRET` + authorized redirect URI  
   `https://the-gold-mind-ai-v2-professional.vercel.app/api/auth/callback/google`

2. **Resend** — `RESEND_API_KEY` + `RESEND_FROM_EMAIL` for license/billing/support emails

3. **Paddle or PayPal live** — when ready to accept real payments (set `PAYMENT_MODE=live`)

4. **Supabase** — when durable cross-instance persistence is required (licenses survive cold starts)

5. **Upstash Redis** — when scaling beyond single-instance memory cache

---

## FINAL DECISION

# READY FOR LIVE CUSTOMER TESTING

All recoverable software defects are resolved. Customer workflows operate end-to-end via demo authentication and sandbox billing. Remaining items in the table above are external provider credentials for production-grade OAuth, payments, email, and durable DB — not application blockers.
