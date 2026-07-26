# UPDATE_ARCHITECTURE.md

**Phase 8 · Sprint 7**  
**Design only — do not implement in this sprint**  
**Editions:** Website (Professional) · MQL5 Market  

---

## 1. Website Edition — update workflow

```
Version Check
  → Release Notes (user visible)
  → Safe Download (TLS)
  → Integrity Verification (checksum / signature)
  → Backup (commercial state — Sprint 6)
  → Apply package
  → Restart (terminal / shell guidance)
  → Health check
  → On failure: Rollback to N-1
```

### Stage detail

| Stage | Spec |
|-------|------|
| Version Check | Client polls update service with edition + current version + license state |
| Release Notes | Short customer language; link to full notes |
| Safe Download | HTTPS; resume optional; temp folder |
| Integrity Verification | SHA-256 (+ code sign when available); abort if mismatch |
| Backup | Automatic commercial backup before replace |
| Apply | Atomic swap where possible |
| Restart | Clear user prompt — never silent mid-trade UX chaos |
| Rollback | Restore N-1 package + prior backup; Diagnostics banner |

### Safety rules

- No forced update during known critical trading moments without user confirm (policy)  
- Patch/Hotfix may be recommended strongly; MAJOR always confirm  
- Update never modifies Core strategy math beyond the shipped Core tag contents  
- Failed verify → do not apply  

---

## 2. MQL5 Market Edition — update process (document only)

| Topic | Spec |
|-------|------|
| Distribution | Updates delivered through **MQL5 Market** mechanisms only |
| Compliance | No parallel illegal auto-updater that violates Market rules |
| Version sync | Market product version aligns with shared Core tag for that release |
| Release notes | Published via Market product update description |
| Rollback | Per MetaQuotes / Market platform behavior; document customer guidance in Support KB |
| License | Market licensing model — not Website portal lease |

**Do not implement** a Website-style updater inside Edition B.

---

## 3. Channel mapping

| Update feed | Serves |
|-------------|--------|
| Stable feed | Public Stable |
| RC feed (opt-in) | RC testers |
| LTS feed | LTS subscribers |
| Beta feed (future) | Beta opt-in |

---

## 4. Failure UX

Align with Error Handling + Notifications:

- `UPD_CHECK_FAIL` → Warning  
- `UPD_INTEGRITY_FAIL` → Critical · no apply  
- `UPD_ROLLBACK_OK` → Success + INFO log  

---

*End of UPDATE_ARCHITECTURE.md*
