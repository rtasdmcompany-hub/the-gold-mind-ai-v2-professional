# AI Performance Report — Phase 11C

**Generated:** 2026-07-30T09:11:08.107Z

## Tick / Decision Latency

| Metric | Value |
|--------|-------|
| P50 (10k) | 0.0046 ms |
| P95 (10k) | 0.0058 ms |
| P99 (10k) | 0.0155 ms |
| Throughput (10k) | 69019 decisions/sec |

## Notes

- Harness mirrors Phase 11B weighted confidence + band policy exactly.
- MT5 chart UI / broker round-trip not included (pre-activation decision path only).
- Throttle constant in product: `GM_P11B_THROTTLE_MS = 1200`.

## Verdict

FAIL
