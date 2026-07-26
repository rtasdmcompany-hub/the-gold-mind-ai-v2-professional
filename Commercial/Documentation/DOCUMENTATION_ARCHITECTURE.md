# DOCUMENTATION_ARCHITECTURE.md

**Phase 8 · Sprint 8**  
**Goal:** Single documentation center customers and Support can trust  
**Rule:** Docs describe product honestly — Architecture-Ready ≠ claimed shipped unless true

---

## 1. Documentation tree

```
Documentation Center
├── User Manual
├── Quick Start Guide
├── Installation Guide
├── Activation Guide
├── Dashboard Guide
├── Trading Guide
├── Reports Guide
├── FAQ
├── Release Notes
├── Version History
└── Developer Notes
```

Maps to existing Phase 8 commercial docs + future customer-facing HTML/PDF.

---

## 2. Document roles

| Doc | Audience | Purpose |
|-----|----------|---------|
| User Manual | All customers | End-to-end reference |
| Quick Start | New buyers | Fastest path to first safe session |
| Installation Guide | New buyers | Install without friction |
| Activation Guide | Licensed users | Activate + devices |
| Dashboard Guide | Operators | UI / widgets / health |
| Trading Guide | Traders | How product trades (Core truth) · risk disclosures |
| Reports Guide | Traders / investors | Journal · analytics · exports |
| FAQ | All | High-frequency answers |
| Release Notes | All | What changed per version |
| Version History | All | Chronology · LTS pins |
| Developer Notes | Internal / partners | Build · editions · freeze rules — not customer marketing |

---

## 3. Source of truth map (commercial)

| Topic | Canonical sprint docs |
|-------|----------------------|
| Install / Wizard | Sprint 2 onboarding |
| License / Portal | Sprint 3 |
| UI / Nav | Sprint 4 |
| Analytics / Journal | Sprint 5 |
| Security / Diagnostics | Sprint 6 |
| Updates / Editions | Sprint 7 |
| Support / Success | Sprint 8 (this) |

Customer manuals **summarize**; they do not contradict freeze rules.

---

## 4. Delivery formats

| Format | Use |
|--------|-----|
| In-portal / web | Primary |
| PDF | Offline / export |
| In-app Help links | Context-sensitive |
| Video | Tutorials (Support Center) |

---

## 5. Versioning

- Docs carry product version (`applies to 2.1.x`)  
- Breaking doc changes noted in Release Notes  
- Market Edition callouts where behavior/packaging differs  

---

*End of DOCUMENTATION_ARCHITECTURE.md*
