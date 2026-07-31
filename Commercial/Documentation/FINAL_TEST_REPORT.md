# FINAL_TEST_REPORT.md

**Product:** THE GOLD MIND PROFESSIONAL 1.0.0  
**Date:** 2026-07-31  
**Release freeze:** ACTIVE

---

## Automated suites executed

| Suite | Command | Result |
|-------|---------|--------|
| TypeScript | `npx tsc --noEmit` | **PASS** |
| Portal production build | `npm run build` | **PASS** |
| Release catalog / download | `npm run validate:releases` | **PASS 25/25** |
| Commercial fail-closed flows | `npm run test:portal-flows` | **PASS** (0 failures) |

---

## Portal-flows coverage

- Trial allowed in production  
- Paid self-serve blocked in production by default  
- Sandbox / free renew blocked in production  
- Unconfigured Paddle fails closed in production  
- Trade alert preference defaults  

---

## Production smoke (live host)

| Check | Result |
|-------|--------|
| Home / login / privacy HTTP 200 | **PASS** |
| `/api/health` | **PASS** (status `degraded` due to cache latency; core services healthy) |
| `/api/licenses/ready` | **PASS** (`ready:true`, Upstash durable store configured) |

---

## Integrity checks

| Check | Result |
|-------|--------|
| MQ5/EX5 vs VERSION_MANIFEST | **PASS** |
| ZIP/Setup vs SHA256SUMS | **PASS** |
| Runtime CORE_CERT_SHA vs MQ5 | **PASS** (aligned this freeze) |

---

## Not executed (Owner / environment limits)

| Test | Reason |
|------|--------|
| Signed installer install on Windows | No Authenticode cert / no Windows runner |
| Live Paddle checkout | Live PSP credentials not fully production-approved in agent |
| Full Google OAuth browser login | Requires Owner Console allowlist confirmation |
| Vercel Production redeploy of this commit | No Vercel CLI auth in agent |

---

## Test verdict

**Engineering automated gate: PASS**  
**Commercial live-market gate: PENDING Owner**
