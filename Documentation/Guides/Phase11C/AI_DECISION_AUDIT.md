# AI Decision Audit — Phase 11C

**Generated:** 2026-07-30T09:11:08.107Z

## Owner Rules Applied

```json
{
  "maxLotIncreasePct": 20,
  "maxLotReducePct": 50,
  "maxFreezeMin": 30,
  "emergencyCancel": true,
  "newsProtection": true,
  "brokerProtection": true,
  "weekendProtection": true,
  "minLot": 0.01,
  "maxLotCap": 5
}
```

## Band Policy Evidence

| Confidence | Band | Action |
|------------|------|--------|
| 97 | EXTREMELY_STRONG | INCREASE_LOT |
| 85 | STRONG | NORMAL |
| 70 | CAUTION | REDUCE_LOT |
| 50 | HIGH_RISK | FREEZE |
| 30 | EXTREME_RISK | CANCEL |

## Forbidden Mutations (Static)

- PASS: TGM_RISK_PER_TRADE_FRACTION=0.03 unchanged
- PASS: CalculateAutoLotSize has no GmP11B calls
- PASS: AI authority has no PositionClose/OrderModify/SLTP mutate
- PASS: OrderDelete present (pending freeze/cancel only)
- PASS: EA has AdjustLot + OnTick hooks
- PASS: Lot adjust wraps GetTradeVolume output only
- PASS: Activation ends AI authority
- PASS: Failsafe disable paths present
- PASS: No forbidden SL/TP/deal mutate patterns in AI layer

## Failsafe Audit

- **AI timeout:** failsafe=true engineContinues=true — FAILSAFE: analysis timeout — AI disabled | Trading Engine continues
- **AI crash:** failsafe=true engineContinues=true — FAILSAFE: AI crash — AI disabled | Trading Engine continues
- **AI invalid data:** failsafe=true engineContinues=true — FAILSAFE: invalid ATR — AI disabled | Trading Engine continues
- **AI disconnect:** failsafe=true engineContinues=true — FAILSAFE: AI disconnect — AI disabled | Trading Engine continues
- **AI exception:** failsafe=true engineContinues=true — FAILSAFE: exception — forced AI exception | Trading Engine continues normally

## Failures

- Missing real MT5/broker historical replay artifacts; deterministic scenario replay cannot prove production behavior

## Verdict

FAIL
