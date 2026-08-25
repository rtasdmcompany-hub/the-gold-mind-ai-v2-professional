# CHANGELOG.md

## 2.2.0 — Build 421 method update (2026-08-25)

- Core Build **421** / property version **2.136**
- Shared SL: last grid level +/- 50 pip on all 3 levels (BUY = buy3−50, SELL = sell3+50)
- Profit booking: +30 pip → **80% close + break-even**; **20% runner** stays to ATR TP
- Lot sizing: **3% of account EQUITY** (distance = |entry → shared SL| per level)
- Excel entry geometry: BUY = High−Diff×m, SELL = Low+Diff×m
- Phase11E AI Dynamic Execution Engine removed (no lot reduce / AI panel)
- Hedge system remains OFF; H4 range lock OFF
- Same Core as Website Professional commercial release **1.2.0**

## 2.1.0 — Build 417 method update (2026-08-25)

- Core Build **417** / property version **2.132**
- Shared SL: last grid level +/- 50 pip on all 3 levels
- Profit booking: +30 pip FULL close (no partial / float runner)
- Lot sizing: 2% of account **BALANCE** (stops equity feedback loop)
- H4 range lock removed — every H4 places 3 BUY + 3 SELL
- Hedge system remains OFF
- Daily profit lock force OFF
- Same Core SHA as Website Professional commercial release **1.1.0**

## 2.0.0 — Market RC packaging (2026-07-26)

- Market listing pack prepared (description, features, guides, disclaimer)
- Store brand assets (icon, logo, banner, cover)
- Package MANIFEST bound to prior certified Core SHA
- Website PaymentPort / portal explicitly excluded from Market package
- Core Trading Engine: **unchanged** at that tag
