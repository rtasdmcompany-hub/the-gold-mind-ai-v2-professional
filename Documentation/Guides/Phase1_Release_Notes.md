# Phase 1 Release Notes — Build 10010

**Product:** THE GOLD MIND AI PROFESSIONAL  
**Release:** Phase 1 Final / Sprint 10  
**Date:** 2026-07-25

## Highlights

- Core Trading Engine complete through Sprint 10  
- Architecture frozen for Phase 2 extension  
- Phase 2 Bridge + interface contracts shipped  
- Phase 1 Closure Engine writes enterprise closure report on startup  
- Compiler: **0 errors, 0 warnings**

## Binary

- Expert: `Experts/TheGoldMindAI_Professional.mq5`  
- Compiled: `Experts/TheGoldMindAI_Professional.ex5`  
- Build: **10010**

## Strategy (unchanged)

Official Gold Mind H4 grid, 3% risk, 30 pip SL, ATR TP, BE/Partial/Trail as documented in Phase 1 sprints.

## Breaking Changes

None for trading behavior. Strategy constants frozen.

## Upgrade Notes from RC-1 (9009)

1. Replace EA with build 10010.  
2. Keep Magic Number unchanged on live accounts with open GM positions.  
3. On first attach, review `GM_Phase1_Closure_Report.txt` under the terminal Files folder.  
4. Do not enable future AI hooks until Phase 2 approval.

## Known Limitations

See `Known_Limitations_Phase1.md`.
