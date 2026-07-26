# GO_LIVE_CHECKLIST.md

**Edition:** THE GOLD MIND PROFESSIONAL (Website)  
**Rule:** No public Stable if any Critical blocker remains.

## Pre-go-live

- [ ] BC-LEGAL counsel sign-off (Privacy/Terms/Refund/Risk)
- [ ] BC-BRAND assets approved
- [ ] Live PSP credentials configured (or written invite-only waiver)
- [ ] Authenticode Stable (or waiver)
- [ ] KB ≥ 20 articles verified
- [ ] Core SHA-256 matches certification
- [ ] Demo auth disabled in production
- [ ] HTTPS + CSRF + secrets validated
- [ ] Customer notification templates ready
- [ ] Rollback owner assigned

## Go-live

- [ ] Deploy production portal
- [ ] Smoke: register/invite → purchase → activate → download
- [ ] Monitor health + payments + support queue
- [ ] Publish release notes

## Post-go-live (T+24h)

- [ ] Review incidents / alerts
- [ ] Confirm email delivery
- [ ] Confirm updater check path
