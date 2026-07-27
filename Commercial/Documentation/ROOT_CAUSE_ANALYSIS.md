# ROOT_CAUSE_ANALYSIS.md

**Product:** THE GOLD MIND AI v2.0 PROFESSIONAL  
**Date:** 2026-07-27  
**Mission:** Production recovery without modifying Trading Engine or Core SHA

## Executive finding

The production outage was caused by application configuration and serverless runtime assumptions, not by the Trading Engine, Core logic, or product branding deployment.

## Root causes

### 1. NextAuth production configuration failure
- `/api/auth/*` returned HTTP 500.
- Production required secret resolution compatible with deployed environment variables.
- Fix: use `AUTH_SECRET || NEXTAUTH_SECRET`.

### 2. Redirect loop in middleware
- `/login` redirected to `/portal` while `/portal` redirected back to `/login`.
- Cause: middleware used a truthy auth object instead of checking for a real authenticated identity.
- Fix: require authenticated `user.email` or `user.id`.

### 3. Serverless filesystem mismatch
- Health, billing, licensing, releases, and related commercial persistence assumed workspace-local writable directories.
- Vercel runtime requires writable temp storage, not repository-relative persistent writes.
- Fix: move commercial stores to serverless-safe writable root.

### 4. Public health route protection mismatch
- `/api/v1/health` and `/api/mobile/health` were blocked by auth middleware.
- Fix: classify those routes as public operational endpoints.

### 5. Health semantics mixed app readiness with live provider credentials
- Missing Resend credentials should be tracked as Owner-managed live-delivery configuration, not as a production app outage.
- Fix: keep service health green when outbox/store layer is healthy.

## Areas inspected

- NextAuth configuration
- Middleware
- Route handlers
- Session management
- Redirect logic
- Cookies / session creation
- Environment variable handling
- OAuth provider configuration
- Commercial persistence and writable paths
- Health service
- Payment service health logic

## Non-bug Owner dependencies

These remain external configuration requirements:

- Google OAuth credentials and redirect URI
- Paddle live credentials / webhook secret
- PayPal live credentials / webhook secret
- Resend live email credentials

## Protected scope confirmation

No changes were made to:

- Trading Engine
- Core SHA
- Trade logic
- Recovery / risk / order execution internals

## RCA conclusion

This was a production auth + serverless configuration failure. Recoverable application defects have been corrected.
