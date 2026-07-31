# REAL MT5 VALIDATION REPORT — Phase 11D

**Product:** THE GOLD MIND AI v2.0 PROFESSIONAL  
**Generated:** 2026-07-30  
**Evidence class:** Real MT5 Strategy Tester (Every Tick / 100% real ticks)

## Environment

| Item | Value |
|------|-------|
| Terminal data | `D0E8209F77C8CF37AD8BF550E51FF075` |
| Broker | Exness-MT5Trial16 |
| Account | 262523237 |
| Expert | `TheGoldMindAI_Professional` |
| Compiled EX5 size | 234428 bytes |
| EX5 SHA256 | `099838E4119B5267BC5728ED13825C5C7B181D9ECE26BB4FDD4B3700794F3FCF` |
| Symbol | XAUUSDm |
| Period | H4 |
| Range | 2026.06.02 – 2026.06.20 |
| Model | Every tick based on real ticks |
| History Quality | **100% real ticks** |
| Bars / Ticks | 85 / **4,825,624** (identical both runs) |

## Runs Executed

| Case | Input | Report | Exit |
|------|-------|--------|------|
| AI ON | `P11B_Enable_Supervisor=true` | `evidence/Phase11D_AI_ON.htm` | 0 |
| AI OFF | `P11B_Enable_Supervisor=false` | `evidence/Phase11D_AI_OFF.htm` | 0 |

Automation: `Scripts/Phase11D/run-mt5-tester.ps1 -Mode BOTH` via `terminal64.exe /config`.

## Summary Results

| Metric | AI ON | AI OFF |
|--------|-------|--------|
| Total Net Profit | -2,918.19 | -3,370.02 |
| Profit Factor | 0.92 | 0.90 |
| Total Trades | **269** | **269** |
| Short / Long | 119 / 150 | 119 / 150 |
| Profit / Loss trades | 141 / 128 | 141 / 128 |
| Total Deals | 468 | 468 |

## Integrity Checks (real HTML parse)

| Check | Result |
|-------|--------|
| Deal direction identical | **468/468** |
| Deal price identical | **468/468** |
| Deal volume different (lot policy) | **464/468** |
| Pending open/time/type/price/SL/TP/comment identical | **610/610** |
| Pending volume different | **610/610** |

## Artifacts

- `evidence/Phase11D_AI_ON.htm`
- `evidence/Phase11D_AI_OFF.htm`
- `evidence/tester_AI_ON.log`
- `evidence/tester_AI_OFF.log`
- `evidence/GM_P11B_EXEC_LEARN.csv`
- `evidence/phase11d-comparison.json`
- `evidence/tester-run-results.json`
- `evidence/phase11d-compile.log`

## Decision Input

Real Every-Tick Strategy Tester evidence collected successfully for both AI ON and AI OFF.
