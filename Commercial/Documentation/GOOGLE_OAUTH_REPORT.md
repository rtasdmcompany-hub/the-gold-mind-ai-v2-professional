# GOOGLE_OAUTH_REPORT.md

**Product:** THE GOLD MIND PROFESSIONAL  
**Date:** 2026-07-31  
**Account:** Existing Google Cloud company credentials — no new Google account created  

---

## Credentials provided

| Item | Status |
|------|--------|
| Client ID | Present (`…apps.googleusercontent.com`) |
| Client Secret | Present |
| Client validity probe | **PASS** — Google token endpoint returned `invalid_grant` (malformed code), **not** `invalid_client` |

---

## Application configuration

Portal already enables Google when:

- `GOOGLE_CLIENT_ID` / `AUTH_GOOGLE_ID` looks like `*.apps.googleusercontent.com`
- `GOOGLE_CLIENT_SECRET` / `AUTH_GOOGLE_SECRET` length ≥ 20

Applied locally in gitignored `.env.production` / `.env.local`:

- `GOOGLE_CLIENT_ID` / `AUTH_GOOGLE_ID`
- `GOOGLE_CLIENT_SECRET` / `AUTH_GOOGLE_SECRET`
- Production base URL currently: `https://the-gold-mind-ai-v2-professional.vercel.app`

Callback used by Auth.js:

`{AUTH_URL}/api/auth/callback/google`

---

## Required Google Cloud Console settings (reuse existing client)

In the **existing** Google Cloud project / OAuth client, ensure:

### Authorized JavaScript origins

```
https://the-gold-mind-ai-v2-professional.vercel.app
http://localhost:3000
```

(After custom domain cutover, also add `https://YOUR_PRODUCTION_DOMAIN`.)

### Authorized redirect URIs

```
https://the-gold-mind-ai-v2-professional.vercel.app/api/auth/callback/google
http://localhost:3000/api/auth/callback/google
```

(After custom domain cutover, also add `https://YOUR_PRODUCTION_DOMAIN/api/auth/callback/google`.)

### Login / logout

- Login: `/login` → Google provider (`signIn("google")`) when configured
- Logout: portal sign-out clears JWT session (Auth.js)

---

## What Cursor completed

- Validated client ID/secret against Google token endpoint
- Wrote production env values locally (gitignored)
- Confirmed portal Google provider gate will enable with these values
- Production `next build` PASS with configuration present

## What Cursor cannot complete without Google Cloud Console access

- Editing Authorized JavaScript Origins / Redirect URIs inside Google Cloud Console UI/API (no GCP admin token available here)

---

## Owner action remaining for Google OAuth?

**YES — Console URI allowlist confirmation only:**

Confirm (or add) the origins/redirect URIs above on the existing OAuth client, then paste `GOOGLE_CLIENT_ID` + `GOOGLE_CLIENT_SECRET` into **Vercel Production**.

After that, Google login is fully production-ready.
