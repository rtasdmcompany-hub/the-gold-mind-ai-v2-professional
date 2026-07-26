# DATABASE_OPTIMIZATION.md

**Phase:** 10 · Sprint 5  
**UI:** `/portal/admin/database-optimization`  
**Run:** `2026-07-26T07:53:10Z`  
**Database Performance Score:** **67**

---

## Review findings

| Area | Status | Detail | Recommendation |
|------|--------|--------|----------------|
| Indexes | ok | Encrypted file stores use full-scan list APIs | Add email→id secondary maps when license count > 10k |
| Slow Queries | ok | Aggregate read p95 **4.1 ms** | Cache dashboard aggregates 30–60s for admin hubs |
| Connection Pooling | improve | File-backed stores (no SQL pool) | When adopting Supabase: PgBouncer · max 10–20 for Controlled Launch |
| Caching | improve | Hot paths should use Upstash/memory facade | Cache health rollups and open-ticket counts |
| Migration Performance | ok | Additive JSON store versions | Keep versioned migrations offline before promote |
| Backup Speed | ok | Store footprint ~5 KB | Nightly copy of `.data/**` to object storage; test restore |

## Query stats (license + billing + support read path)

| Stat | Value |
|------|------:|
| Samples | 10 |
| Avg | 1.2 ms |
| P50 | 0.8 ms |
| P95 | 4.1 ms |
| P99 | 4.1 ms |

## Store footprint (RC)

| Store | Bytes |
|-------|------:|
| Licensing | ~4 KB |
| Billing | 0 |
| Support | ~1.6 KB |

File-backed encrypted stores remain valid for RC / Controlled Launch; plan SQL when MAU requires it. No Core schema or trade data is involved.
