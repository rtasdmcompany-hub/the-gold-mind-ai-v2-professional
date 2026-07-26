# COMMERCIAL_CERTIFICATION.md

**Phase:** 9 · Sprint 9 · RC-2

---

## Commercial layer certification

The commercial platform is certified as an **operational service layer** wrapping a frozen Core:

| Capability | Certified behavior |
|------------|-------------------|
| Licensing | Issue · activate · validate · devices · grace |
| Billing | Trial/Monthly/Yearly/Lifetime · invoices · webhooks |
| Portal | Customer + Admin surfaces |
| Installer/Updater | Verified packages · rollback |
| Cloud | Gateway · health · audit · cache |
| Support | Tickets · KB entry · admin console |

---

## Isolation certificate

| Rule | Status |
|------|--------|
| No commercial import of Trading Engine | **PASS** |
| Payment failure does not stop TE | **PASS** |
| Cloud outage does not stop TE | **PASS** |
| Admin cannot mutate Core via console | **PASS** |
| Website payments never required by Market edition | **PASS** |

---

## Shared Core

Website Professional and MQL5 Market share the same certified Core tag/hash.  
Edition differences are **commercial shells only**.

---

*End of COMMERCIAL_CERTIFICATION.md*
