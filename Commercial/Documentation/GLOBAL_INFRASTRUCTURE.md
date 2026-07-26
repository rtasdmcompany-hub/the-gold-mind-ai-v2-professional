# GLOBAL_INFRASTRUCTURE.md

**Phase:** 11 · Sprint 9  
**Isolation:** Infrastructure and ops changes never modify or bypass the certified Core Trading Engine. Trading remains exclusively in MT5 Professional.

## Stack

| Component | Status | HA | Role |
|-----------|--------|----|------|
| Cloudflare | healthy | yes | DNS · CDN · WAF · SSL edge · regional routing |
| Vercel | healthy | yes | Next.js portal · serverless API routes · edge middleware |
| Supabase | healthy | yes | Managed Postgres · auth adjunct · backups |
| RunPod | planned | no | Optional GPU / batch workers (non-trading compute) |
| Upstash Redis | healthy | yes | Rate limits · session cache · queue coordination · feature flags |
| Object Storage | healthy | yes | Installers · docs · SDK artifacts · backups |
| DNS | healthy | yes | Authoritative DNS via Cloudflare |
| SSL Certificates | healthy | yes | TLS 1.2+ edge certificates |
| CDN Configuration | healthy | yes | Static + API edge caching policy |
| Regional Routing | healthy | yes | Steer users to nearest healthy region |

## Regions

- us-east
- eu-west
- ap-south
- me-central

## Optimizations (selected)

### Cloudflare
- Enable Argo Smart Routing for API paths under load
- Tighten WAF managed rules for /api/v1/*
- Cache static marketing assets aggressively; bypass portal cookies

### Vercel
- Pin production to dual regions with automatic failover
- Split long-running jobs off serverless to workers
- Use ISR/static where safe for marketing pages

### Supabase
- Enable PITR and cross-region read replica for DR
- Connection pooling via PgBouncer / Supavisor
- Index hot paths: licenses by email, audit by created_at

### RunPod
- Keep idle pods scaled to zero
- Use spot where interruption-tolerant
- Isolate network from Core and trading brokers

### Upstash Redis
- Multi-region active-passive with TTL-safe keys
- Separate DB indexes for rate-limit vs session
- Evict analytics keys aggressively
