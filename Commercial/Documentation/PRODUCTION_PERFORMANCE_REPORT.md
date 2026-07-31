# PRODUCTION_PERFORMANCE_REPORT.md

**Product:** THE GOLD MIND AI v2.0 PROFESSIONAL  
**URL:** https://the-gold-mind-ai-v2-professional.vercel.app  
**Date:** 2026-07-27  
**Region observed:** Vercel edge `bom1` / build `iad1`

---

## Summary

Public page performance is **acceptable for go-live brochure traffic**. Authenticated flows could not be measured because login/portal are unavailable.

**Public performance: PASS**  
**Authenticated performance: NOT MEASURED (blocked)**

---

## Timing samples (curl)

| Resource | TTFB | Total | Notes |
|----------|------|-------|-------|
| `/` | ~0.38s | ~0.39s | HTML ~22.6 KB |
| `/pricing` | ~0.29s | ~0.29s | Fast |
| Public HTML pages (batch) | ~0.45–0.65s | — | Earlier probe set |
| `/favicon.ico` | ~0.15s | — | Cached/static |
| Brand PNG (header) | ~0.35s | — | Static asset |
| OG image `/opengraph-image.png` | cached/prerender | — | `X-Vercel-Cache: PRERENDER` |

---

## Static asset health

| Asset | Status | Size (approx) |
|-------|--------|----------------|
| `/brand/the-gold-mind-logo-dark.png` | 200 | ~221 KB |
| `/brand/the-gold-mind-og-1200x630.png` | 200 | served |
| `/brand/the-gold-mind-icon-192.png` | 200 | small |
| `/favicon.ico` | 200 | ~26 KB |
| `/site.webmanifest` | 200 | OK |

---

## Backend / API latency

| Endpoint | Result | Impact |
|----------|--------|--------|
| `/api/health` | 503 unhealthy JSON (fast response) | Availability fail, not latency |
| `/api/auth/providers` | 500 | Blocks auth |
| `/api/v1/health` | 500 | API platform health broken |
| `/api/mobile/health` | 500 | Mobile companion health broken |

Health report notes `cacheBackend: memory` and `rateLimitBackend: memory` — expected on Vercel without Upstash, but not durable across instances.

---

## Performance risks for scale

1. **Ephemeral filesystem** for `.data/*` stores on serverless → health failures + cold inconsistency.  
2. **Memory rate-limit/cache** not shared across regions/instances.  
3. Auth failure prevents measuring portal/dashboard bundle cost under real session.

---

## Recommendations

1. Restore auth, then re-run Lighthouse on `/portal` after login.  
2. Move licensing/billing/audit persistence to Supabase/Postgres.  
3. Optional: Upstash Redis for shared rate limits/cache.  
4. Keep OG/favicon/brand assets on CDN (already via Vercel static).

---

## Verdict

Public site performance is ready. Platform is **not performance-certified for customer portal workloads** until auth and durable storage are healthy.
