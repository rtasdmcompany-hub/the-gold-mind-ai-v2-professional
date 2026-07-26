# REGRESSION_REPORT.md

**Phase:** 9 · Sprint 8 · RC-2  
**Method:** Static isolation scan · compile · harness · edition policy review

---

## Trading Engine / Core

| Check | Result |
|-------|--------|
| Trading Engine unchanged | **PASS** — SHA-256 certified |
| Core calculations unchanged | **PASS** — no commercial code path into Core |
| No regression into Include/Experts | **PASS** — portal has zero `.mqh` imports |

---

## Commercial regression surfaces

| Area | Result | Notes |
|------|--------|-------|
| UI regression | **PASS WITH NOTES** | Admin/portal pages compile; visual e2e browser suite not automated |
| Portal regression | **PASS** | Routes present · layout auth gate |
| API regression | **PASS** | 21 route handlers · gateway-wrapped key paths |
| Installer regression | **PASS** | Scripts present · checksum/rollback paths intact |
| Authentication regression | **PASS** | NextAuth JWT · RBAC · brute-force · idle timeout |

---

## Isolation regression

Grep of `Commercial/CustomerPortal/web/src` for Trading Engine / `.mqh` / `Include/` imports: **no coupling**.  
MetaTrader strings appear only as user-facing install guidance.

Market Edition folder has **no** CustomerPortal / Paddle / PayPal references — edition isolation held.

---

*End of REGRESSION_REPORT.md*
