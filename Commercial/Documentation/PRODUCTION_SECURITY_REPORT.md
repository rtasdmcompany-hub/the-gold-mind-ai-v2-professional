# PRODUCTION_SECURITY_REPORT.md

**Product:** THE GOLD MIND AI v2.0 PROFESSIONAL  
**URL:** https://the-gold-mind-ai-v2-professional.vercel.app  
**Date:** 2026-07-27  
**Scope:** Production commercial portal only (Trading Engine / Core SHA out of scope)

---

## Summary

Transport and edge security headers are strong. Authentication is **not production-safe** in the current deployment: NextAuth returns configuration errors, and session middleware produces a login/portal redirect loop.

**Security posture for customer go-live: NOT ACCEPTABLE.**

---

## Findings

| ID | Severity | Finding | Status |
|----|----------|---------|--------|
| SEC-01 | **Critical** | NextAuth server configuration failure (`/api/auth/*` → 500) | Open |
| SEC-02 | **Critical** | Session gate inconsistency causes `/login` ↔ `/portal` redirect loop | Open |
| SEC-03 | **High** | Auth health reports `degraded` — session secret missing/invalid in production | Open / Config Pending |
| SEC-04 | **Medium** | Google OAuth not configured — no production identity provider available | Configuration Pending |
| SEC-05 | **Medium** | Payment webhooks/credentials not configured for live PSP | Configuration Pending |
| SEC-06 | **Low** | `X-XSS-Protection` header missing | Accepted (modern browsers; CSP present) |
| SEC-07 | **Info** | CSP allows `'unsafe-inline'` / `'unsafe-eval'` for scripts | Residual risk; common for Next.js |
| SEC-08 | **Info** | `X-Tgm-Cloud: commercial-isolated` present | Positive isolation signal |

---

## Verified controls (PASS)

- **HTTPS / HSTS:** `Strict-Transport-Security: max-age=31536000; includeSubDomains`
- **Clickjacking:** `X-Frame-Options: DENY` + CSP `frame-ancestors 'none'`
- **MIME sniffing:** `X-Content-Type-Options: nosniff`
- **Referrer:** `strict-origin-when-cross-origin`
- **Permissions-Policy:** camera/microphone/geolocation disabled
- **CSP baseline:** `default-src 'self'` with constrained connect/img
- **CSRF helper** present in middleware for mutating API paths (not fully exercisable while auth is down)
- **Core isolation:** No Trading Engine exposure observed on commercial endpoints

---

## Auth & session analysis

Observed without cookies:

1. `GET /login` → **307** `Location: /portal`  
2. `GET /portal` → **307** `Location: /login`  
3. Loop continues (verified with `--max-redirs 3`)

`GET /api/auth/providers` body:

```json
{"message":"There was a problem with the server configuration. Check the server logs for more information."}
```

Interpretation: Production lacks a valid Auth.js secret and/or providers configuration. Middleware and page-level session checks disagree, creating an availability + security failure (auth cannot complete).

Demo credentials provider is correctly **disabled in production** unless `PORTAL_ALLOW_DEMO_IN_PROD=true` (code review). That is good security, but currently leaves **no working login path**.

---

## Required security remediation (Owner + DevOps)

1. Set Vercel Production env:
   - `AUTH_SECRET` (or `NEXTAUTH_SECRET`) — cryptographically strong  
   - `NEXTAUTH_URL=https://the-gold-mind-ai-v2-professional.vercel.app`
2. Configure Google OAuth for this product only; add redirect URI:
   - `https://the-gold-mind-ai-v2-professional.vercel.app/api/auth/callback/google`
3. Redeploy and verify:
   - `/login` returns **200** (not redirect to `/portal`) when anonymous  
   - `/api/auth/providers` returns **200** JSON  
   - Authenticated `/portal` loads once  
4. Rotate secrets if any temporary/dev secrets were ever used on this project.

---

## Residual recommendations

- Prefer durable session/revocation store over memory cache on serverless.
- Keep Payment webhook signature verification enabled before enabling live PSP.
- Consider removing `'unsafe-eval'` from CSP after confirming Next.js runtime needs.
