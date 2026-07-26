# RELEASE_CHECKLIST.md

**Phase 8 · Sprint 9**  
**Includes:** Final Readiness Matrix (Task 8) · pre-public release actions  
**Statuses:** NOT STARTED · IN PROGRESS · READY · BLOCKED  

---

## 1. Final Readiness Matrix

| Category | Item | Status | Notes |
|----------|------|--------|-------|
| **Architecture** | Commercial `/Commercial` tree & edition split | READY | Sprints 1–7 design |
| **Architecture** | Shared Core · multi-edition profiles | READY | Sprint 7 |
| **Trading Engine** | Core frozen · sole execution authority | READY | Permanent freeze |
| **Trading Engine** | Magic 0 isolation policy documented | READY | Existing architecture |
| **UI/UX** | Design system · nav · widgets taxonomy | READY | Sprint 4 (design) |
| **UI/UX** | Pixel implementation of commercial IA | IN PROGRESS | Not fully shipped as designed |
| **Installer** | Professional installer flow designed | READY | Sprint 2 |
| **Installer** | Sealed signed installer + checksum live | NOT STARTED | Blocks Website launch |
| **Licensing** | License types · portal · devices designed | READY | Sprint 3 |
| **Licensing** | Live activation + payment webhooks | NOT STARTED | BLOCKED for paid public |
| **Customer Portal** | IA complete | READY | Sprint 3 |
| **Customer Portal** | Production portal deployed | NOT STARTED | BLOCKED for full Website CX |
| **Security** | Security architecture + hardening design | READY | Sprints 3/6 |
| **Security** | Prod TLS · signing · redaction implemented | IN PROGRESS | |
| **Documentation** | Phase 8 commercial doc set | READY | Sprints 1–9 |
| **Documentation** | Customer User Manual authored | IN PROGRESS | Architecture READY |
| **Support** | Support ops · KB · templates designed | READY | Sprint 8 |
| **Support** | Helpdesk staffed + SLA live | NOT STARTED | Soft-launch risk |
| **Website Edition** | Pages/legal IA | READY | This sprint |
| **Website Edition** | Legal content + live storefront | NOT STARTED | **BLOCKED** |
| **MQL5 Edition** | Compliance design + checklist | READY | Sprint 1/9 |
| **MQL5 Edition** | Market package audit + screenshots | IN PROGRESS | Launch not READY |
| **Commercial Packaging** | Naming · notes · changelog formats | READY | This sprint |
| **Commercial Packaging** | Stable artifacts published | NOT STARTED | |
| **Launch Assets** | Usage guide | READY | This sprint |
| **Launch Assets** | Official logo/icon binaries in Assets | NOT STARTED / BLOCKED if missing | Owner supply |

---

## 2. Pre-public release actions

### Both editions
- [ ] Quality Gates 1–10 PASS (Sprint 7)  
- [ ] Same Core tag for Professional + Market  
- [ ] Risk disclosure on all sales surfaces  
- [ ] Support path published  
- [ ] Release notes published  

### Website Professional
- [ ] Legal pack approved  
- [ ] Pricing live  
- [ ] Payment → license email verified  
- [ ] Download + checksum  
- [ ] Activation + wizard smoke  
- [ ] Update feed (or manual download policy stated)  

### MQL5 Market
- [ ] Compliance string scan  
- [ ] Screenshots from Market build  
- [ ] Description approved  
- [ ] Market upload package frozen  

---

## 3. Global readiness summary

| Lens | Assessment |
|------|------------|
| Design / architecture | Strong — Phase 8 nearly complete |
| Implementation / live ops | Incomplete — legal, portal, payments, assets block full public GO |
| Trading Core | Ready & frozen — not the launch blocker |
| Recommendation | **Conditional soft-launch only after BLOCKED rows clear**; full international GO deferred |

---

## 4. Global Readiness Review (Task 6)

| Criterion | Score posture |
|-----------|---------------|
| Professional Appearance | High if assets + UI IA applied |
| Commercial Value | High architecture; value proof needs live CX |
| Ease of Purchase | Designed; not live |
| Ease of Installation | Designed; installer not sealed |
| Ease of Activation | Designed; license services not live |
| Ease of Learning | Docs/KB architecture strong; content partial |
| Ease of Support | Ops model strong; staffing pending |
| Customer Confidence | Transparency design strong (Sprint 5) |
| Brand Consistency | Tokens locked; binaries pending |
| Enterprise Quality | Process (gates/release) enterprise-grade on paper |

---

*End of RELEASE_CHECKLIST.md*
