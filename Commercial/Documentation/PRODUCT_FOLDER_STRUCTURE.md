# PRODUCT_FOLDER_STRUCTURE.md

**Phase 8 · Sprint 1**  
**Root:** `Commercial/`

---

## Tree

```
Commercial/
├── README.md
├── Brand/
│   ├── Guidelines/          # Brand usage notes
│   └── Tokens/              # Color/type token references
├── Installer/
│   ├── Professional/        # Website installer recipe
│   └── Market/              # Market package recipe
├── Licensing/
│   ├── Professional/        # Website subscription / device activation model
│   └── Market/              # MQL5 Market activation model
├── Onboarding/
│   ├── WelcomeWizard/       # First-run content architecture
│   └── QuickStart/          # One-pager / short video scripts
├── Support/
│   ├── FAQ/
│   └── Runbooks/
├── MarketEdition/
│   ├── Package/             # Lightweight Market manifest
│   └── Compliance/          # MQL5 rules checklist
├── ProfessionalEdition/
│   ├── Package/             # Full Professional manifest
│   └── Features/            # Capability matrix detail
├── Website/
│   ├── Landing/
│   └── Pricing/
├── CustomerPortal/
│   ├── Activation/
│   ├── Subscriptions/
│   └── Updates/
├── Assets/
│   ├── Logos/               # Official logos only (no redesign)
│   ├── Icons/
│   ├── Splash/
│   ├── Storefront/
│   └── README.md
└── Documentation/           # Product definition docs (this set)
    ├── PRODUCT_EDITIONS.md
    ├── COMMERCIAL_ARCHITECTURE.md
    ├── BRAND_STANDARD.md
    ├── PRODUCT_FOLDER_STRUCTURE.md
    ├── EDITION_COMPARISON.md
    └── PHASE8_SPRINT1_REPORT.md
```

---

## Separation from engineering tree

| Tree | Owns |
|------|------|
| `Include/` `Experts/` | Frozen Core + enterprise observe platforms |
| `Commercial/` | Productization, editions, brand, journey, support |
| `Documentation/Guides/` | Historical phase / engineering guides |

Commercial work in Sprint 1+ must prefer `/Commercial` for product artifacts so engineering Core remains untouched.

---

*End of PRODUCT_FOLDER_STRUCTURE.md*
