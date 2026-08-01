# OWNER_ACTION_REQUIRED.md

**Product:** THE GOLD MIND PROFESSIONAL 1.0.0  
**Updated:** 2026-07-31  
**Release freeze:** ACTIVE

Engineering freeze complete. Remaining items are **Owner / ops only**.

---

## 1. Promote production deployment (required for GitHub == Production)

**Status:** Waiting for Owner  

Latest release is on branch `cursor/cloud-agent-1785482281349-vtik0` (PR #1).  
Production host is live but still on an older `main` revision. Agent has **no Vercel CLI auth**.

**Owner:** Merge PR #1 to `main` **or** Redeploy Production in Vercel from this branch/commit, then confirm:

- Production URL commit matches GitHub HEAD  
- `/api/health` and `/api/licenses/ready` still PASS  

---

## 1b. Local disk auto-sync (H: drive)

**Status:** Waiting for Owner (one-time)  

Cloud/GitHub/Vercel updates do **not** rewrite your Windows folder by themselves.  
On the PC that holds the project, run **once**:

```powershell
.\Commercial\Scripts\Install-LocalGitAutoSync.ps1
```

Details: `Commercial/Documentation/LOCAL_GITHUB_AUTO_SYNC.md`  
Manual sync: `Commercial\Scripts\Sync-Now.cmd`

---

## 2. Code Signing Certificate

**Status:** Waiting for Owner  

Provide Authenticode certificate; authorize signed Setup rebuild.

---

## 3. Resend — verify `thegoldmind.ai`

**Status:** Waiting for Owner (interim cutover active)  

**Live-test unblock (2026-08-01):** `RESEND_API_KEY` is now on Vercel Production.  
Outbound From temporarily uses verified infra `noreply@rtasstudio.com` with display name **THE GOLD MIND PROFESSIONAL** so Gmail can receive mail before brand DNS exists. Details: `EMAIL_AND_SAFE_BROWSING.md`.

When ready, on the **existing** Resend account, add/verify `thegoldmind.ai` (SPF/DKIM), then set Production:

- `RESEND_FROM_EMAIL=THE GOLD MIND PROFESSIONAL <noreply@thegoldmind.ai>`
- `SUPPORT_EMAIL` / `SUPPORT_INBOX_EMAIL=support@thegoldmind.ai`

After brand domain verify, remove the rtasstudio.com cutover From.

---

## 4. Vercel Production env (confirm / complete)

**Status:** Partially done  

Observed on live host: Upstash durable license store **ready** (`/api/licenses/ready`).  

Still confirm in Vercel Production:

| Variable | Notes |
|----------|-------|
| `AUTH_SECRET` / `NEXTAUTH_SECRET` / `LICENSE_STORE_SECRET` | Required |
| `AUTH_URL` / `NEXTAUTH_URL` / `NEXT_PUBLIC_APP_URL` | Current Vercel URL or custom domain |
| `GOOGLE_CLIENT_ID` / `GOOGLE_CLIENT_SECRET` | Verified locally earlier — confirm pasted |
| `RESEND_API_KEY` + Gold Mind From | After domain verify |
| `UPSTASH_REDIS_REST_URL` / `TOKEN` | Appears configured on live host — confirm |
| `PADDLE_*` live keys + webhook | Still required for open checkout |
| `PORTAL_*_EMAILS` admin roster | Production admin elevation |

Brand/product optional overrides: see `.env.production.example`.

---

## 5. Google Cloud Console — Redirect URI allowlist

**Status:** Waiting for Owner  

Confirm OAuth client allows:

- `https://the-gold-mind-ai-v2-professional.vercel.app`
- `.../api/auth/callback/google`  
Consent product name: **THE GOLD MIND PROFESSIONAL**

---

## 6. Legal Approval

**Status:** Waiting for Owner  

Counsel sign-off on published legal drafts.

---

## 7. Live smoke (Owner machine)

**Status:** Waiting for Owner  

1. Windows install of unsigned Setup (or signed after §2)  
2. License activate via portal  
3. Attach EA on MT5  
4. Optional: one live Paddle dry-run after §4  

---

## Completed (no longer blocking engineering)

- Resend API key validity (shared account)  
- Google OAuth client credential validity  
- Brand separation + brand/product central config  
- Local production build + release package validation  
- Trading Engine freeze integrity  

---

## After Owner completes promotion + §3–§7

Commercial GO can be reassessed.  
Until then: **Internal GO · Commercial NO-GO · Live Trading Ready = NO (await Owner feedback).**
