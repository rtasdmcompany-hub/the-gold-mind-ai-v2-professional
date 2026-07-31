# AI Stress Test Report — Phase 11C

**Generated:** 2026-07-30T09:11:08.107Z  
**Evidence:** `evidence/phase11c-evidence.json`

## Batches

| N | Elapsed ms | Ops/sec | Latency P50 | P95 | P99 | Max | Heap Δ MB | RSS Δ MB |
|---|------------|---------|-------------|-----|-----|-----|-----------|----------|
| 100 | 0.93 | 107434 | 0.0032 | 0.0063 | 0.0118 | 0.0118 | 0.18 | 0.00 |
| 500 | 7.31 | 68428 | 0.0052 | 0.0090 | 0.0213 | 0.0627 | 0.84 | 0.56 |
| 1000 | 11.69 | 85566 | 0.0052 | 0.0063 | 0.0149 | 0.1019 | -0.54 | 0.40 |
| 5000 | 54.39 | 91927 | 0.0032 | 0.0057 | 0.0098 | 1.7178 | -1.35 | 2.29 |
| 10000 | 144.89 | 69019 | 0.0046 | 0.0058 | 0.0155 | 4.4188 | 0.33 | 1.24 |

## Decision Mix (NY Open stress markets)

- **n=100:** {"INCREASE_LOT":0,"NORMAL":100,"REDUCE_LOT":0,"FREEZE":0,"CANCEL":0,"PASS":0}
- **n=500:** {"INCREASE_LOT":0,"NORMAL":500,"REDUCE_LOT":0,"FREEZE":0,"CANCEL":0,"PASS":0}
- **n=1000:** {"INCREASE_LOT":0,"NORMAL":1000,"REDUCE_LOT":0,"FREEZE":0,"CANCEL":0,"PASS":0}
- **n=5000:** {"INCREASE_LOT":0,"NORMAL":5000,"REDUCE_LOT":0,"FREEZE":0,"CANCEL":0,"PASS":0}
- **n=10000:** {"INCREASE_LOT":0,"NORMAL":10000,"REDUCE_LOT":0,"FREEZE":0,"CANCEL":0,"PASS":0}

## Memory / Leak Gate

- Soft gate: heap delta at 10k pendings ≤ 200 MB
- Result: **0.33 MB**

## Verdict

FAIL — see failures in evidence JSON
