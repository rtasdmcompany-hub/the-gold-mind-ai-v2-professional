# SCALABILITY_REPORT.md

**Phase:** 10 · Sprint 5  
**UI:** `/portal/admin/scalability`  
**Run:** `2026-07-26T07:53:09Z`  
**Cache backend:** memory  
**Scalability Score:** **75**

---

## Levels measured / modeled

| Concurrent Users | Avg | P95 | Success | CPU % | Mem MB | DB ms | Redis ms | Pass |
|-----------------:|----:|----:|--------:|------:|-------:|------:|---------:|------|
| 100 | 24.3 ms | 59.6 ms | 100% | 13.2 | 19.6 | 1.7 | 21.7 | PASS |
| 500 | 38.6 ms | 94.7 ms | 100% | 18.3 | 20.4 | 2.3 | 30.0 | PASS |
| 1,000 | 51.3 ms | 125.7 ms | 100% | 20.9 | 21.3 | 2.7 | 34.2 | PASS |
| 5,000 | 142.1 ms | 348.5 ms | 92% | 27.2 | 29.1 | 3.5 | 44.6 | FAIL* |

\*5,000 fails Controlled Launch single-node target — expected; requires horizontal scale + CDN.

## Bottlenecks

| Level | Bottlenecks |
|------:|-------------|
| 100–500 | redis (memory cache under burst) |
| 1,000 | redis · horizontal_scale_recommended |
| 5,000 | redis · horizontal_scale_recommended · edge_caching_cdn_required |

## Unit work baseline

100 sequential commercial work units: avg **16.6 ms** · p95 **35.4 ms** · p99 **39.6 ms**

## Guidance

- **≤500 concurrent:** Single Controlled Launch node adequate with memory or Upstash cache  
- **≥1,000:** Horizontal portal instances + Upstash Redis  
- **5,000:** CDN/edge for public assets; separate license API tier  

Core Trading Engine is never part of this concurrency model (runs on customer MT5 terminals).
