# BACKTEST PLAN — Phase 14 Institutional AI Validation

**Purpose:** Compare H4 engine performance with Phase 14 validation **OFF** vs **ON**.  
**Rule:** Identical market data, symbol, timeframe, and EA inputs except the Phase 14 flags.  
**Status:** Plan only — no code changes.

---

## 1. Test matrix

| Run | `AI_VALIDATION_ENABLED` | `AI_VALIDATION_ALLOW_OPTIONAL` | Expected behavior |
|-----|:-----------------------:|:------------------------------:|-------------------|
| **A — Baseline** | `false` | n/a (ignored) | Pure H4 engine (pre-P14 / pass-through) |
| **B — Validation ON** | `true` | `true` | Gate + optional 70–84 band allowed |
| **C — Strict (optional)** | `true` | `false` | Gate; reject below 85 (optional study) |

**Primary comparison:** Run A vs Run B.  
Run C is optional for sensitivity analysis.

---

## 2. Fixed conditions (both runs)

| Setting | Value |
|---------|--------|
| Expert | `TheGoldMindAI_Professional.mq5` (v2.068+) |
| Symbol | XAUUSD (or broker gold equivalent) |
| Chart / model TF | H4 |
| Tester model | Every tick based on real ticks (preferred) or 1-minute OHLC (document which) |
| Period | Same date range for A and B (recommend ≥ 12 months; state exact dates) |
| Deposit / leverage | Identical |
| Risk inputs | Identical (`RiskMode`, lots, ATR multipliers, BE/trail, Mode B) |
| Spread | Same modeling (current / official) |
| Phase11B supervisor | Same on/off for both runs |

**Only intentional delta:** Phase 14 feature flags.

---

## 3. Metrics to record

Capture from Strategy Tester **Results** / **Report** for each run:

| Metric | Run A (OFF) | Run B (ON) | Δ (B − A) | Δ % |
|--------|------------:|-----------:|----------:|----:|
| Total Trades | | | | |
| Win Rate (%) | | | | |
| Profit Factor | | | | |
| Max Drawdown (% and/or $) | | | | |
| Recovery Factor | | | | |
| Net Profit | | | | |
| Average Trade | | | | |
| Expected Payoff | | | | |

Optional extras (recommended, not required):

| Extra | Why |
|-------|-----|
| Gross profit / gross loss | Quality of wins vs losses |
| Sharpe Ratio (if available) | Risk-adjusted |
| Trades rejected by P14 (from Experts log count of `TGM [P14]: REJECT`) | Filter intensity |
| REAL NEWS vs PROXY MODE counts (`TGM [P14A-MARKET]`) | News path health |

---

## 4. Procedure

1. Compile EA (F7); confirm no errors.  
2. **Run A:** Inputs → `AI_VALIDATION_ENABLED = false` → Start → Save report as `BT_P14_OFF_<dates>.html` (or XML).  
3. Reset tester cache if needed so period/symbol match exactly.  
4. **Run B:** Same settings → `AI_VALIDATION_ENABLED = true`, `AI_VALIDATION_ALLOW_OPTIONAL = true` → Start → Save `BT_P14_ON_<dates>.html`.  
5. Fill the comparison table above.  
6. Review Journal for `TGM [P14]:` and `TGM [P14A-MARKET]:` lines on Run B only.  
7. (Optional) Run C with `AI_VALIDATION_ALLOW_OPTIONAL = false`.

---

## 5. Interpretation guide

| Observation | Likely meaning |
|-------------|----------------|
| Trades ↓, PF ↑, DD ↓ | Validation filtering weak setups (desired) |
| Trades ↓, Net Profit ↓ sharply | Gate too strict or optional band needed |
| Metrics ≈ identical | Flag off path OK, or few rejects in sample |
| ON run errors / zero trades | Calendar/session path or compile/deploy issue — verify Includes synced |

**Success criteria (Owner decision):** Document preferred outcome (e.g. DD down without destroying net profit). Phase 14 freeze does not require a specific numeric pass/fail in this plan.

---

## 6. Deliverables

- [ ] Run A report file  
- [ ] Run B report file  
- [ ] Completed metrics table  
- [ ] Short Owner note: keep default OFF / enable ON for live / further Phase 15 work  

---

## 7. Notes

- Default product flag remains **OFF** so historical backtests stay comparable to pre-Phase-14 baselines.  
- Do not change H4 strategy parameters between runs when measuring Phase 14 impact alone.
