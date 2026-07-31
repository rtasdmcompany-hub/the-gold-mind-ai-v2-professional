# AI DECISION EVIDENCE — Phase 11D

**Generated:** 2026-07-30  
**Source:** Real MT5 Strategy Tester + `GM_P11B_EXEC_LEARN.csv`

## Required Evidence Presence

| Artifact | Present |
|----------|---------|
| `Phase11D_AI_ON.htm` | **YES** |
| `Phase11D_AI_OFF.htm` | **YES** |
| `GM_P11B_EXEC_LEARN.csv` | **YES** (413 lines) |
| `tester_AI_ON.log` / `tester_AI_OFF.log` | **YES** |

## Learn Log Action Census

| Action | Count | Meaning |
|--------|------:|---------|
| `ACTIVATED_READONLY` | 400 | AI stopped intervention after fill |
| `LOT_ADJUST` | 13 | Pre-activation lot change within policy |
| Forbidden actions (`MODIFY_TP`, `MODIFY_SL`, direction change, pending-price move) | **0** | |

Sample (real lines):

```text
2026.06.02 04:00:00,LOT_ADJUST,60.6,ExecConf=61 Band=CAUTION ... Caution - lot reduced up to 50% BEFORE activation.
2026.07.30 10:03:55,ACTIVATED_READONLY,69.3,ticket=1601702088
```

## Observed AI Behaviour vs Baseline

AI ON reduced pre-activation lot size under CAUTION confidence (example first pending: **0.5** vs AI OFF **1.0**), while preserving identical pending price / SL / TP / comment.

Deal-level parse:

- Direction same: 468/468
- Price same: 468/468
- Volume different: 464/468

## Conclusion

AI decisions are evidenced by real tester HTML reports and the Phase 11B learn CSV. Only permitted pre-activation lot adjustments and post-activation read-only marks were recorded.
