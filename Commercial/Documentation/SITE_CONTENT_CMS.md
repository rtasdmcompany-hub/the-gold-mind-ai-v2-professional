# Site Content Manager (cPanel-style)

Public entry (footer **Admin** button): **`/admin`**  
CMS path: **`/portal/admin/site-content`**  
Permission: `admin.launch.read` (view) · `admin.launch.write` (edit/upload)

Footer → **Admin** → admin email/password → Site Content CMS. Non-admin accounts are blocked.

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
| **Vercel Blob** | `BLOB_READ_WRITE_TOKEN` set | Best for production videos |
| **Local `public/uploads/`** | Non-serverless Node | Dev / self-host |
| **Durable Redis** | Small images only (≤ ~1.4MB) | Served at `/api/site-content/media/{id}` |

Without Blob on Vercel, **paste an HTTPS MP4 URL** (CDN / Blob / object storage). Large videos cannot live in Redis.

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
