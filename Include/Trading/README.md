# Include/Trading

Trade ownership, pending placement, Trade IDs, and H4 cycle control.

| File | Purpose |
|------|---------|
| `CTradeOwnership.mqh` | Magic Number gate — never touch manual/other EA |
| `CPendingOrderEngine.mqh` | Place/delete 3 Buy + 3 Sell pendings |
| `CTradeIdManager.mqh` | Unique internal Trade IDs (`GM_BLx#T{id}`) |
| `CCycleEngine.mqh` | Startup + new-H4 rollover |
| `CStrategyEngineBase.mqh` | Strategy engine base |
| `CTradeBase.mqh` | Trade management base (future) |
