# TRADING_ENGINE_REVIEW.md

**Scope:** Gold Mind Core Trading Engine — validation review only  
**Policy:** Do NOT modify strategy / calculations  
**Build:** 21060

---

## 1. Executive finding

**No strategy redesign required from this review.**  
Core remains architecturally isolated and frozen. Enterprise layers bind observe-only.  
Compile status: **0 errors**, **5 warnings** (News calendar casts — non-Core).

**Trading Engine Score recommendation: 88 / 100 (PASS WITH NOTES)**

---

## 2. Checklist validation

| Area | Evidence | Status |
|------|----------|--------|
| H4 calculation | `CLevelEngine` uses closed H4 high/low + `GM_LEVEL_FRAC_1/2/3` (0.20 / 0.58 / 0.92) | **PASS** |
| Signal / level generation | 3 Buy + 3 Sell tags; `GM_LEVEL_COUNT = 6` | **PASS** |
| Pending order logic | `CPendingOrderEngine` + ownership magic gate + lifecycle gate | **PASS** |
| ATR calculations | ATR-14 TP path referenced in Trade Manager / risk plan (frozen Core) | **PASS** |
| Stop Loss | Documented 30-pip SL policy in frozen Core / production docs | **PASS** |
| Take Profit | ATR-based TP via risk plan | **PASS** |
| Break-even | Trade Manager BE path | **PASS** |
| Trailing | Trail on residual runner after partial | **PASS** |
| Partial close | ~80% partial / ~20% runner model (documented lifecycle) | **PASS** |
| Recovery | `CCycleEngine` startup inventory, stale pending cleanup, no duplicate placement | **PASS** |
| Risk management | `CRiskEngine` / protection engines gate lots & plans | **PASS** |
| Manual trade isolation | Magic **0** rejected; `IsManualMagic` / `CanManageMagic` | **PASS** |
| Magic handling | Own-magic + symbol scoped counts | **PASS** |
| Session handling | `CGmH4SessionEngine` + cycle rollover | **PASS** |
| Broker compatibility | Broker validation hooks in pending/risk paths | **PASS WITH NOTES** |
| State management | Registry / level DB / trade IDs | **PASS** |
| Restart recovery | Startup cycle restores / places without waiting next H4 | **PASS** |

---

## 3. Logical conflict scan (architecture)

| Concern | Finding |
|---------|---------|
| Enterprise vs Core authority | Ecosystem `may_execute` / interrupt / remote flags forced **false** | OK |
| Template mutation during live trades | ECC locks template apply when GM positions > 0 | OK |
| Labs during live trades | ESL/EOL pause heavy work when GM trades active | OK |
| AI auto-apply | ADC `may_auto_change_ai = false`; EOL auto-apply disabled | OK |
| Dashboard last-wins | Timer publish overwrites widgets — informational only | OK (UX note) |

**No conflicting “second executor” found in Phase 7 platforms.**

---

## 4. Notes (not strategy changes)

1. **Broker variance:** Spread/slippage/fill quality differ by broker — needs live soak tests per broker profile before commercial claims.  
2. **News warnings:** `CCalendarNewsProvider` ulong/long/double casts — clean before Market listing polish.  
3. **Live soak evidence:** Certification engines score architecture + module readiness; long-run demo/live PnL validation remains an operational gate (not a code defect).  
4. **Dashboard remaps:** Widget labels rotate per sprint — operators must use Core logs for authoritative trade events.

---

## 5. Protect-the-Core statement

Commercial cloud, BI, multi-account, and command features **must remain observe-only**.  
Any Phase 8+ work that adds write-paths into pending/SL/TP/risk without explicit Core ownership review should be rejected.

---

*End of TRADING_ENGINE_REVIEW.md*
