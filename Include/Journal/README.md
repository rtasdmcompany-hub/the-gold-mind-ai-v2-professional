# THE GOLD MIND AI — Journal Module

Phase 2 Sprint 5 — Enterprise Alert Center, Trade/Level/Session Journals (READ-ONLY).

| File | Role |
|------|------|
| `CJournalEngine.mqh` | Orchestrator |
| `CAlertCenter.mqh` | Categorized alerts |
| `CTradeJournal.mqh` | Live trade journal |
| `CLevelJournal.mqh` | Level journal |
| `CSessionJournal.mqh` | H4 session journal |
| `CJournalSearch.mqh` | Search & filter |
| `SGmJournalReportStats.mqh` | Dashboard report widgets |

**Contract:** Never opens/closes/modifies trades, SL/TP, or risk.
