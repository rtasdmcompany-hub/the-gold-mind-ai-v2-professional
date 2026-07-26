# Engine Separation Architecture

**Product:** THE GOLD MIND AI  
**Owner:** RTAS Group of Companies

Future AI modules integrate **without changing the core strategy**. Engines are isolated; no module may unnecessarily interfere with another.

```
                    ┌──────────────────────────┐
                    │     CGmApplication       │
                    │   (orchestrator only)    │
                    └────────────┬─────────────┘
         ┌───────────┬───────────┼───────────┬───────────┬───────────┐
         ▼           ▼           ▼           ▼           ▼           ▼
 ┌─────────────┐ ┌─────────┐ ┌───────┐ ┌──────────┐ ┌────────┐ ┌───────────┐
 │  Strategy   │ │  Trade  │ │ Risk  │ │ Recovery │ │   AI   │ │ Analytics │
 │   Engine    │ │  Mgmt   │ │Engine │ │  Engine  │ │ Layer  │ │  Engine   │
 │             │ │ Engine  │ │       │ │          │ │        │ │           │
 │ CGmStrategy │ │CGmTrade │ │CGmRisk│ │CGmRecov. │ │CGmAI   │ │CGmAnalyt. │
 │ EngineBase  │ │  Base   │ │ Base  │ │  Base    │ │ Base   │ │  Base     │
 └──────┬──────┘ └────┬────┘ └───┬───┘ └────┬─────┘ └───┬────┘ └─────┬─────┘
        │             │          │          │           │            │
        │             └─────▲────┴────▲─────┘           │            │
        │                   │         │                 │            │
        │            CGmTradeOwnership (Rules #1–#4)    │            │
        │                   │         │                 │            │
        └───────────────────┴─────────┴─────────────────┴────────────┘
                              Read-only analytics never sends orders
```

## Boundaries

| Engine | May calculate levels | May send/modify orders | May touch foreign/manual trades | May change strategy math |
|--------|----------------------|------------------------|----------------------------------|--------------------------|
| Strategy | Yes (intent only) | No (emits intents) | No | Owns strategy |
| Trade Management | No | Yes (own magic only) | **Never** | No |
| Risk | Limits / veto | Via Trade Mgmt only | **Never** | No |
| Recovery | State restore | Dedup / resume only | **Never** | No |
| AI | Advisory signals | No direct | **Never** | No (advises only) |
| Analytics | Observe / report | **Never** | **Never** | No |

## Integration Rule

New AI features plug into `CGmAIBase` derivatives and publish advisories to the Application / Strategy Engine.  
They must **not** rewrite Strategy Engine internals or bypass `CGmTradeOwnership`.
