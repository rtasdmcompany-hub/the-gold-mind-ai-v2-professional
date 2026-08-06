# PHASE 14 — VALIDATION REPORT

**Product:** THE GOLD MIND AI PROFESSIONAL  
**Module path:** `Include/AI/InstitutionalValidation/`  
**EA build:** v2.068 (Phase 14 enhancement layer)  
**Report date:** 2026-08-07  
**Scope:** Verification only — no H4 Trading Engine changes  

**Legend**

| Mark | Meaning |
|:----:|---------|
| ✔ | Fully Implemented — real logic present and wired into scoring |
| ⚠ | Partially Implemented — real logic, but simplified / limited coverage |
| ✖ | Placeholder / Stub — empty, hardcoded default-only, or NOT IMPLEMENTED |

---

## Executive summary

| Module | Overall |
|--------|---------|
| StructureValidator | ✔ Fully Implemented |
| InstitutionalValidator | ✔ Fully Implemented *(Session Bias stub fixed during audit)* |
| MarketValidator | ⚠ Partially Implemented *(session = weekend-only; fundamentals = proxy)* |
| TPSLOptimizer | ✔ Fully Implemented |
| ConfidenceCalculator | ✔ Fully Implemented |
| InstitutionalValidationEngine | ✔ Fully Implemented |

| Metric | Count |
|--------|------:|
| Placeholder / stub functions | **0** |
| `TODO` / `FIXME` / `placeholder` comments | **0** |
| Functions that return defaults only (no market logic) | **0** *(after Session Bias fix)* |
| Modules still requiring implementation | **0** for production gate; Market session depth remains **optional hardening** (⚠) |

**Verdict:** Phase 14 is **production-ready** as an enhancement layer when `AI_VALIDATION_ENABLED=true`. With flag `false`, behavior is pass-through (existing backtests unchanged).

---

## 1. StructureValidator (`CStructureValidator.mqh`)

| Capability | Status | Evidence |
|------------|:------:|----------|
| Higher High / Higher Low | ✔ | `hh = (sh1 > sh2)`, `hl = (sl1 > sl2)`; `bullStruct = hh && hl` |
| Lower High / Lower Low | ✔ | `lh = (sh1 < sh2)`, `ll = (sl1 < sl2)`; `bearStruct = lh && ll` |
| Structure Break | ✔ | `bullBreak` / `bearBreak` via H4 close vs swing high/low |
| Trend Continuation | ✔ | `continuationBuy/Sell = struct && !fakeBreak` |
| Pullback | ✔ | Entry vs mid-range between swings (`pullbackBuy/Sell`) |
| Retest | ✔ | Entry within 15% of swing range of HL/LH (`retestBuy/Sell`) |
| Fake Break | ✔ | Break on bar1 then close0 back inside (`fakeBull` / `fakeBear`) |

**Notes**

- Swing detection uses real fractal-style `FindSwingHigh` / `FindSwingLow` on `PERIOD_H4`.
- If swings cannot be found: neutral PASS at confidence 70 — **graceful degradation**, not a stub.
- Pullback and Retest are computed as separate flags; scoring may combine them in the reason string.

**Module overall:** ✔ Fully Implemented

---

## 2. InstitutionalValidator (`CInstitutionalValidator.mqh`)

| Capability | Status | Evidence |
|------------|:------:|----------|
| BOS | ✔ | Close vs 20-bar swing high/low (`bosBuy` / `bosSell`) |
| CHoCH | ✔ | Against-direction character change vs bar-3 high/low; scored as penalty |
| Liquidity | ✔ | Equal highs / equal lows within 5% of range |
| Order Block | ✔ | `DetectOrderBlock()` — last opposing candle before impulse (bars 2–6) |
| Fair Value Gap | ✔ | `DetectFVG()` — 3-candle H4 imbalance |
| Premium / Discount | ✔ | Entry vs mid of 20-bar range |
| Session Bias | ✔ | Hour bands + H4 momentum alignment *(was stub `isBuy?8:8`; fixed)* |

**Notes**

- BOS/CHoCH are **lightweight institutional approximations** (not a full ICT library), but they are **real calculations**, not placeholders.
- Pre-fix Session Bias returned identical scores for buy and sell — marked as stub behavior and **completed** during this verification (momentum-aligned London/NY scoring).

**Module overall:** ✔ Fully Implemented

---

## 3. MarketValidator (`CMarketValidator.mqh`)

| Capability | Status | Evidence |
|------------|:------:|----------|
| ATR calculation | ✔ | `ReadAtr()` via shared `iATR` handle `CopyBuffer` |
| Spread filter | ✔ | Live ask−bid in points vs `GM_P14_MAX_SPREAD_POINTS` |
| Volatility filter | ✔ | ATR vs median ATR(14); spike if `> 2.5×` median |
| Session filter | ⚠ | Weekend closed only; weekday always OK (no Friday-late / thin-session band) |
| Fundamental / News | ⚠ | News: real `CalendarValueHistory` USD high-impact ±30m (fail-open if empty). Fundamental: H4 5-bar close vs average **proxy**, not true fundamentals |

