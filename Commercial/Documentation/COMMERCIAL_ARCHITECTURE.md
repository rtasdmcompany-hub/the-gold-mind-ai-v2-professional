# COMMERCIAL_ARCHITECTURE.md

**Phase 8 · Sprint 1**  
**Purpose:** Separate commercial product architecture from frozen trading Core  
**Status:** Architecture design — not feature implementation

---

## 1. Architecture principle

```
┌──────────────────────────────────────────────────────────────┐
│                 COMMERCIAL PRODUCT SHELL                     │
│  Brand · Onboarding · Licensing · Portal · Editions · Docs   │
│  (Phase 8+) — NEVER writes into live trading controls        │
└────────────────────────────┬─────────────────────────────────┘
                             │ observe / configure catalogs only
┌────────────────────────────▼─────────────────────────────────┐
│              ENTERPRISE OBSERVE LAYER (Phases 2–7)           │
│  Dashboard · AI · Cloud · Journal · BI · Ops (read-only)     │
└────────────────────────────┬─────────────────────────────────┘
                             │ observe only
┌────────────────────────────▼─────────────────────────────────┐
│         GOLD MIND CORE TRADING ENGINE (PERMANENTLY FROZEN)   │
│  Calculation · Execution · Risk · Recovery · Magic · H4      │
│  Sole authority to trade                                     │
└──────────────────────────────────────────────────────────────┘
```

---

## 2. Commercial domains (owned under `/Commercial`)

| Domain | Responsibility |
|--------|----------------|
| Brand | Identity tokens, guidelines, asset placement |
| Installer | Professional vs Market package recipes |
| Licensing | Website subscription vs Market activation models |
| Onboarding | Welcome Wizard content, Quick Start |
| Support | FAQ, runbooks, severity model |
| ProfessionalEdition | Website SKU definition & package manifest |
| MarketEdition | Market SKU definition & compliance checklist |
| Website | Landing / pricing content architecture |
| CustomerPortal | Activation, subscription, updates (Professional) |
| Assets | Official logos/icons/splash (no redesign) |
| Documentation | Commercial product definitions |

---

## 3. Edition packaging architecture

### Professional (Website)

```
Purchase (Website)
  → Download sealed Professional package
  → Installer guidance
  → License activate (Customer Portal / Identity)
  → Welcome Wizard
  → MT5 attach (Core frozen)
  → Subscription renew + auto-update
  → Enterprise Support
```

### Market (MQL5)

```
Purchase (MQL5 Market)
  → Market install
  → Simple Market activation
  → Lightweight first-run tips
  → MT5 attach (same frozen Core)
  → Market updates
```

---

## 4. Dependency policy

| Edition | Allowed dependencies |
|---------|----------------------|
| Professional | RTAS license/portal endpoints; cloud account services (non-trading) |
| Market | MetaTrader / MQL5 Market only — **no forbidden external deps** |

Commercial code/docs must never:

- Call trade open/close/modify APIs from portal/onboarding  
- Override Magic handling  
- Patch Risk / Recovery / Strategy  

---

## 5. Build profile concept (design only)

| Profile | Output |
|---------|--------|
| `PROFESSIONAL` | Full commercial shell + observe enterprise surfaces |
| `MARKET` | Lightweight shell + Core + compact UI |
| `INTERNAL` | Dev edition (not a public SKU in Sprint 1 docs) |

Implementation of compile flags is **out of Sprint 1** — definitions only.

---

## 6. Safety interface

Commercial architecture exposes only:

- Product identity strings  
- Edition capability matrix  
- Onboarding content  
- License *status* consumption (observe)  
- Support & docs  

Commercial architecture does **not** expose:

- Order send  
- SL/TP modify  
- Pending modify  
- Risk parameter mutation of live Core  

---

*End of COMMERCIAL_ARCHITECTURE.md*
