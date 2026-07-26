# Phase 3 Development Roadmap

**From:** Phase 2 Closure (Build 21010)  
**To:** AI Intelligence Engine Team  
**Prerequisite:** Stakeholder approval of Phase 2 Closure

## Hard rules (non-negotiable)

1. Never modify Core Trading Engine / Gold Mind math / Risk Management  
2. Never modify Dashboard Foundation internals (frozen)  
3. Never manage Magic 0, manual trades, or foreign Magics  
4. AI is advisory-first; any future execution gate must still respect ownership  
5. New code = new modules under `Include/AI/` (or new folders), not forks of Core/Dashboard

## Suggested sprints

### Sprint 1 — Market Analysis + Confidence
- Implement `IGmAIMarketAnalysis` + `IGmAIConfidenceMeter`
- Log insights only; dashboard widgets consume snapshot fields

### Sprint 2 — Trade / Level Scoring
- Implement `IGmAITradeScoring` using `PeekLevels()` + registry reads
- Surface scores on AI Dashboard (replace `NOT INITIALIZED` where approved)

### Sprint 3 — Decision Advisory (feature-flag OFF by default)
- Implement `IGmAIDecisionEngine`
- Optional pause-new-pending advisory into Protection layer (no direct order send)

### Sprint 4 — External services
- Python bridge + REST + Cloud + GPT behind `CGmAIApi` / reserved interfaces
- Keep payloads observation-only until security review

### Sprint 5 — News / Prediction / Recovery AI
- `IGmAINewsAnalyzer`, `IGmAIPredictionEngine`, `IGmAIRecoveryEngine`
- Full integration tests + ownership regression suite

## First engineering tasks

1. Read `Documentation/Guides/Phase3_Handover.md`  
2. Scaffold `Include/AI/Phase3/` (or equivalent) modules implementing interfaces  
3. Wire behind feature flags in `CApplication` without touching Core tick math  
4. Extend AI Dashboard widgets to display live advisory status  

## Non-goals (early Phase 3)

- Rewriting Calculation / Risk / Lifecycle  
- Auto-hedging live capital without dedicated approval  
- Letting AI close manual trades  

**Status: Roadmap ready — WAIT for Phase 2 approval before coding Phase 3.**
