# Site Content Manager (cPanel-style)

Public entry (footer **Admin** button): **`/admin`**  
CMS path: **`/portal/admin/site-content`**  
Permission: `admin.launch.read` (view) · `admin.launch.write` (edit/upload)

Footer → **Admin Only** → `/admin` email/password form → Site Content CMS.

### Who can enter
The signed-in email must appear in Vercel Production env (comma-separated):

```bash
PORTAL_SUPER_ADMIN_EMAILS=atiqvilog@gmail.com,your-other-admin@gmail.com
# or
PORTAL_ADMIN_EMAILS=...
```

After changing the env, redeploy (or wait for the next deploy). Then open `/admin`, sign out if a customer session is active, and sign in with that admin email + password.

If the account is Google-only, either:
- add that Google email to `PORTAL_SUPER_ADMIN_EMAILS` and use User Portal Google sign-in then open Admin, or
- set a password on the account and use the Admin Email / Password form.

Edit without redeploying:

- iPhone panel rotating video ads
- Hero background video / poster + headline / CTAs
- Header logo + brand wordmark / CTA
- Footer logos + description / copyright / risk line

## How video upload works

1. Open **Enterprise Admin → Site Content**.
2. In **iPhone video panel ads** (or Hero), choose a file **or paste a public HTTPS URL**.
3. Click **Save**.

Upload storage priority:

| Mode | When | Notes |
|------|------|--------|
| **Vercel Blob (client direct)** | `BLOB_READ_WRITE_TOKEN` set | Required for production videos (bypasses 4.5MB API limit) |
| **Local `public/uploads/`** | Non-serverless Node | Dev / self-host |
| **Durable Redis** | Small images only (≤ ~1.4MB) | Served at `/api/site-content/media/{id}` |

Store linked: `tgm-site-content`. Admin UI uses `/api/site-content/blob` for direct browser → Blob upload.

## Persistence

Content JSON key: `tgm:site-content:store:v1` (Upstash when configured).  
Public read API: `GET /api/site-content/public`.

Homepage components load this store (with built-in defaults if empty).

## Env

```bash
# Required for durable saves on Vercel (same Redis as licenses)
UPSTASH_REDIS_REST_URL=
UPSTASH_REDIS_REST_TOKEN=

# Recommended for video uploads on Vercel
BLOB_READ_WRITE_TOKEN=
```

## Legacy folder

`public/media/phone-ads/` + `ads.json` remain as **defaults / fallback**. Admin saves override them at runtime.
