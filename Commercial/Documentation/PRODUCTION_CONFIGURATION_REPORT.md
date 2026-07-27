# PRODUCTION_CONFIGURATION_REPORT.md

**Product:** THE GOLD MIND AI v2.0 PROFESSIONAL  
**Date:** 2026-07-27  
**Production URL:** https://the-gold-mind-ai-v2-professional.vercel.app

---

## Dedicated production stack

| Component | Configuration | Status |
|-----------|---------------|--------|
| Vercel project | `rtas-group/the-gold-mind-ai-v2-professional` | **ACTIVE** |
| Framework | Next.js 15.5.9 | **CONFIGURED** |
| Node.js | 24.x | **CONFIGURED** |
| Region | `iad1` | **CONFIGURED** |
| Deployment Protection SSO | Disabled for production | **CONFIGURED** |
| Production alias | `the-gold-mind-ai-v2-professional.vercel.app` | **ACTIVE** |

---

## Environment variables (Vercel production)

| Variable | Purpose | Status |
|----------|---------|--------|
| `NEXTAUTH_URL` | This product's canonical URL | **SET** |
| `AUTH_URL` | Auth callback base | **SET** |
| `AUTH_SECRET` | Session signing | **SET** |
| `NEXTAUTH_SECRET` | Session signing alias | **SET** |
| `LICENSE_STORE_SECRET` | Isolated license encryption | **SET** |
| `BILLING_STORE_SECRET` | Isolated billing encryption | **SET** |
| `AUDIT_STORE_SECRET` | Isolated audit encryption | **SET** |
| `COMMERCIAL_DATA_ROOT` | Serverless data path | **SET** |
| `CORS_ALLOWED_ORIGINS` | This product origin only | **SET** |
| `PAYMENT_MODE` | Sandbox | **SET** |
| `PORTAL_DEMO_AUTH` | Controlled demo login | **SET** |
| `GOOGLE_CLIENT_ID` | **This product's OAuth client** | **NOT SET** |
| `GOOGLE_CLIENT_SECRET` | **This product's OAuth client** | **NOT SET** |
| `PADDLE_*` | This product's billing IDs | **NOT SET** |
| `PAYPAL_*` | This product's billing IDs | **NOT SET** |
| `RESEND_*` | This product's email sender | **NOT SET** |
| `SUPABASE_*` | This product's database | **NOT SET** |
| `UPSTASH_*` | This product's cache | **NOT SET** |

---

## Product-specific OAuth (required for isolated production auth)

Create a **new** Google OAuth client — do not reuse RTAS Studio AI or any other product's client.

| Setting | Value |
|---------|-------|
| Application name | THE GOLD MIND AI PROFESSIONAL |
| Authorized redirect URI | `https://the-gold-mind-ai-v2-professional.vercel.app/api/auth/callback/google` |
| Vercel env vars | `GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET` |

---

## Installer configuration

| File | portalBase |
|------|------------|
| `inno/payload/config/portal.json` | `https://the-gold-mind-ai-v2-professional.vercel.app` |
| `inno/payload/config/version.json` | `https://the-gold-mind-ai-v2-professional.vercel.app` |
| `Build-CommercialRelease.ps1` default | Product Vercel URL |

Rebuild installer after isolation URL update: `Build-CommercialRelease.ps1`

---

## Future custom domain (optional, this product only)

| Domain | Status |
|--------|--------|
| `thegoldmind.ai` | Owner DNS — not yet assigned to this Vercel project |

When assigned, update `NEXTAUTH_URL`, OAuth redirect URI, and installer `portalBase`.

---

## Production health (last verified)

| Check | Result |
|-------|--------|
| `/` | 200 OK |
| `/login` | 200 OK |
| `/api/health` | 200 healthy |
| Demo auth → portal | PASS |

---

## Configuration verdict

**Application configuration: COMPLETE** for isolated sandbox production.  
**Product-specific OAuth credentials: OWNER ACTION** — dedicated Google OAuth client not yet provisioned for this product.
