# Phase 2 Handover Document

**From:** Phase 1 Core Team (Sprint 10 / Build 10010)  
**To:** Phase 2 AI / Analytics / Integration Team  
**Product:** THE GOLD MIND AI PROFESSIONAL  
**Date:** 2026-07-25

## Mission for Phase 2

Enhance the Gold Mind strategy with intelligence layers.  
**Do not replace** the Core Engine. **Do not modify** frozen calculation or risk constants.

## Entry Points

| Asset | Path |
|-------|------|
| Freeze contract | `Include/Core/ArchitectureFreeze.mqh` |
| Interfaces | `Include/Phase2/IPhase2Interfaces.mqh` |
| Read-only Core API | `Include/Phase2/CPhase2Bridge.mqh` |
| Closure engine (reference) | `Include/Phase2/CPhase1ClosureEngine.mqh` |
| Application wiring | `Include/Core/CApplication.mqh` |

## Hard Rules

1. Never change H4 level fractions, SL, ATR TP, BE/Partial/Trail constants.  
2. Never manage Magic 0, manual trades, or foreign Magics.  
3. AI decisions are **advisory** unless a future approved gate is added that still respects ownership.  
4. New features = new modules under `Include/Phase2/` (or new folders) calling the Bridge.  
5. Manual trades always remain untouched.

## Suggested First Phase 2 Sprint

1. Implement `IGmAIMarketAnalysis` stub → live insight logging.  
2. Implement `IGmAITradeScoring` for level tags via `PeekLevels()`.  
3. Wire advisory `IGmAIDecisionEngine` **behind a feature flag** (default OFF).  
4. Dashboard reads via Analytics + Bridge snapshots only.

## Non-Goals for Early Phase 2

- Rewriting Calculation / Risk / Lifecycle  
- Changing Magic ownership rules  
- Auto-hedging live capital without a dedicated approved sprint  

## Handover Checklist

- [x] Core compiles 0/0  
- [x] Architecture frozen flag `GM_CORE_ARCHITECTURE_FROZEN=1`  
- [x] Phase 2 interfaces shipped  
- [x] Bridge read-only APIs shipped  
- [ ] Stakeholder approval of Phase 1 Closure  
- [ ] Phase 2 kickoff authorized  

**Status: Ready for Phase 2 after approval.**
