# Developer Notes — Phase 1 Frozen Core

## Ownership

Only Gold Mind trades identified by the official Magic Number **and** internal Trade ID may be managed.

## Include Path

Always compile with `/include` = project root (`THE GOLD MIND AI v2.0 Professional`).

## Where to Add Features

| Need | Place |
|------|-------|
| AI / scoring / hedge / cloud | `Include/Phase2/` or new sibling folders |
| Read Core state | `CGmPhase2Bridge` |
| Change strategy math | **FORBIDDEN** without new product version & approval |

## Key Classes

`CGmApplication` → Config, Logger, Ownership, Registry, Risk, Protection, LevelManager, LevelEngine, Pending, Cycle, H4Session, TradeManager/TradeMgmt, Validation, Production, Phase2Bridge, Phase1Closure

## Persistence

- Soft Upsert: profit-only registry updates (Flush later)  
- Hard Upsert: BE / Partial / Trail / structural changes  

## Testing

Prefer Validation On Startup on demo. Closure report is written each Init via `CGmPhase1ClosureEngine`.

## Style

Match existing MQL5 patterns, include guards, and RTAS copyright headers. Do not invent strategy numbers.
