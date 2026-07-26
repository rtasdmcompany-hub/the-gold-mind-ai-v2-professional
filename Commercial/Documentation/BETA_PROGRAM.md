# BETA_PROGRAM.md

**Phase:** 10 · Sprint 1  
**Type:** Invite-only Controlled Beta  

---

## Customer groups

| Group ID | Label |
|----------|-------|
| `internal_team` | Internal Team |
| `vip_customers` | VIP Customers |
| `professional_traders` | Professional Traders |
| `selected_partners` | Selected Partners |
| `beta_testers` | Beta Testers |

## Participant tracking

Admin UI: `/portal/admin/beta`  
API: `GET /api/admin/launch?view=beta`  
Store: encrypted `.data/launch/beta/participants.enc`

Fields: email · name · group · status · invite code · notes · invited/accepted · last seen

Statuses: `invited` → `accepted` → `active` → `paused` / `exited`

## Cohort cap

Default **50**. Adjustable by `admin.launch.write`. Seats remaining shown on Launch Dashboard.

## Seed (Sprint 1)

Demo roster seeded on first open (internal QA, VIP, pro trader, partner, beta tester). Replace with real invites before live traffic.

## Rules

1. No participant without roster entry  
2. Do not exceed cohort cap  
3. Pause / exit on abuse or unresolved Critical commercial issues  
4. Collect feedback via `/portal/feedback`  
5. Core remains frozen for all beta users  

## Success criteria for Sprint 2 invite wave

- Roster reviewed by Commercial + Owner  
- Monitoring green  
- Incident + notification playbooks acknowledged by on-call
