# PRODUCTION_DEPLOYMENT.md

**Phase:** 10 · Sprint 8  
**UI:** `/portal/admin/production-deployment`  

---

## Verified (env-aware)

| Component | Notes |
|-----------|-------|
| GitHub Release | Process documented; local workspace may lack remote |
| Vercel | PASS when `VERCEL_URL` present; else configure for prod |
| Supabase | Optional — file stores valid for RC |
| Cloudflare | Recommended for Stable TLS/CDN |
| RunPod | N/A on license path |
| Redis | Prefer Upstash for multi-instance |
| Email | Transactional provider required for Stable notifications |
| Background workers | In-process webhooks/cache; fleet optional |
| Environment variables | `validateSecretsPresent()` |
| Rollback | Prior release redeploy + `.data` restore |

Do not fake live cloud connectivity when credentials are absent.
