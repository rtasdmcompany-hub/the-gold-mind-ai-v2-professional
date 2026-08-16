# H4 POWER CONFIG — Evidence-based upgrade

**Date:** 2026-08-16  
**Production EX5 freeze (unchanged):** `21503FA83938CF80AA24947A512EBE2F238AC7512BF9E48A21FBFF647D77F9B7`

## What we locked / changed

| Control | Old | New | Why |
|---|---|---|---|
| H4 range filter | 250 | **250 (LOCKED)** | Phase34: range 400 rejected (worse IS/OOS) |
| Max activations / level / H4 | **2** (re-arm) | **1** (no re-arm) | Phase30: re-arm REJECTED — OOS Act2 SL ≈ −$2,980 |
| Per-level 400 distance | research only | **REMOVED** | Wrong fix for “more trades”; not the bleed cause |
| Ahmed / SBT / Phase14 | off | **off** | Not proven |

## Files updated

- `Include/AI/RiskGovernor/Phase17/CPhase17RiskGovernor.mqh` — defaults: range 250, activations **1**
- `Commercial/Documentation/Phase18/Phase18_DEFAULT_PROTECTIONS.set` — activations **1**
- Research MQ5: 400-distance gate removed; power notes updated

## What this does NOT claim

- Does **not** guarantee every calendar month is green (Phase30 control OOS was still −$1,496 / PF 0.84).
- Does claim: removes the **proven harmful** re-arm path that doubled OOS damage (PF 0.84 → 0.44).

## Validation

Backtest: frozen production EX5 + updated set (range 250, act 1), same 3M window:

| | Act=2 (old default) | Act=1 (power) |
|---|---:|---:|
| Net | −2,799 | **−1,496** |
| PF | 0.44 | **0.84** |
| Trades | 36 | **68** |

Full write-up: `H4POWER_ACT1_3M_BACKTEST_REPORT.md`
