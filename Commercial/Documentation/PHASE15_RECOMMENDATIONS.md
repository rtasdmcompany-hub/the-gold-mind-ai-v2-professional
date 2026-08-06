# PHASE 15 — RECOMMENDATIONS

**Status:** Recommendations only  
**Date:** 2026-08-07  
**Constraint:** No implementation · No code · No commits · No refactoring in this document  

Phase 14 (Institutional AI Validation) is **FEATURE FROZEN**. Phase 15 work must be newly authorized by Owner before any engineering starts.

---

## 1. Positioning

Phase 15 should treat Phase 14 as a **stable gate** and focus on measurement, tuning policy, and optional adjacent capabilities — **without** reopening H4 Trading Engine design.

---

## 2. Recommended themes

### 2.1 Validation analytics (highest priority)

- Persist per-placement Phase 14 scores (structure / institutional / market / final / verdict) to a lightweight log or CSV for offline analysis.  
- Dashboard or report: reject rate, optional rate, REAL NEWS vs PROXY MODE mix.  
- Correlate rejects with subsequent “would-have” MFE/MAE (shadow scoring) — analysis only.

### 2.2 Backtest & forward evidence

- Execute `BACKTEST_PLAN.md` (OFF vs ON) and archive Owner-signed results.  
- Forward demo window with `AI_VALIDATION_ENABLED=true` under controlled risk.  
- Define Owner go-live policy: default OFF vs ON for production Professional builds.

### 2.3 Confidence policy (config-only candidates)

- Owner-configurable thresholds (still ≥85 / 70–84 / &lt;70 as defaults) — **only if** authorized as Phase 15 inputs, not silent code tweaks.  
- Optional: separate optional-band lot haircut (e.g. 70–84 → 75% size) — recommendation only; not in Phase 14.

### 2.4 MarketValidator depth (optional hardening)

- Broker-server timezone alignment for session maps.  
- Expanded calendar country set for XAU (e.g. CN / JP) under REAL NEWS.  
- Richer PROXY calendar (non-blocking) — keep fail-open rule absolute.

### 2.5 Institutional / Structure depth (optional)

- Deeper swing-state BOS/CHoCH machine (still validation-only).  
- Multi-timeframe structure confirm (e.g. D1 bias filter) as an **extra weight**, not H4 replacement.

### 2.6 Operational

- MetaQuotes Include sync checklist in release engineering.  
- Compile gate in CI (syntax) for `InstitutionalValidation/*.mqh` if build pipeline allows.  
- Document frozen SHA / build serial pairing for Professional packages.

---

## 3. Explicit non-goals for Phase 15

Unless Owner reopens scope:

- Do **not** modify H4 grid / levels / shared ATR SL strategy math.  
- Do **not** resurrect Mode A hedge/loss-cap.  
- Do **not** turn Phase 14 into a new trading strategy.  
- Do **not** add UI panels for Phase 14 unless separately authorized.  
- Do **not** add database dependencies to the EA runtime path.

---

## 4. Suggested Phase 15 success criteria (Owner to confirm)

1. OFF vs ON backtest table completed and archived.  
2. Live/demo reject rate within an Owner-agreed band (e.g. 5–25%).  
3. No increase in OrderSend errors attributable to validation.  
4. Clear written policy: when Professional ships with validation default ON or OFF.

---

## 5. Proposed sequencing (planning only)

1. Run and archive backtest comparison.  
2. Shadow analytics / logging design review.  
3. Owner policy decision (default flag).  
4. Only then authorize any Phase 15 engineering sprint.

---

## 6. Freeze reminder

Phase 14 code and validators remain **frozen**.  
These recommendations are advisory until Owner authorizes Phase 15.
