# Architecture Report — RC-1

```
EA → CGmApplication
  ├── Configuration (Protection + Session + Validation + Production)
  ├── FailSafe / Security / LiveExec (Production)
  ├── Capital Protection
  ├── H4 Session + Execution Control
  ├── Cycle → Levels → Pendings → Trade Manager
  ├── Trade Management (BE / Partial / Trail)
  ├── Level Lifecycle
  ├── Validation + Backtest (Sprint 8)
  └── Stubs: AI / Analytics / Recovery AI
```

Strategy calculation remains isolated in `Include/Calculation/`.  
Production hardening never mutates level fractions, SL pips, ATR multiplier, or BE/Partial/Trail constants.
