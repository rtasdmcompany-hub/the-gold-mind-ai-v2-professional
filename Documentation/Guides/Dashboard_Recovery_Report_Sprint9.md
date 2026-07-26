# Dashboard Recovery Report (Sprint 9)

**Build:** 21009 · **RC:** Dashboard-RC-1

## Recovery probes

| Event | Validation |
|-------|------------|
| MT5 restart | Panel X/Y GlobalVariables round-trip |
| EA reload | Settings clamp coherence |
| Broker / internet disconnect | UI remains valid (flags only) |
| Power failure / sleep-wake | GV persistence present |
| Theme / language | Survive reload clamp |

Settings, theme, profile, layout, language, refresh, transparency, and animation fields are covered by Settings + Recovery validators. Live broker disconnect still requires operator confirmation in a live session.
