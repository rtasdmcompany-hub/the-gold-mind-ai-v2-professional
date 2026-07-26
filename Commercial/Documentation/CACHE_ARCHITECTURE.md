# CACHE_ARCHITECTURE.md

**Phase:** 9 · Sprint 6  
**Code:** `server/cloud/cache.ts`

---

## Backend

| Mode | When |
|------|------|
| **Upstash Redis** | `UPSTASH_REDIS_REST_URL` + `UPSTASH_REDIS_REST_TOKEN` |
| **Memory fallback** | Env unset or Upstash error |

REST commands via `fetch` — no hard dependency required for MVP; Upstash SDK optional later.

---

## Use cases

| Cache | Key pattern |
|-------|-------------|
| Session Cache | `tgm:session:{email}` |
| Rate Limiting Cache | `tgm:rl:{bucket}` |
| Configuration Cache | `tgm:cfg:{name}` |
| Performance Cache | `tgm:perf:{name}` |
| Brute-force | `tgm:bf:{email}` |

---

## Invalidation

- Exact: `cacheDel(key)` / `cacheInvalidate(key)`  
- Prefix (memory): `cacheInvalidate("tgm:cfg:*")`  

TTL required on all writes. Map capped at 5000 entries in memory mode.

---

## Trading Engine

Cache is commercial-only. EA runtime must not require Redis availability.

---

*End of CACHE_ARCHITECTURE.md*
