# Dashboard Stress Test Report (Sprint 9)

**Build:** 21009 · **RC:** Dashboard-RC-1

## Scenarios exercised (READ-ONLY collect loops)

| Scenario | Probe |
|----------|-------|
| Rapid tick updates | 50× `Collect` loops |
| High volatility fields | Symbol / spread / ATR present |
| Multiple open / pending | Counter integrity |
| H4 session presence | Session / countdown fields |
| Large trade history counters | Total / today closed |
| Multi-instance fields | Instance id / chart / running count |
| Chart object budget | ObjectsTotal < 5000 |
| Memory sample | Terminal memory > 0 |
| Long-runtime harness | 12/24/48/72h trackers armed |

Live multi-day soak is operator-executed; the EA logs milestones when uptime reaches each threshold.
