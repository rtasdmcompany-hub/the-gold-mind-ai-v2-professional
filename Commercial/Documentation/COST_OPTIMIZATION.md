# COST_OPTIMIZATION.md

**Monthly:** $1840 · **Next quarter forecast:** $2350 · **Savings opportunity:** ~$221

| Category | Monthly | Forecast | Optimization |
|----------|--------:|---------:|--------------|
| Compute (Vercel / workers) | $620 | $780 | Move cron/webhooks to dedicated workers; right-size serverless concurrency |
| Database (Supabase) | $410 | $520 | Connection pooling · archive cold audit · reserved capacity at 100k users |
| Redis (Upstash) | $95 | $140 | TTL eviction · separate rate-limit namespace · reserved plan at 250k |
| Bandwidth / CDN | $280 | $360 | Aggressive asset caching · compress downloads · regional POP affinity |
| Object Storage | $120 | $160 | Lifecycle old installers · infrequent access tier for archives |
| WAF / Security add-ons | $180 | $200 | Consolidate rulesets · disable unused bot fights on static hosts |
| Observability / logging | $135 | $190 | Sample debug logs · retain metrics 90d hot / 1y cold |

## Reserved capacity

- Supabase reserved compute at ≥100k users
- Upstash reserved at ≥250k users
- CDN committed bandwidth if downloads grow

## Scaling policies

- Autoscale API workers on p95 > 300ms
- Scale Redis connections with active API keys
- Scale-to-zero optional RunPod workloads
