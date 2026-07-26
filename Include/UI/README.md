# Include/UI

Phase 2 Sprint 8 — Enterprise Theme Engine, UI Customization & Personalization (**UI only**).

| File | Role |
|------|------|
| `CPersonalizationEngine.mqh` | Orchestrator |
| `CDashboardTheme.mqh` (Dashboard) | Theme palettes |
| `CProfileManager.mqh` | Saved UI profiles |
| `CLayoutManager.mqh` | Panel layout save/restore |
| `CAnimationEngine.mqh` | Optional lightweight animations |
| `CLocalization.mqh` | EN / UR / AR string resources |

**Hard rule:** Never opens/closes/modifies trades, risk, or strategy.
