# System Architecture — Enterprise (Phase 1)

Companion to `Overview.md`. Build **10010**.

## Module Descriptions (short)

| Module | Responsibility |
|--------|----------------|
| H4 Detection / Time | Detect H4 cycle boundaries |
| Calculation | Official grid levels from H4 high/low/diff |
| Pending Order Engine | Place/manage own pendings with gates |
| Trade Registry | Soft/hard persistence of GM trades |
| Magic + Trade ID | Ownership identity |
| Risk | Lot, SL, ATR TP, broker checks |
| Lifecycle | Level attempts, COMPLETED/FAILED |
| Trade Management | BE, Partial, Trail |
| Capital Protection | Exposure / DD monitoring |
| Session | H4 session record + sync |
| Validation | Startup QA suite |
| Production | FailSafe, Security, Live, logging context |
| Phase2 Bridge | Read-only Core API for future AI |
| Phase1 Closure | Final audit report + PASS/FAIL |

## Data Stores

- Trade Registry file  
- Level Database file  
- Session records  
- Logs + Closure / RC reports under Files  

## Extension Seam

Phase 2 modules consume `CGmPhase2Bridge` and implement `IGm*` interfaces. Core tick path remains authoritative for order placement and trade management.
