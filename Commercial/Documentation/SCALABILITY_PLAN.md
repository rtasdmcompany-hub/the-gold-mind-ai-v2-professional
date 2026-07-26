# SCALABILITY_PLAN.md

**Score:** 95 · 1M plan ready: true

| Tier | Users | Est. monthly USD | Key upgrades |
|------|------:|------------------|--------------|
| users_10k | 10,000 | 350–800 | Baseline monitoring |
| users_50k | 50,000 | 900–2200 | Read replica |
| users_100k | 100,000 | 2500–5500 | Autoscale policies |
| users_250k | 250,000 | 7000–14000 | Reserved Redis |
| users_1m_planning | 1,000,000 | 25000–60000 | Regional cells (US/EU/AP/ME) |

## 1,000,000 users (planning)

- Multi-region active-active data plane
- Cell-based tenancy for enterprise orgs
- Separate analytics warehouse
