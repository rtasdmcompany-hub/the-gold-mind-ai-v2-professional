# HIGH_AVAILABILITY.md

**Score:** 96

| Check | Status | Detail |
|-------|--------|--------|
| Automatic Failover | pass | DNS/CDN health-check failover + Vercel dual-region deploy |
| Health Checks | pass | /api/v1/health · /api/health · synthetic regional probes |
| Regional Redundancy | pass | Regions: us-east, eu-west, ap-south, me-central |
| Service Recovery | pass | Stateless portal redeploy + circuit breakers on commercial APIs |
| Database Recovery | pass | Supabase PITR + daily snapshots + cross-region replica target |
| Background Worker Recovery | partial | Queue workers auto-restart; RunPod optional scale-to-zero |
| Queue Recovery | pass | Upstash-backed queues with retry + DLQ for webhooks |
| Session Recovery | pass | Redis session cache with sticky-safe JWT/session cookies |
