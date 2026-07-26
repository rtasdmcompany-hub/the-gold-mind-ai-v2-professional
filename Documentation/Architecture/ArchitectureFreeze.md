# Architecture Freeze Report — Phase 1 + Phase 2

**Build:** 21010  
**Flags:**  
- `GM_CORE_ARCHITECTURE_FROZEN = 1` (`PHASE1_CORE_FROZEN`)  
- `GM_DASHBOARD_ARCHITECTURE_FROZEN = 1` (`PHASE2_DASHBOARD_FROZEN`)  
- `GM_PHASE1_COMPLETE = 1` · `GM_PHASE2_COMPLETE = 1`

## Frozen Surfaces — Phase 1 Core

| Engine | Path | Freeze Meaning |
|--------|------|----------------|
| Calculation | `Include/Calculation/*` | Level fractions & H4 math locked |
| Trade | `Include/Trading/*` | Placement & ownership rules locked |
| Lifecycle | `Include/Lifecycle/*` | Level attempt / FAILED / COMPLETED locked |
| Risk | `Include/Risk/*` | 3% lot, 30 pip SL, ATR TP locked |
| Session | `Include/Session/*` | H4 session reset & sync contract locked |
| Recovery paths | Registry / Level DB / Session recovery | Soft/hard persist semantics locked |

## Frozen Surfaces — Phase 2 Dashboard Foundation

| Area | Path | Freeze Meaning |
|------|------|----------------|
| Dashboard Engine/UI | `Include/Dashboard/*` | Foundation locked — extend via APIs |
| Analytics | `Include/Analytics/*` | Observation contract locked |
| Journal / Alerts / Reports | `Include/Journal/*`, `Include/Reports/*` | Surfaces locked for consumers |
| AI Foundation stubs | `Include/AI/*` | Stubs remain; Phase 3 adds new modules |
| Multi-Instance | `Include/MultiInstance/*` | Monitor-only contract locked |
| Personalization | `Include/UI/*` | Theme/profile/locale surfaces locked |

## Allowed After Freeze

- New Phase 3 AI modules implementing `IPhase2Interfaces.mqh`  
- Calling `CGmPhase2Bridge` and Analytics snapshots  
- Feature-flagged advisory layers that respect Magic ownership  

## Forbidden After Freeze

- Editing Core strategy math / risk constants  
- Rewriting Dashboard Foundation instead of extending  
- Managing foreign Magics or magic 0 / manual trades  
- Letting AI open/close/modify trades without approved ownership gate  

## Marker Files

- `Include/Core/ArchitectureFreeze.mqh`  
- `Include/Phase2/CPhase2ClosureEngine.mqh`
