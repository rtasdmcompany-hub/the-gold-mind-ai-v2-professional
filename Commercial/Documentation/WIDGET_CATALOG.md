# WIDGET_CATALOG.md

**Phase 8 · Sprint 4**  
**Companion to:** `UI_COMPONENT_LIBRARY.md` · `DASHBOARD_LAYOUT.md`  
**Rule:** Modular · reusable · observe/display only

---

## Stable commercial widget set

| Widget ID | Title | Primary signal |
|-----------|-------|----------------|
| `acct_summary` | Account Summary | Login, server, currency |
| `daily_profit` | Daily Profit | Day P&L |
| `equity` | Equity | Equity value |
| `balance` | Balance | Balance value |
| `margin` | Margin | Margin / free margin |
| `risk` | Risk | Risk posture summary (display) |
| `win_rate` | Win Rate | Win % |
| `open_trades` | Open Trades | Count + link |
| `pending_orders` | Pending Orders | Count + link |
| `spread` | Spread | Current spread |
| `latency` | Latency | Ping / delay if available |
| `broker_status` | Broker Status | Connected / degraded |
| `market_session` | Market Session | Session label |
| `ai_health` | AI Health | Advisory subsystem health |
| `news_status` | News Status | Calendar/news feed health |
| `recovery_status` | Recovery Status | Recovery engine state (display) |
| `license_status` | License Status | Active / grace / expired |
| `cloud_status` | Cloud Status | Cloud connectivity |

---

## Composition rules

- Dashboard home: prioritize Account · Equity · Daily Profit · Margin · Open Trades · License  
- Secondary row: Spread · Session · AI Health · Broker  
- Advanced (Portfolio/AI pages): deeper widgets — not all on first viewport  

---

## Reuse

Same widget component with different `id` + data binding; shared loading/empty/error chrome.

---

*End of WIDGET_CATALOG.md*
