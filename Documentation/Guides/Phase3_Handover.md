# Phase 3 Handover Package

**From:** Phase 2 Enterprise Dashboard Team (Sprint 10 / Build 21010)  
**To:** Phase 3 AI Intelligence Team  
**Product:** THE GOLD MIND AI PROFESSIONAL

## Mission

Build the AI Intelligence Engine as **independent modules** connected through existing APIs. Do not modify Core or Dashboard Foundation.

## System architecture (frozen layers)

```
Core Trading Engine (FROZEN)
        │ read-only
   CGmPhase2Bridge
        │
   Analytics / Journal / Reports / Multi-Instance (FROZEN surfaces)
        │
   Dashboard Foundation (FROZEN — READ-ONLY UI)
        │
   AI Foundation stubs ──► Phase 3 NEW MODULES (implement interfaces)
```

## Available APIs

### Core / Risk / Trade / Session (via Bridge)

| API | Method |
|-----|--------|
| Identity | `Magic()`, `Symbol()`, `IsOwnPosition()` |
| Session | `SessionId()`, `H4Cycle()` |
| Registry | `RegistryCount()`, `GetTrade()`, `GetRegistryAt()` |
| Positions/Pendings | `OwnPositions()`, `OwnPendings()` |
| Account / DD | `ReadAccount()`, `ReadDrawdown()` |
| Levels (observe) | `PeekLevels()` — does **not** place orders |
| Freeze | `CoreFrozen()` |

### Dashboard APIs

- `CGmDashboardEngine::GetSnapshot` / `RefreshNow` / `Process` / `QaReport`
- Settings/Theme/Profile via Personalization (UI only)

### Analytics APIs

- `CGmAnalyticsEngine::Collect` / `Snapshot` — WR, PF, RF, DD, nets, floating

### Logging / Files

- `CGmLogger` levels + `CGmFileManager::WriteText`

### AI stubs

- `CGmAIApi` Prepare* / BuildObservationJson / Invoke (returns false until live)
- Decision Center remains `NOT INITIALIZED` until Phase 3 fills it

## Reserved AI modules (interfaces)

See `Include/Phase2/IPhase2Interfaces.mqh`:
Decision, Market Analysis, Trade Scoring, Capital Protection AI, Hedge, Analytics, Cloud Sync, News, Confidence, Prediction, Recovery, REST, Cloud AI, GPT, Python Bridge.

## Database / persistence notes

- Trade registry / level DB / session logs remain Core-owned  
- AI modules may add **new** files under FileManager common folder — do not rewrite Core DBs  
- Multi-instance heartbeats: `GM_INST_*.hb` (FILE_COMMON)

## Integration guidelines

1. Feature-flag every AI advisory path (default OFF)  
2. Never call trade-send/modify APIs from AI modules in early sprints  
3. Magic ownership checks required before any future management advice is acted on  
4. Prefer snapshot → JSON → external service → advisory result → dashboard display  
5. Keep Manual trades completely isolated  

## Documents

- `Phase2_Closure_Report.md`
- `Enterprise_Dashboard_Completion_Report.md`
- `AI_Readiness_Report.md`
- `Phase3_Development_Roadmap.md`
- `Phase2_Sprint10_Report.md`

## Handover checklist

- [x] Phase 2 compiles 0/0  
- [x] Core frozen  
- [x] Dashboard frozen  
- [x] Interfaces + Bridge shipped  
- [x] AI readiness certified  
- [ ] Stakeholder approval of Phase 2 Closure  
- [ ] Phase 3 kickoff authorized  

**STOP here until approval.**
