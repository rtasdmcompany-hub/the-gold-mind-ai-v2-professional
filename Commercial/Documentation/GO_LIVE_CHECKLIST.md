# GO_LIVE_CHECKLIST.md

**Product:** THE GOLD MIND PROFESSIONAL 1.0.0  
**Updated:** 2026-07-31  
**Release freeze:** ACTIVE · Release Maintenance mode

---

## A. Internal engineering (complete)

- [x] Trading Engine frozen (MQ5/EX5 hashes certified)
- [x] Core cert constants aligned to frozen MQ5
- [x] Certified release artifacts hash-aligned (ZIP / Setup)
- [x] Portal production build PASS (`4Xs3---i8WWGDhpEgF2Qk`)
- [x] Licensing/payment fail-closed tests PASS
- [x] Release download catalog validation 25/25 PASS
- [x] Brand configuration centralized (`src/lib/brand.ts`)
- [x] Product configuration centralized (`src/lib/product.ts`)
- [x] Billing emails wired to Resend path
- [x] Admin system docs + legal drafts linked
- [x] Final audit / build / test / deployment reports published
- [x] Release branch pushed to GitHub

---

## B. Owner / ops (required before open sales)

See [`OWNER_ACTION_REQUIRED.md`](./OWNER_ACTION_REQUIRED.md):

- [ ] Promote latest release branch to **Vercel Production** (merge PR #1 → `main` or dashboard redeploy)
- [ ] Confirm Production commit SHA == GitHub HEAD
- [ ] Code signing certificate + signed Setup republish
- [ ] Verify/add `thegoldmind.ai` on Resend (SPF/DKIM) + branded From
- [ ] Paste any remaining Production secrets (Paddle live, admin roster, AUTH URLs if custom domain)
- [ ] Google OAuth redirect allowlist confirmation
- [ ] Legal counsel approval of published drafts
- [ ] Clean Windows install + MT5 attach smoke
- [ ] One live Paddle checkout dry-run after live approval

---

## C. Launch day (after B)

- [ ] Production health green / ready
- [ ] Login · license activation · authenticated download
- [ ] Transactional email from Gold Mind From address
- [ ] Monitor first activations and support tickets
- [ ] Owner live trading feedback loop starts

---

## Stop

No new features until Owner authorizes exit from Release Maintenance.
