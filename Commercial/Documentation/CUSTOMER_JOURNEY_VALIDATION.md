# CUSTOMER_JOURNEY_VALIDATION.md

**Phase:** 10 · Sprint 8  
**UI:** `/portal/admin/customer-journey`  

---

| Step | Outcome |
|------|---------|
| Landing Page | PASS |
| Account Registration | PARTIAL (invite-only Controlled Launch) |
| Email Verification | PARTIAL (provider-dependent) |
| License Purchase | PASS |
| Payment | PARTIAL (sandbox) / PASS when live PSP env set |
| License Activation | PASS |
| Download | PASS |
| Installation | PASS (Professional scripts) |
| First Login | PASS |
| Auto Update | PASS |
| Support Portal | PASS |
| Renewal | PASS |

Every step has a commercial path. Open public signup remains gated until Owner enables `PORTAL_OPEN_SIGNUP` after board gates clear.
