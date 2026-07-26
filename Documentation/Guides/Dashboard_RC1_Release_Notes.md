# Dashboard-RC-1 — Release Notes

**Product:** THE GOLD MIND AI PROFESSIONAL  
**Build:** 21009  
**Label:** Dashboard-RC-1  
**Sprint:** Phase 2 / Sprint 9

## Summary

Enterprise Dashboard certified as a production **monitoring** release candidate. Includes stress suite, sync/visual/settings/recovery validation, performance monitoring, and long-runtime milestones (12/24/48/72h).

## What changed

- Dashboard QA engine under `Include/Dashboard/QA/`
- UI performance: layout throttle, skip-unchanged widget updates, adaptive refresh under load
- Automatic QA suite on dashboard load; reports written via FileManager

## What did **not** change

- Core Trading Engine
- Gold Mind level calculation
- Risk Management / protection rules
- Order execution paths

## Operator notes

- Dashboard is **READ-ONLY** — never places, closes, or modifies trades/orders
- Long-runtime milestones log when the EA is left running continuously
- Review `GM_DASH_QA_Enterprise_QA_Report.txt` after attach for PASS/FAIL scorecard

## Production checklist

See `GM_DASH_QA_Production_Checklist.txt` and Sprint 9 report.
