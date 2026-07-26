# EXPORT_SYSTEM.md

**Phase 8 · Sprint 5**  
**Formats:** PDF · CSV · Excel · Print-friendly  
**Scope:** Templates and pipeline design only — no Core trade mutation

---

## 1. Export matrix

| Source | PDF | CSV | Excel | Print |
|--------|:---:|:---:|:-----:|:-----:|
| Trade Journal (filtered) | ✓ summary | ✓ | ✓ | ✓ |
| Daily / Weekly / Monthly / Yearly / Lifetime | ✓ | KPI CSV | ✓ | ✓ |
| Account / Recovery / Risk / Strategy packs | ✓ | optional | ✓ | ✓ |
| System Health snapshot | ✓ one-pager | ✓ | — | ✓ |

---

## 2. Pipeline (logical)

```
User selects report + filters + format
  → Report Builder assembles dataset (read-only)
  → Template Renderer (PDF / XLSX / CSV / HTML-print)
  → File to user download path / portal library
  → Audit: who exported what / when (commercial ops)
```

---

## 3. Templates (generate as specs)

### T-PDF-EXEC — Executive one-pager
- Brand header · period · 6 KPIs · mini equity · disclaimer  

### T-PDF-FULL — Full period report
- Matches Reporting System skeleton  

### T-CSV-JOURNAL — Flat journal
- Columns = Trade Journal schema  

### T-CSV-KPI — Period KPIs
- key, value, unit, as_of  

### T-XLSX-PACK — Multi-sheet
| Sheet | Content |
|-------|---------|
| Summary | KPIs |
| Trades | Journal rows |
| Equity | Time series points |
| Notes | Disclaimers / filters applied |

### T-PRINT — Print CSS / layout
- A4 / Letter  
- Black text on white; gold accents minimized for ink  
- Page numbers · “Confidential — account holder”  

---

## 4. Naming convention

```
TGM_{Edition}_{ReportType}_{AccountOrMask}_{YYYYMMDD}_{HHmm}.{ext}
```

Example: `TGM_PRO_Monthly_****1234_20260726_0105.pdf`

---

## 5. Quality gates

| Gate | Requirement |
|------|-------------|
| Completeness | Filters echoed on cover |
| Integrity | Row counts match journal filter |
| Privacy | Mask account number in shared PDFs option |
| Non-trading | Export never changes open positions |

---

## 6. Implementation note

Templates are **design artifacts** in this sprint. Rendering engines (lib / service) deferred.

---

*End of EXPORT_SYSTEM.md*
