# Architecture Overview — Phase 1 Complete (Build 10010)

**Product:** THE GOLD MIND AI PROFESSIONAL  
**Owner:** RTAS Group of Companies  
**Status:** Core Architecture **FROZEN** · Phase 1 **PASS**

## Design Goals (achieved)

| Goal | Status |
|------|--------|
| Modular | DONE — Include modules by domain |
| Scalable | DONE — Phase 2 extends via Bridge/interfaces |
| AI Ready | DONE — `Include/Phase2` contracts + Bridge |
| High Performance | DONE — soft Upsert, throttled sync, gated live checks |
| Maintainable | DONE — OOP, config, logging, validation |
| Commercial Grade | DONE — versioning, ownership, docs, freeze |
| Production Ready | DONE — FailSafe, Security, Recovery, Closure gate |

## Layered Architecture (Frozen Core + Phase 2 Surface)

```
┌─────────────────────────────────────────────────────────────┐
│  ENTRY                                                      │
│  Experts/TheGoldMindAI_Professional.mq5                     │
└────────────────────────────┬────────────────────────────────┘
                             │
┌────────────────────────────▼────────────────────────────────┐
│  APPLICATION                                                │
│  CGmApplication                                             │
│  + Phase1Closure · Phase2Bridge · ProductionHardening       │
└───────┬─────────────────────────────────────────────────────┘
        │
┌───────▼─────────────────────────────────────────────────────┐
│  FROZEN CORE                                                │
│  Calculation | Trading | Lifecycle | Risk | Session         │
│  TradeManagement | Protection | Recovery paths              │
└───────┬─────────────────────────────────────────────────────┘
        │ read-only
┌───────▼─────────────────────────────────────────────────────┐
│  PHASE 2 SURFACE                                            │
│  IGmAI* | IGmHedge | IGmAnalytics | IGmCloudSync            │
│  CGmPhase2Bridge                                            │
└─────────────────────────────────────────────────────────────┘
```

## Trade Lifecycle (summary)

Pending → Fill → Registry + Level ACTIVE → SL/TP management → BE → Partial 80% → Trail 20% runner → Close → Level COMPLETED/FAILED rules apply.

## Level Lifecycle (summary)

New H4 → generate 6 levels → place pendings → First SL → recreate Attempt=2 → Second SL → FAILED · TP → COMPLETED · New H4 resets levels (prior positions remain).

## Recovery Process (summary)

OnInit: Registry recover → Uncovered SL protect → TradeMgmt recover → Protection recover → Startup cycle → Validation → Phase1 Closure.

## Risk Flow (summary)

Equity × 3% → lot normalize → SL 30 pips → TP ATR×1.0 → broker validate → place only if capital/session/production gates allow.

## Session Flow (summary)

H4 bar change → session record → cancel stale own pendings per rules → new levels → sync throttled stats.

## Non-Negotiables

- Manual / magic 0 / foreign Magics never managed  
- Strategy math frozen  
- AI enhances, never replaces Core
