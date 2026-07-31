# FINAL GO-LIVE CHECKLIST

**Product:** THE GOLD MIND PROFESSIONAL 1.0.0  
**Updated:** 2026-07-31  

---

## A. Internal engineering (complete)

- [x] Trading Engine frozen
- [x] Certified release artifacts hash-aligned
- [x] Portal production build PASS
- [x] Licensing/payment fail-closed automated tests PASS
- [x] Release download catalog validation 25/25 PASS
- [x] Billing emails wired to Resend delivery path (activates when keys exist)
- [x] Admin system docs + production admin list template
- [x] Legal drafts published (Privacy, Terms, EULA, Refund, Cookies, Disclaimer, Risk)
- [x] Legal links in website + portal footers + sitemap
- [x] `.env.production` template generated (gitignored) + `.env.production.example` published

---

## B. Owner / ops (required before open sales)

See [`OWNER_ACTION_REQUIRED.md`](./OWNER_ACTION_REQUIRED.md):

- [ ] Code signing certificate + signed Setup republish
- [ ] Production domain DNS + AUTH_URL / NEXTAUTH_URL
- [ ] Paste production secrets (Auth, Upstash, Admin emails, Resend+SPF/DKIM, Paddle live+webhook, Google OAuth)
- [ ] Legal counsel approval of published drafts
- [ ] Clean Windows install + MT5 attach smoke
- [ ] One live Paddle checkout dry-run after live approval

---

## C. Launch day

- [ ] Deploy portal with production env
- [ ] Publish GitHub Release from `Commercial/Releases/1.0.0/github-assets/`
- [ ] Verify login, license activation, authenticated download
- [ ] Verify transactional email (welcome / license) with Resend
- [ ] Monitor first activations and support tickets
