# Known Limitations — Phase 1

| Limitation | Severity | Notes |
|------------|----------|-------|
| Backtest metrics empty until closed deals exist | Info | Expected on fresh accounts |
| AI modules are stubs / interfaces only | Info | Phase 2 scope |
| Hedge engine not implemented | Info | Phase 2+ |
| Cloud sync not implemented | Info | Phase 2+ |
| Dashboard UI not shipped | Info | Phase 2 Analytics |
| Live validation warnings on broker volume rounding | Minor | Step tolerance applied |
| `TERMINAL_MEMORY_AVAILABLE` may be 0 on some builds | Info | Treated as unknown/OK |
| Historical Gold “final backtest statistics” depend on terminal history | Info | Run on account with XAUUSD history loaded |
| Stress/stability probes are framework-level, not a substitute for multi-week live demo | Medium | Operator must run demo soak before live |

## Explicit Non-Limitations

- Magic Number isolation is enforced  
- Manual trades are not managed  
- Core strategy math is frozen
