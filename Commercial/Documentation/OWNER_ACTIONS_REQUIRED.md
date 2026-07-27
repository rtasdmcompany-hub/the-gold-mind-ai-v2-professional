# OWNER_ACTIONS_REQUIRED.md

**Product:** THE GOLD MIND AI v2.0 PROFESSIONAL  
**Date:** 2026-07-26  

## PAUSE POINT 1 — GitHub Authentication

Run this command in a terminal and complete browser approval:

```powershell
gh auth login -h github.com -p https -w
```

Then reply: **GitHub auth complete**

After that, automation will:
1. Create private repo `the-gold-mind-ai-v2-professional`
2. Push local `main` (`ecdff78`)
3. Install Vercel CLI / create NEW Vercel project
4. Deploy and return the Vercel URL
5. Continue with Supabase + OAuth prep

## Already done locally

- `.gitignore` (secrets excluded)
- `.env.production.example` (isolated template)
- `vercel.json` (Next.js)
- First commit on `main`: `ecdff78`
- Core SHA verified MATCH / frozen

## Do not reuse

Any existing Vercel project, Supabase DB, OAuth client, or payment/email keys from other products.
