# Folder Structure — Phase 1 Final

```
THE GOLD MIND AI v2.0 Professional/
│
├── Experts/
│   └── TheGoldMindAI_Professional.mq5|.ex5
│
├── Include/
│   ├── Core/                 # Application, Version, ArchitectureFreeze, platform services
│   ├── Logging/              # CGmLogger
│   ├── Configuration/        # CGmConfiguration
│   ├── Trading/              # Ownership, Registry, TradeIds, Pending, Cycle, TradeManager
│   ├── Calculation/          # LevelEngine + FROZEN LevelConstants
│   ├── Lifecycle/            # Level DB / state / lifecycle
│   ├── Risk/                 # Lot / SL / ATR TP / Broker — FROZEN constants
│   ├── TradeManagement/      # BE / Partial / Trail — FROZEN constants
│   ├── Protection/           # Capital Protection
│   ├── Session/              # H4 Session / Sync / ExecutionControl
│   ├── Validation/           # Module / Trade / Lifecycle / Stress / Perf
│   ├── Backtesting/          # Metrics collector
│   ├── Production/           # FailSafe / Security / Live / Enterprise log
│   ├── Phase2/               # Interfaces + Bridge + Phase1 Closure
│   ├── AI/                   # CGmAIBase stub (Phase 2 implements interfaces)
│   ├── Recovery/             # Recovery base / snapshots
│   ├── Reports/              # Analytics base stub
│   ├── Orders/               # Placeholder (logic lives in Trading)
│   ├── Indicators/           # Placeholder
│   └── Utilities/            # Helpers
│
├── Documentation/
│   ├── Architecture/         # Overview, Freeze, FolderStructure, TradingRules, …
│   ├── Modules/
│   ├── Classes/
│   └── Guides/               # Sprint reports, Phase1 closure, handover, QA
│
├── Resources/
├── Tests/
└── README.md
```

## Phase 2 Extension Rule

Add new intelligence under `Include/Phase2/` (or new folders).  
Do **not** edit frozen Core math headers.
