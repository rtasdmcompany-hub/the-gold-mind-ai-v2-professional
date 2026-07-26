# Risk Report — Phase 1 Final (Build 10010)

## Strategy Risk (frozen)

| Control | Setting |
|---------|---------|
| Equity risk per trade | 3% |
| Fixed SL | 30 pips |
| TP | ATR(14)×1.0 H4 |
| BE | +50 pips once |
| Partial | 80% / 20% |
| Trail | 30 pips |

## Operational Risks & Mitigations

| Risk | Mitigation |
|------|------------|
| Managing manual trades | Magic + Trade ID ownership gates |
| Duplicate pendings | ExecutionControl + SecurityGuard |
| Disconnect | FailSafe blocks new entries; open positions retained |
| Registry loss | Flush cadence + hard persist on BE/Partial/Trail |
| Strategy drift in Phase 2 | Architecture Freeze + constant warnings |
| AI overriding Core | Interfaces advisory; Bridge read-only |

## Capital Protection

Sprint 6 Capital Protection remains warn-oriented for drawdown thresholds (no unauthorized strategy halt invented in Phase 1). Phase 2 Capital Protection AI may advise pause — must be feature-flagged.

## Residual Risk

Broker conditions (spread, requotes, holidays) can still reject or delay execution. Operators must validate on demo with the target broker before live.
