# BUG_FIX_REPORT.md

**Product:** THE GOLD MIND AI v2.0 PROFESSIONAL  
**Mode:** RELEASE CANDIDATE — INTERNAL FIX LOG  
**Generated:** 2026-07-31  

Trading Engine formulas were **not** modified. Fixes below are packaging, portal, AI supervisor behavior (pre-activation), installer UX, and commercial copy/security hygiene.

---

## AI / EA

| Bug | Fix |
|-----|-----|
| Activation tracks often marked EXPIRED instead of READ ONLY | Map activation by position comment; READ ONLY when activated |
| Global READ ONLY while LIVE pendings remained | Gate global READ ONLY on zero LIVE tracks |
| RESUME learn CSV prev lot/conf collision | Capture previous values before overwrite |
| AI panel did not follow dashboard drag | Reposition panel objects in `UpdatePanel` |
| Packaged EX5 stale vs Phase 11E Experts build | Recompile + package EX5 `251018` / SHA `890e2225…` |
| Core SHA packaging gate mismatch | Rebaseline mq5 SHA `9fd20246…` |

---

## Installer / packaging

| Bug | Fix |
|-----|-----|
| Customer Start Menu exposed Activate/Deploy PowerShell | Removed; launcher GUI runs helpers hidden |
| Uninstall string showed visible PS one-liner | Pointed at launcher `/uninstall` |
| Update channel could pull non-stable | Forced stable-only |
| Release tree `.old` / `Setup.new.exe` pollution | Removed |
| Validate-Installer false-negative on UTF-16 markers | Alignment check corrected |
| Empty/minimal first-run payload docs | `FIRST_RUN.txt` / first-run guide path |
| Customer-facing “unsigned development build” | Relabeled `Code signing pending` / `pending_code_sign` |

---

## Customer Portal / website

| Bug | Fix |
|-----|-----|
| No password reset | `/forgot-password` + `/reset-password` + account service |
| Public `/releases/*` download bypass | Middleware gate; authenticated API download path |
| Hard-coded `@goldmind.local` production admin elevation | Removed production defaults |
| Stub Stripe/PayPal offered in checkout | Hidden; Paddle-only when configured |
| Non-admin could target non-stable release checks | Stable-only hardening |
| Beta/Partner nav visible without invite | Gated |
| RC/demo/sandbox customer copy | Scrubbed |
| Marketing “signed” implying Authenticode done | “Checksum-verified” / signing pending |
| Contact success UX | `?sent=1` + support email when configured |
| Legal contacts non-commercial | `@rtas.group` |
| Portal package identity non-1.0.0 | Set `1.0.0` |
| Ops/Upstash banners leaked to customers | Customer-safe messaging / removed |
| Billing base URL could fall back to localhost in prod | Production-safe resolver |
| Sandbox checkout redirects when disallowed | Hardened |
| `latest-stable.json` stale signature + fallback SHA/size | Synced to ZIP `e6112062…` / 863565; seed defaults updated |
| i18n support contacts used `.local` domains | `partners@rtas.group · support@rtas.group` |
| Affiliate default base URL used `.local` | Production-safe portal default |

---

## Security / access

| Bug | Fix |
|-----|-----|
| Dev admin privilege defaults in production role paths | Removed; env allow-lists required |
| Demo license auto-seed on empty store | Blocked when `NODE_ENV=production` or `VERCEL` |
| Robots indexing portal/api/releases | Disallow rules applied |

---

## Not bugs (Owner external)

Code signing, Paddle live keys, Resend DNS, domain DNS, Upstash permanent Redis, Google OAuth secrets, legal counsel approval, SmartScreen reputation — tracked only in `OWNER_ACTION_REQUIRED.md`.
