# MARKET VALIDATOR REPORT — Phase 14A Finalization

**Module:** `Include/AI/InstitutionalValidation/CMarketValidator.mqh`  
**Date:** 2026-08-07  
**Scope:** MarketValidator upgrade only  
**Not modified:** H4 Strategy · StructureValidator · InstitutionalValidator · TPSLOptimizer · ConfidenceCalculator  

---

## Objective

Upgrade MarketValidator from **Partial** to production-grade market hygiene with:

- Real session / weekend / market-closed detection  
- Abnormal spread detection  
- Abnormal ATR / volatility detection  
- MT5 Economic Calendar when available (**REAL NEWS**)  
- Automatic **PROXY MODE** fallback when calendar unavailable  
- Never block trades solely because news data is missing  
- Explicit logging of news decision source  

---

## Status

| Area | Before (14) | After (14A) |
|------|-------------|-------------|
| Overall MarketValidator | ⚠ Partial | ✔ Fully Implemented *(with documented soft proxy)* |
| Trading sessions | Weekend only | Asia / London / NY / Overlap / Off-hours / Closed |
| Weekend / market closed | Day-of-week only | Weekend + Friday-late + broker trade mode + quote sessions |
| Abnormal spread | Absolute points only | Absolute + vs broker typical `SYMBOL_SPREAD` |
| Abnormal ATR / volatility | Spike vs median only | Spike + abnormally low ATR |
| News | Calendar only, fail-open silent | REAL NEWS vs PROXY MODE with logs |
| Unavailable news blocking | Soft | Guaranteed: proxy never hard-blocks for missing calendar |

---

## Implementation details

### 1. Trading sessions

Detected in UTC for XAU:

| Session | Hours (UTC) | Score effect |
|---------|-------------|--------------|
| London / NY overlap | 12–16 | +10 (prime) |
| London | 07–12 | +8 |
| New York | 16–21 | +8 |
| Asia | 00–07 | +3 (quiet) |
| Off-hours | other open | −8 (thin) |
| Closed | weekend / Friday ≥21 / broker closed | −40 |

Reason string includes `sess=LONDON_NY_OVERLAP` (etc.).

### 2. Weekend / market closed

- Saturday / Sunday → closed  
- Friday ≥ 21:00 UTC → late close  
- `SYMBOL_TRADE_MODE_DISABLED` → closed  
- Broker `SymbolInfoSessionQuote` — if sessions exist and now is outside all → closed  

### 3. Abnormal spread

Uses live ask−bid points and broker typical spread:

- **Abnormal** if ≥ max(500 pts, typical × 3) → −35  
- **Elevated** if ≥ max(250 pts, typical × 1.8) → −14  
- Else → +8  

### 4. Abnormal ATR / volatility

Uses shared H4 ATR handle:

- Missing ATR → −10  
- ATR > median(14) × 2.5 → **ABNORMAL-ATR-SPIKE** (−22)  
- ATR < median(14) × 0.35 → abnormal low (−12)  
- Else → +8  

### 5. News — REAL vs PROXY

| Mode | When | Behavior |
|------|------|----------|
| **REAL NEWS** | `CalendarValueHistory` probe succeeds (`n ≥ 0`, no error) | Scan US + EU high-impact ±30 minutes |
| **PROXY MODE** | Calendar API unavailable / error | Soft heuristic windows only (NFP / FOMC-ish) |

Rules:

- Empty calendar result under REAL NEWS = **clear** (not a block)  
- PROXY MODE applies **soft** score penalty only (−10), never a dedicated hard news reject for missing data  
- Module `pass` still uses score ≥ 50 (closed market / extreme spread+ATR can fail)  

### 6. Logging

Every validation prints:

```
TGM [P14A-MARKET]: REAL NEWS | pass=Y conf=82 | Market: ...
TGM [P14A-MARKET]: PROXY MODE | pass=Y conf=74 | Market: ...
```

Reason string also embeds `[REAL NEWS]` or `[PROXY MODE]`.

### 7. Backward compatibility

- Public API unchanged: `Validate(const bool isBuy) → SGmP14ModuleResult`  
- `SetAtrHandle(int)` unchanged  
- Engine / other validators / H4 strategy untouched  
- Feature flag path unchanged (`AI_VALIDATION_ENABLED`)  

---

## Verification checklist

| Requirement | Status |
|-------------|:------:|
| Detect trading sessions correctly | ✔ |
| Detect weekend / market closed | ✔ |
| Detect abnormal spread | ✔ |
| Detect abnormal ATR / volatility | ✔ |
| Use MT5 Economic Calendar when available | ✔ |
| Auto fallback to proxy when calendar unavailable | ✔ |
| Never block solely for unavailable news data | ✔ |
| Log REAL NEWS vs PROXY MODE | ✔ |
| Keep backward compatibility | ✔ |
| No H4 strategy changes | ✔ |

---

## Residual notes (non-blocking)

- Session hours are UTC approximations for XAU; broker server offsets may differ slightly — quote-session check compensates when broker publishes sessions.  
- PROXY news windows are heuristics, intentionally soft.  
- Directional “bias±” H4 average remains as a light compatibility scorer (not a full fundamental model).

---

## Sign-off

**Phase 14A MarketValidator finalization complete.**  
MarketValidator is production-ready for use under the existing Phase 14 gate.
