# ISSUE_TRACKER.md

**Phase:** 10 · Sprint 2  
**Console:** `/portal/admin/issues`  

---

## Priority

| Code | Meaning |
|------|---------|
| P0 | Critical — stop cohort expansion; hotfix/rollback |
| P1 | High — fix this sprint if commercial |
| P2 | Medium — scheduled |
| P3 | Low / feature backlog |

## Fields

Status · Owner · Target Fix · Verification · Resolution Date · Kind (`bug` | `feature_request`)

## Status flow

`open` → `in_progress` → `blocked?` → `resolved` → `verified` → `closed`

## Seed examples

- P1 unsigned installer SmartScreen (commercial packaging)  
- P3 dark mode feature (deferred)  
- P2 sandbox email delay (verified)

## Hard rule

No issue may authorize modification of Trading Engine, Strategy, Risk, Recovery, Order Execution, or Magic Number logic.
