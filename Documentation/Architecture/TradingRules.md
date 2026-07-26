# Trading Rules — THE GOLD MIND AI

**Owner:** RTAS Group of Companies  
**Division:** RTAS Digital Marketing Company  
**Status:** NON-NEGOTIABLE proprietary rules  
**Encoded in:** `Include/Core/TradingRules.mqh`, `Include/Trading/CTradeOwnership.mqh`

---

## Rule #1 — Own trades only

The Gold Mind AI will **ONLY** manage trades created by itself.

## Rule #2 — Never touch manual trades

The EA must **NEVER**:

- modify
- close
- trail
- hedge
- partially close
- move Stop Loss
- move Take Profit
- interfere in any way

…with **ANY** manually opened trade (typically Magic = 0).

## Rule #3 — Never manage other EAs

The EA must **NEVER** manage trades opened by another Expert Advisor.

## Rule #4 — Magic Number ownership

- Every trade opened by The Gold Mind AI must use the configured **Magic Number**.
- **Only** trades with this Magic Number may be managed.
- All other trades must be **completely ignored**.

**Enforcement gate:** `CGmTradeOwnership` — every future management action must pass `CanManageMagic` / `CanManagePosition` / `CanManageOrder`.

---

## Startup Behaviour

The EA becomes active **immediately** after attach.

It must **NOT** wait for the next H4 candle.

On initialization (when strategy sprint is enabled):

1. Detect the most recently **CLOSED** H4 candle
2. Read High and Low
3. Calculate all trading levels (official Gold Mind method)
4. Place required pending orders for the **current** H4 cycle
5. Continue on every new H4 candle close

**Policy constants:** `GM_POLICY_STRATEGY_TIMEFRAME = PERIOD_H4`, `GM_POLICY_ACTIVATE_IMMEDIATELY`, `GM_POLICY_USE_LAST_CLOSED_H4`

---

## Recovery Behaviour

On EA restart / MT5 restart / PC restart / internet reconnect:

1. Detect existing Gold Mind trades via Magic Number
2. Restore internal state
3. **Never** duplicate pending orders
4. **Never** open duplicate trades
5. Continue managing **only** own trades

**Framework:** `CGmRecoveryBase::RecoverState()` runs on every `OnInit`.