**NOT IMPLEMENTED (explicit)**

| Item | Mark |
|------|:----:|
| Full multi-currency / XAU-specific economic calendar mapping | ✖ *(not required for lightweight gate; USD HI window is used)* |
| True fundamental model (rates, DXY, COT, etc.) | ✖ *(proxy only — documented)* |

**Module overall:** ⚠ Partially Implemented  
Still **usable in production** as a market hygiene gate. Remaining depth is optional hardening, not a blocker for Phase 14 enablement.

---

## 4. TPSLOptimizer (`CTPSLOptimizer.mqh`)

| Rule | Status | Evidence |
|------|:------:|----------|
| TP/SL only validated (no strategy redesign) | ✔ | Operates on caller-supplied entry/SL/TP only |
| Preserve existing TP/SL when valid | ✔ | Valid side/distance → keep; optional nearer TP only if within cap |
| SL adjustment ≤ 20% ATR | ✔ | `maxAdj = atr * GM_P14_SL_ATR_ADJUST_MAX` (0.20); tight-SL widen gated by `MathAbs(delta) <= maxAdj` |
| TP → nearest valid liquidity | ✔ | `NearestLiquidityTarget()` scans H4 highs/lows within ~1.5 ATR |
| No H4 strategy redesign | ✔ | Does not touch levels, lots, grid, or recovery |

**Notes**

- If SL is **invalid / missing**, optimizer may heal to ~1× ATR distance so the order is not sent naked. That is validation heal, not H4 redesign.
- Valid SL that is already sane is left unchanged.

**Module overall:** ✔ Fully Implemented

---

## 5. ConfidenceCalculator (`CConfidenceCalculator.mqh`)

| Rule | Status | Evidence |
|------|:------:|----------|
| H4 = 60% | ✔ | `GM_P14_W_H4 = 0.60` |
| Structure = 20% | ✔ | `GM_P14_W_STRUCTURE = 0.20` |
| Institutional = 10% | ✔ | `GM_P14_W_INSTITUTIONAL = 0.10` |
| Market = 10% | ✔ | `GM_P14_W_MARKET = 0.10` |
| ≥ 85 Execute | ✔ | `GM_P14_CONF_EXECUTE = 85.0` → `GM_P14_EXECUTE` |
| 70–84 Optional | ✔ | `GM_P14_CONF_OPTIONAL = 70.0` → `GM_P14_OPTIONAL` |
| &lt; 70 Reject | ✔ | else `GM_P14_REJECT` |

**Engine wiring (`CInstitutionalValidationEngine`)**

- H4 confidence fixed at **100** when H4 engine requests placement (strategy already decided).
- Optional band honored via `AI_VALIDATION_ALLOW_OPTIONAL`.
- Flag OFF → pass-through (intentional; not a stub).

**Module overall:** ✔ Fully Implemented

---

## 6. Audit counts (InstitutionalValidation folder)

| Check | Result |
|-------|--------|
| `TODO` / `FIXME` / `XXX` / `placeholder` / `stub` comments | **0** |
| Empty stub functions (`return true` with no logic) | **0** |
| Functions returning only hardcoded defaults with no market input | **0** after Session Bias fix |
| Pure ✖ placeholder modules | **0** |

### Items fixed during verification (stub-only policy)

| Item | Action |
|------|--------|
| `CInstitutionalValidator::SessionBiasScore` | Was directionally stubbed (`isBuy ? 8 : 8`). Replaced with session + H4 momentum alignment. |

No other code changes were made. H4 Trading Engine was not modified.

---

## 7. Production readiness

| Criterion | Status |
|-----------|--------|
| Feature flag `AI_VALIDATION_ENABLED` (default OFF) | ✔ |
| Modular validators | ✔ |
| Hook only before Place*/OrderSend | ✔ |
| No UI / No DB | ✔ |
| Backtests unchanged when flag OFF | ✔ |
| Real (non-placeholder) validators | ✔ |
| Known partials documented | ⚠ Market session depth + fundamental proxy |

### Optional follow-ups (NOT blocking — out of stub scope)

1. MarketValidator: Friday-late / rollover session bands  
2. MarketValidator: richer fundamental inputs if product requires them later  
3. Institutional BOS/CHoCH: deeper swing-based state machine (still real today)

---

## 8. Sign-off

**Phase 14 verification complete.**  
No placeholder modules remain. One directional Session Bias stub was completed.  
**Phase 14 is production-ready** as an optional Institutional AI Validation enhancement layer over the frozen H4 Trading Engine.
