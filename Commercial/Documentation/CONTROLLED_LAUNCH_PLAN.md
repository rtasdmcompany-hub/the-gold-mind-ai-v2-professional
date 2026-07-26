# CONTROLLED_LAUNCH_PLAN.md

**Product:** THE GOLD MIND AI v2.0 Professional  
**Phase:** 10 · Sprint 1  
**Mode:** Controlled Public Launch (invite-only) — **NOT** open global release  
**Core:** FROZEN  

---

## Principle

Customer trust has higher priority than rapid growth. Expand cohorts only after stability and satisfaction targets are met.

---

## Environments

| Environment | Access | Payments | Channel | Deploy rule (summary) |
|-------------|--------|----------|---------|------------------------|
| Development | none | sandbox | dev | Local · fixtures only |
| Internal QA | internal | sandbox | rc | Harness + Core hash PASS |
| Staging | internal | sandbox | rc | Production-like · webhook smoke |
| Production | invite_only | live | stable | Dual approval · health green |
| Controlled Beta | invite_only | live | rc | Roster + cohort caps |
| Future Public Stable | public | live | stable | **Blocked** until Owner GO |

Runtime: `TGM_LAUNCH_ENV` (default `controlled_beta`).  
Public Stable requires `TGM_PUBLIC_STABLE_AUTHORIZED=1` **and** Owner written GO.

Full rules: portal `src/server/launch/environments.ts` · admin Launch Dashboard.

---

## Rollout stages

1. **Internal** — RTAS team on Controlled Beta roster  
2. **VIP / Partners** — small invite waves  
3. **Professional traders / Beta testers** — expand only if gates pass  
4. **Public Stable** — future only  

## Expansion gates (before next cohort)

| Metric | Target |
|--------|--------|
| Critical open incidents | 0 |
| System health | healthy ≥ 7 consecutive days (or Owner waiver) |
| Activation success | ≥ 95% |
| Update success | ≥ 95% |
| Avg satisfaction | ≥ 4.0 / 5 (n ≥ 10) |
| Legal / Brand / Support board conditions | VERIFIED or Owner-waived |

## Hotfix policy

- Commercial bugs only  
- Core Trading Engine / Strategy / Risk / Recovery / Execution / Magic **never** patched in Phase 10 without new board certification  

## STOP

Await approval before Sprint 2 (first live invite wave execution).
