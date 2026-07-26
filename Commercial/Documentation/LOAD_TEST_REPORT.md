# LOAD_TEST_REPORT.md

**Phase:** 10 · Sprint 5  
**UI:** `/portal/admin/load-tests`  
**Run:** `2026-07-26T07:53:10Z`  
**Load Score:** **100**

---

## Targets & results

| Target | Requests | Concurrency | Avg | P95 | P99 | Success | Result |
|--------|---------:|------------:|----:|----:|----:|--------:|--------|
| Customer Portal | 80 | 10 | 24.7 ms | 30.6 ms | 30.7 ms | 100% | PASS |
| Authentication | 60 | 10 | 0.3 ms | 0.6 ms | 1.1 ms | 100% | PASS |
| License Server | 100 | 15 | 12.1 ms | 14.8 ms | 14.9 ms | 100% | PASS |
| Payment APIs | 40 | 8 | 0.0 ms | 0.1 ms | 0.2 ms | 100% | PASS |
| Support System | 50 | 8 | 0.1 ms | 0.2 ms | 0.2 ms | 100% | PASS |
| Admin Console | 40 | 6 | 5.4 ms | 8.4 ms | 8.5 ms | 100% | PASS |
| Cloud APIs | 80 | 12 | 13.1 ms | 17.4 ms | 17.8 ms | 100% | PASS |

## Bottlenecks & recommendations

| Area | Recommendation |
|------|----------------|
| Customer Portal | Keep data fetches parallel; edge-cache public shells |
| Authentication | Ensure `AUTH_SECRET` in prod; Redis session rate-limit backend |
| License Server | Add per-email index map if store grows beyond file scan |
| Payment APIs | Keep PaymentPort async; webhook workers off request path |
| Support System | Paginate ticket lists; cache open-count for dashboards |
| Admin Console | Defer BI aggregates; avoid full scans on every hub render |
| Cloud APIs | Prefer Upstash Redis in prod (current backend: memory) |

## Method

Controlled in-process bursts with limited concurrency (safe for Controlled Launch hosts). Identifies commercial bottlenecks without attacking Core EA runtime.
