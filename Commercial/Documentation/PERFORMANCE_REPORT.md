# PERFORMANCE_REPORT.md

**Phase:** 10 · Sprint 5  
**Scope:** Commercial platform / cloud / presentation only  
**Core:** FROZEN · not imported by performance suite  
**Run:** `2026-07-26T07:53:09Z` · CLI `npm run perf:sprint5`  
**Portal:** `0.9.0-phase10.s5`  

---

## Benchmarks (measured)

| Metric | Avg | P95 | Target (P95) | Result |
|--------|----:|----:|-------------:|--------|
| Website Load Time | 3.5 ms | 10.6 ms | ≤ 800 ms | PASS |
| Customer Portal Load Time | 2.7 ms | 4.7 ms | ≤ 600 ms | PASS |
| Dashboard Rendering | 1.4 ms | 4.3 ms | ≤ 500 ms | PASS |
| API Response Time | 0.8 ms | 0.9 ms | ≤ 200 ms | PASS |
| Authentication Time | 0.0 ms | 0.1 ms | ≤ 150 ms | PASS |
| License Validation Time | 1.2 ms | 2.3 ms | ≤ 120 ms | PASS |
| Subscription Processing | 0.0 ms | 0.1 ms | ≤ 250 ms | PASS |
| Payment Processing | 0.0 ms | 0.0 ms | ≤ 300 ms | PASS |
| Installer Download Speed | 74.3 ms | 109.1 ms | ≤ 400 ms | PASS |
| Update Check Time | 52.9 ms | 89.6 ms | ≤ 200 ms | PASS |

**Pass count:** 10 / 10  
**Performance Score:** **100**

## Surfaces

| Surface | Path |
|---------|------|
| Executive dashboard | `/portal/admin/performance` |
| Benchmarks | `/portal/admin/benchmarks` |
| API | `/api/admin/performance?view=benchmark` |
| CLI | `npm run perf:sprint5` |

## Isolation

Performance probes exercise portal health, license/billing stores, cache, and release metadata only. Trading Engine behavior is unchanged.
