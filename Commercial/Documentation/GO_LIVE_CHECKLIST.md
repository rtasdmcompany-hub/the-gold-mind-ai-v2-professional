# FINAL GO-LIVE CHECKLIST

**Product:** THE GOLD MIND PROFESSIONAL 1.0.0  
**Updated:** 2026-07-31  
**Mode:** RELEASE  

Use this list for commercial go-live. Internal engineering items are marked DONE where verified.

---

## A. Internal engineering (complete)

- [x] Trading Engine frozen (no formula/strategy changes)
- [x] Certified EX5 aligned across ZIP / Experts / installer payload (`890e2225…`)
- [x] mq5 packaging gate SHA verified (`9fd20246…`)
- [x] Stable ZIP + Setup.exe SHA256 verified
- [x] Portal production build PASS
- [x] Authenticated download path + stable-only catalog verified (`validate:releases` 25/25)
- [x] Licensing/payment fail-closed gates verified (`test:portal-flows` 0 failures)
- [x] Sandbox checkout blocked in production
- [x] Demo license seed blocked on production/Vercel
- [x] SBOM / SHA256SUMS / Release Notes / Version Manifest present
- [x] Production env template published (`.env.production.example`)
- [x] AI Command Center **preview card only** (full Phase 13 deferred to V2.0)

---

## B. Owner / ops (required before open sales)

Complete items in [`OWNER_ACTION_REQUIRED.md`](./OWNER_ACTION_REQUIRED.md), then check off:

- [ ] Authenticode sign Setup.exe / TheGoldMindSetup.exe and republish hashes
- [ ] Production domain DNS → Vercel; set `AUTH_URL` / `NEXTAUTH_URL` / `NEXT_PUBLIC_APP_URL`
- [ ] Paste all production secrets from `.env.production.example` into Vercel
- [ ] Upstash Redis created and reachable from Vercel
- [ ] Paddle live mode + webhook URL configured
- [ ] Resend domain verified (SPF/DKIM) and sending works
- [ ] Google OAuth client created for production origin (if offering Google login)
- [ ] Admin allow-list emails set
- [ ] Legal counsel sign-off
- [ ] Clean Windows install smoke: Setup → Activate → Deploy → MT5 attach
- [ ] One paid checkout → license delivery dry-run after Paddle live

---

## C. Launch day

- [ ] Deploy portal to production
- [ ] Publish GitHub Release assets from `Commercial/Releases/1.0.0/github-assets/`
- [ ] Verify `/portal` login + downloads with a real license
- [ ] Monitor first 10 activations / support tickets
- [ ] Confirm SmartScreen behavior after signing (reputation may still warn initially)

---

## D. Do not do at go-live

- Do not enable Phase 13 full AI Command Center
- Do not modify Trading Engine / H4 / ATR / TP / SL
- Do not force sandbox payments in production
- Do not ship unsigned installer as “signed”
