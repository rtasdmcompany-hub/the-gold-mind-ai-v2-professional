# TRADE_JOURNAL.md

**Phase 8 · Sprint 5**  
**Goal:** Professional journal that explains **what** happened and **why** (when reason is available)  
**Rule:** Journal is a transparency surface — not a second executor

---

## 1. Column schema

| Field | Description |
|-------|-------------|
| Trade ID | Stable deal/ticket identifier |
| Date | Close or open date (user preference; default close for history) |
| Time | HH:MM:SS (account/server TZ labeled) |
| Symbol | Instrument |
| Direction | Buy / Sell |
| Lot Size | Volume |
| Entry | Open price |
| Exit | Close price (blank if open) |
| SL | Stop loss at relevant snapshot |
| TP | Take profit at relevant snapshot |
| Profit | Closed P&L (commission/swap visible on detail) |
| Duration | Holding time |
| Reason | Human-readable open/close rationale from journal/advisory text |
| Strategy Version | Build / strategy profile version when recorded |
| Trade Status | Open · Closed · Partial · Cancelled (as applicable) |

---

## 2. Detail pane (row expand / drawer)

Beyond the grid:

- Commission · Swap · Net  
- Magic number / comment (advanced toggle)  
- Linked recovery context **if any** (display only)  
- Chart snapshot link / replay entry (when available)  
- “Why” narrative: Reason + any advisory note — calm language, no hype  

If Reason is unavailable: show “Reason not recorded” — never invent.

---

## 3. Search · Filter · Export

### Search
- Trade ID, Symbol, Reason text, Strategy Version  

### Filters
| Filter | Examples |
|--------|----------|
| Period | Today · Week · Month · Custom |
| Symbol | Multi-select |
| Direction | Buy / Sell |
| Status | Open / Closed |
| Outcome | Win / Loss / BE |
| Source | EA Magic · Manual (Magic 0) |
| Profit range | Min / Max |

### Export
- Current filtered set → CSV / Excel / PDF summary  
- See `EXPORT_SYSTEM.md`

---

## 4. UX rules

| Do | Don’t |
|----|-------|
| Sort by date default newest first | Infinite unsorted spam |
| Pin Status + Profit for scan | Hide P&L in menus |
| Show timezone once in header | Ambiguous local/server mix |
| Empty state with CTA | Blank white void |

---

## 5. Confidence outcomes

Journal exists so customers can answer:

1. Which trades are mine vs EA?  
2. Why was this trade opened/closed (when logged)?  
3. What does my recent sample look like?  

---

*End of TRADE_JOURNAL.md*
