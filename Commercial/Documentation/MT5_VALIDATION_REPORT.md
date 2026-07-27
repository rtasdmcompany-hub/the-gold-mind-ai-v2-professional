# MT5_VALIDATION_REPORT.md

**Product:** THE GOLD MIND AI v2.0 PROFESSIONAL  
**Date:** 2026-07-27  
**Validation:** `npm run mql5:sprint7` (read-only)  
**Core SHA:** `75002e46e3c200292c3696b2767bba20f2dd4200c74078555f84bc1f54a033ce`

---

## Frozen components (NOT modified)

- `Experts/TheGoldMindAI_Professional.mq5` — source frozen
- Trading Engine, algorithms, risk engine, MT5 logic
- Packaged EX5 binary SHA: `7883b4155aabb088e07f9f9563b413b7b63de7188d610021fb4fdca603e8c619`

---

## Automated validation results

```json
{
  "mql5Readiness": 92,
  "commercialPackaging": 85,
  "documentation": 100,
  "compliance": 91,
  "releaseReadiness": 91,
  "customerReadiness": 92,
  "storeSubmissionReadiness": "READY_WITH_CONDITIONS",
  "coreMatchesCert": true
}
```

---

## Workflow verification (read-only)

| Step | Status | Evidence |
|------|--------|----------|
| MT5 detection script | **PASS** | `Deploy-EA-To-MT5.ps1 -ListOnly` in installer payload |
| Expert installation | **PASS** (static) | EA slot in payload + portal `/portal/devices` |
| License activation | **PASS** (static) | `Activate-License.ps1` + portal license API |
| Device registration | **PASS** | Portal devices page operational (recovery verified) |
| Trading Engine startup | **FROZEN** | Not modified — certified binary only |
| Signal pipeline | **FROZEN** | Core logic untouched |
| Trade communication | **FROZEN** | Core logic untouched |
| Recovery / logging | **FROZEN** | Core logic untouched |

---

## Portal MT5 integration

| Portal route | Status |
|--------------|--------|
| `/portal/devices` | **PASS** (200, recovery verified) |
| License create API | **PASS** (200 with Origin header) |
| Downloads page | **PASS** |
| EA deployment docs | **PASS** (`/docs`) |

---

## Remaining conditions (Owner / QA)

1. Live MT5 screenshots for marketing and MQL5 Market listing
2. Owner/QA Strategy Tester evidence on demo account
3. MetaQuotes rules re-read at upload time
4. Legal counsel sign-off if Market description cites website policies

---

## Verdict

**MT5 integration: PASS (read-only validation)** — Core SHA matches certification, installer scripts present, portal device/licensing workflows operational. Live MT5 terminal testing requires Owner environment with MetaTrader 5 installed.
