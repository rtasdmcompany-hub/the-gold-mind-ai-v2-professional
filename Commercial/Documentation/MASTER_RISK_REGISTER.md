# MASTER_RISK_REGISTER.md

**Phase 8 · Sprint 10**  
**Owner:** Executive Board / Product Owner  
**Update cadence:** Each Phase 9 sprint gate  

---

## Risk register

| ID | Risk | Class | Impact | Likelihood | Recommended resolution | Target |
|----|------|-------|--------|------------|------------------------|--------|
| R01 | Public launch without legal pages | **Critical** | Regulatory / trust / chargebacks | High if rushed | Author & approve Privacy, Terms, Refund, Risk disclosure | Phase 9 early |
| R02 | Sell licenses without working payment→entitlement | **Critical** | Revenue failure / support storm | High if rushed | Implement Payment Port + License Service + email | Phase 9 |
| R03 | Market upload with external license/payment UI | **Critical** | Market rejection / ban risk | Medium | Market profile audit + string scan + compliance sign-off | Phase 9 |
| R04 | Accidental Core unfreeze / trade logic drift | **Critical** | Trust & accuracy | Low–Med | Enforce freeze + Quality Gate standing check | Continuous |
| R05 | Missing official brand assets | **High** | Unprofessional appearance | High now | Owner supplies logos/icons to `Commercial/Assets/` | Phase 9 |
| R06 | No sealed installer / checksum | **High** | Tamper / support burden | High | Signed package + SHA-256 + download page | Phase 9 |
| R07 | Portal not live while Website sells | **High** | Failed CX (devices, renew, download) | High | Deploy Customer Portal MVP | Phase 9 |
| R08 | Support unstaffed at launch | **High** | Churn / reputation | Medium | Staff L1 + SLA + KB top-20 before soft launch | Phase 9–10 |
| R09 | Widget / dashboard label churn returns | **Medium** | User confusion | Medium | Freeze commercial widget taxonomy in implementation | Phase 9 |
| R10 | Long-session memory/perf regressions | **Medium** | Stability perception | Medium | Soak tests + Performance budgets | Phase 9–10 |
| R11 | Update rollback untested | **Medium** | Bricked installs | Medium | RC exercise backup→update→rollback | Phase 9 |
| R12 | Over-claiming AI execution | **Medium** | Mis-sell / complaints | Medium | Copy review; Trading Guide truth | Continuous |
| R13 | Broker matrix incomplete | **Medium** | “Doesn’t work here” tickets | Medium | Publish compatibility notes; expand tests | Phase 9–10 |
| R14 | LTS channel never operated | **Low** | Enterprise deal friction | Low | Stand up LTS after first Stable | Phase 10–11 |
| R15 | Localization lag | **Low** | Geo expansion delay | Medium | EN-first; localize post soft launch | Phase 10+ |

---

## Risk posture summary

| Class | Count | Board stance |
|-------|------:|--------------|
| Critical | 4 | Must clear before paid public / Market publish |
| High | 4 | Must clear before broad marketing |
| Medium | 5 | Track in Phase 9–10 gates |
| Low | 2 | Plan; do not block Phase 9 start |

---

*End of MASTER_RISK_REGISTER.md*
