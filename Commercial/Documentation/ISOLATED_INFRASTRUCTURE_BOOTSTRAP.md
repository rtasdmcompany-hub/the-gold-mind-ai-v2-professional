# ISOLATED_INFRASTRUCTURE_BOOTSTRAP.md

**Product:** THE GOLD MIND AI v2.0 PROFESSIONAL  
**GitHub repo (authorized):** `the-gold-mind-ai-v2-professional` (NEW, PRIVATE)  
**Commercial Version:** 1.0.0  
**Core SHA (frozen):** `75002e46e3c200292c3696b2767bba20f2dd4200c74078555f84bc1f54a033ce`  

---

## H — Confirmed

- Commercial Version = **1.0.0**
- Core SHA remains frozen
- No Trading Engine modifications permitted

## G — Codebase requirements

| Service | Required for portal launch? | Decision |
|---------|----------------------------|----------|
| Upstash | Optional (used only if `UPSTASH_REDIS_*` set; file/memory fallback exists) | **Skip unless multi-instance cache needed** |
| RunPod | Status probe only (`RUNPOD_API_KEY`); not required for license/portal | **Skip** |
| Fal.ai | Not referenced as required runtime | **Skip** |
| Cloudflare | Deferred per Owner | **Skip** |
| Supabase | Optional (encrypted file stores work without it); Owner requested NEW project for isolation | **Create NEW project** |

---

## A — GitHub (in progress)

1. Local `.gitignore` created (secrets excluded).  
2. `git init` + first commit authorized.  
3. **Owner must complete:** `gh auth login` before `gh repo create` / push.

### Exact Owner action (GitHub)

```powershell
gh auth login -h github.com -p https -w
```

Complete the browser device approval, then reply: **GitHub auth complete**.

---

## B — Vercel (pending GitHub push)

After repo exists on GitHub:

```powershell
cd "Commercial\CustomerPortal\web"
npm i -g vercel
vercel login
vercel link --yes
# Create NEW project named the-gold-mind-ai-v2-professional — do not select an existing product
vercel --prod
```

### Exact Owner action (Vercel)

1. `vercel login` (browser).  
2. Confirm creation of a **new** project only (refuse any existing product name).

---

## C — Supabase (NEW project)

**Project name:** `the-gold-mind-ai-v2-professional`  
**Region:** closest recommended production region (typically `Southeast Asia (Singapore)` or `Central EU (Frankfurt)` — choose nearest to primary customers; Owner confirms in dashboard).

### Exact Owner action (if API token unavailable)

1. Open https://supabase.com/dashboard  
2. **New project** → name `the-gold-mind-ai-v2-professional`  
3. Set a strong DB password (store in Owner vault — never commit)  
4. Region: nearest production region  
5. After creation, copy these keys from **Project Settings → API**:

| Key to copy | Env var name |
|-------------|--------------|
| Project URL | `NEXT_PUBLIC_SUPABASE_URL` (and `SUPABASE_URL` if used) |
| `anon` `public` key | `NEXT_PUBLIC_SUPABASE_ANON_KEY` |
| `service_role` `secret` key | `SUPABASE_SERVICE_ROLE_KEY` |
| JWT Secret (Settings → API) | `SUPABASE_JWT_SECRET` |

Paste into Vercel project env (THIS project only). Do **not** reuse another product’s keys.

---

## D — Google OAuth (after Vercel URL exists)

1. Google Cloud Console → **new** project: `the-gold-mind-ai-v2-professional`  
2. APIs & Services → OAuth consent screen (External or Internal as appropriate)  
3. Create **OAuth client ID** → Web application  
4. Authorized JavaScript origins: `https://<VERCEL_HOST>`  
5. Authorized redirect URIs: `https://<VERCEL_HOST>/api/auth/callback/google`  
6. Copy Client ID → `GOOGLE_CLIENT_ID`  
7. Copy Client Secret → `GOOGLE_CLIENT_SECRET`  

Do not reuse any existing OAuth client.

---

## E — Resend (NEW)

1. Resend dashboard → create API key named `tgm-v2-professional-prod`  
2. Verify sending domain (or use Resend onboarding domain for test)  
3. Set:
   - `RESEND_API_KEY`
   - `RESEND_FROM_EMAIL`

---

## F — Paddle + PayPal (NEW apps)

### Paddle
1. New Paddle account/product for THE GOLD MIND AI v2.0 PROFESSIONAL only  
2. Create product/price for commercial license  
3. Copy: `PADDLE_VENDOR_ID`, `PADDLE_API_KEY`, `PADDLE_WEBHOOK_SECRET`  
4. Webhook URL: `https://<VERCEL_HOST>/api/billing/webhook` (or project’s paddle webhook route)

### PayPal
1. Developer Dashboard → **new** REST app for THIS product  
2. Copy Client ID/Secret → `PAYPAL_CLIENT_ID`, `PAYPAL_CLIENT_SECRET`  
3. Webhook → `PAYPAL_WEBHOOK_SECRET`  
4. Mode: `live` for production (`PAYPAL_MODE=live`)

---

## After all secrets land

1. Set env on **new** Vercel project from `.env.production.example`  
2. Redeploy  
3. Rebuild installer:  
   `Build-CommercialRelease.ps1 -Version 1.0.0 -PortalBase https://<VERCEL_HOST>`  
4. Publish GitHub Release assets from `Commercial/Releases/1.0.0/github-assets`
