# ISOLATED_DEPLOYMENT_STATUS.md

**Product:** THE GOLD MIND AI v2.0 PROFESSIONAL  
**Date:** 2026-07-26  
**Policy:** Completely independent commercial product — no cross-project reuse  

---

## Inspection (THIS project only)

| Check | Result |
|-------|--------|
| Local path | `H:\PERSONAL\RTAS Digital Marketing Company\RTAS Softwear\THE GOLD MIND AI v2.0 Professional` |
| Git repository | **NOT INITIALIZED** (no `.git`) |
| GitHub remote | **NONE** |
| `gh auth` | **NOT LOGGED IN** |
| Vercel CLI | **NOT FOUND** |
| Supabase CLI | **NOT FOUND** |
| `.vercel` project link | **NOT FOUND** |
| `.env.production` | **NOT FOUND** |
| `.env.local` | Present (local/dev only — must NOT be copied from another product) |
| Workflow file | `.github/workflows/commercial-release.yml` exists locally (not yet on GitHub) |
| Existing Setup.exe | `Commercial/Releases/1.0.0/installer/Setup.exe` (local artifact; not tied to a Vercel URL) |

**No cloud resources were created in this session.**  
**No other repository or production project was touched.**

---

## STOP — Owner decisions required before any create/push/deploy

Per deployment policy: if information is missing, **ASK FIRST**. Never guess. Never reuse another product’s config.

Please reply with answers to **A–H** below. After that, DevOps work for THIS product only will continue.

### A. GitHub

1. GitHub account or organization name for the **new** isolated repo?  
2. Exact new repository name? (Suggested: `the-gold-mind-ai-v2-professional` — confirm or replace)  
3. Public or Private?  
4. Confirm: run `gh auth login` on this machine (Owner must complete browser/device login).

### B. Vercel

1. Vercel account/team for a **new** project (not an existing product)?  
2. Confirm: install Vercel CLI and create a **new** project linked only to this repo.  
3. Preferred production hostname? (Default: Vercel-assigned `*.vercel.app` until custom DNS later)

### C. Supabase

1. Create a **new** Supabase project under which org?  
2. Region preference?  
3. Owner will paste **new** project URL + anon/service keys after creation (do not reuse another product’s DB).

### D. Google OAuth

1. Google Cloud project name for a **new** OAuth client (THIS product only)?  
2. Owner will create OAuth client and paste Client ID/Secret after Authorized redirect URIs are known (needs Vercel URL first).

### E. Email (Resend)

1. Resend account for THIS product?  
2. From-domain / from-address to use?  
3. Owner will paste **new** API key (not shared with another product).

### F. Payments

1. Paddle: new vendor/product for THIS product only? (Owner provides vendor ID + webhook secret)  
2. PayPal: new REST app for THIS product only? (Owner provides client ID/secret)  
3. Primary provider for production: Paddle, PayPal, or both?

### G. Optional infra

1. Upstash Redis: create new instance? (Yes/No)  
2. RunPod / Fal.ai: required for v1 commercial portal launch? (Yes/No — default **No** unless Owner says otherwise)  
3. Cloudflare: defer to future? (Default **Yes, defer**)

### H. Release identity

1. Commercial version string for this isolated launch? (Current local packaging used `1.0.0`)  
2. Confirm Core remains frozen SHA-256:  
   `75002e46e3c200292c3696b2767bba20f2dd4200c74078555f84bc1f54a033ce`

---

## Planned sequence (AFTER Owner answers + logins)

1. `git init` in THIS folder only → first commit (exclude secrets)  
2. `gh repo create` **new** isolated repo → push  
3. Install Vercel CLI → `vercel` **new** project from `Commercial/CustomerPortal/web`  
4. Create **new** Supabase project (Owner keys)  
5. Configure **new** Google OAuth (callback = new Vercel URL)  
6. Set **new** production env vars on Vercel only  
7. Wire Resend / Paddle / PayPal with **new** keys  
8. Rebuild Setup.exe with `-PortalBase <new-vercel-url>`  
9. Document: GitHub, Vercel, Supabase, OAuth, URL, versions, remaining Owner actions  

---

## Remaining Owner Actions (immediate)

| # | Action | Why |
|---|--------|-----|
| 1 | Answer A–H above | Naming + isolation choices |
| 2 | `gh auth login` | Required to create/push **new** GitHub repo |
| 3 | Allow Vercel CLI install + login | Required for **new** Vercel project |
| 4 | Create/provide **new** Supabase project credentials | Isolated DB |
| 5 | Create **new** Google OAuth client (after URL known) | Isolated login |
| 6 | Provide **new** Resend / Paddle / PayPal secrets | Isolated billing/email |

---

## Current deliverable matrix (incomplete until above)

| Item | Status |
|------|--------|
| 1. GitHub Repository | **PENDING Owner** |
| 2. Vercel Project | **PENDING Owner** |
| 3. Supabase Project | **PENDING Owner** |
| 4. Google OAuth App | **PENDING Owner** |
| 5. Deployment URL | **PENDING Owner** |
| 6. Build Version | Local portal `1.0.10-phase12.s1` (not production-deployed) |
| 7. Release Version | Local release pack `1.0.0` |
| 8. Installer Version | Local `Setup.exe` `1.0.0` (portal base still `thegoldmind.ai` — must rebuild after Vercel URL) |
| 9. Remaining Owner Actions | See table above |

**Trading Engine / Risk / Recovery:** not modified.
