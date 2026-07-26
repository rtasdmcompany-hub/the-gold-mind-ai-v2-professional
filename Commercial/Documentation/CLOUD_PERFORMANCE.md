# CLOUD_PERFORMANCE.md

**Phase:** 10 · Sprint 5  
**UI:** `/portal/admin/cloud-performance`  
**Run:** `2026-07-26T07:53:10Z`  
**Cloud Performance Score:** **79**

---

## Validated components

| Component | Status | Latency | Detail | Recommendation |
|-----------|--------|--------:|--------|----------------|
| Cloudflare | fallback | — | Not configured in local RC | Terminate TLS at Cloudflare; cache public assets; bypass `/api/*` |
| Supabase | fallback | — | Using encrypted file stores | Use pooler; avoid cold starts on admin aggregates |
| RunPod | fallback | — | Not required for portal Controlled Launch | Keep off critical license path; async only |
| Upstash Redis | fallback | 0.1 ms avg | `backend=memory` · p95 0.12 ms | Set `UPSTASH_REDIS_REST_URL/TOKEN` for multi-instance |
| Email Delivery | fallback | — | Billing outbox via health probes | Transactional provider; monitor bounce webhooks |
| Storage | fallback | — | Release ZIPs from local catalog in RC | CDN/object storage with signed URLs |
| API Gateway | ok | 1.4 ms avg | health p95 3.0 ms | Keep middleware thin; rate-limit by IP+user |

## Notes

Local/RC environments showing `fallback` are acceptable until production credentials are wired. Gateway throughput is validated; Redis should move from memory → Upstash before multi-instance scale.

**Infrastructure Score (derived):** round((cloud 79 + resilience 100 + load 100) / 3) = **93**
