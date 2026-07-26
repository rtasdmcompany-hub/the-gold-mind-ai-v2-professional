# PHASE9_IMPLEMENTATION_PLAN.md

**Phase:** 9 — Commercial Implementation & Launch Hardening  
**Sprint:** 1 — Implementation Framework & Governance  
**Authority:** `PHASE9_AUTHORIZATION.md` — APPROVED WITH CONDITIONS  
**Rule:** Core Trading Engine is a **certified subsystem** — wrap around it, never alter it

---

## 1. Mission

Implement the Phase 8 commercial blueprint while satisfying every Board Condition before any public launch claim.

No implementation may affect live trading behaviour.

---

## 2. Workstreams

| ID | Workstream | Priority | Depends on | Board Conditions served |
|----|------------|----------|------------|-------------------------|
| W1 | **Commercial** (shell, editions, packaging, naming) | P0 | Brand assets (partial) | B9, C13, packaging |
| W2 | **Licensing** (keys, activate, devices, leases) | P0 | W7 Security basics, W10 stubs | B6–B8 |
| W3 | **Customer Portal** MVP | P0 | W2, W7, Legal publish path | B8, A (links), E18 |
| W4 | **Installer** + checksum distribution | P0 | W1, Brand assets | B9, B10 |
| W5 | **Updates** (Website feed; Market = Market-only) | P1 | W4, W7 | C11, update safety |
| W6 | **Website** (pages, pricing, download, legal hosts) | P0 | Legal pack, W4 artifacts | A1–A5, B |
| W7 | **Security** (TLS, redaction, integrity, sessions) | P0 | — (foundation) | CISO conditions |
| W8 | **Support** (tickets intake, KB top-20, diagnostics help) | P1 | W3 (or email interim) | E17–E19 |
| W9 | **Documentation** (manuals, guides, release notes) | P1 | Content owners | E17, C11 docs gate |
| W10 | **Cloud Services** (license API, webhooks, update check) | P0 | W7 | B6–B7, B8 APIs |

**P0** = required before soft-launch path · **P1** = required before broad public launch

---

## 3. Dependency graph (simplified)

```
W7 Security ──┬──► W10 Cloud Services ──► W2 Licensing ──► W3 Portal
              │                              │
              └──► W1 Commercial ──► W4 Installer ──► W6 Website
                                              │
W9 Documentation ◄── parallel (content) ──────┤
W8 Support ◄── after Portal MVP or email bridge
W5 Updates ◄── after Installer + Cloud version API
MQL5 compliance track ◄── parallel late, after Core tag freeze (Condition D)
```

---

## 4. Isolation principle

| Layer | May change in Phase 9 | Must not change |
|-------|----------------------|-----------------|
| `/Commercial/**` | Yes | — |
| Website / Portal / Cloud | Yes | — |
| Dashboard chrome labels (commercial IA) | Yes, freeze taxonomy | Sprint remaps that imply Core change |
| Core Trading / Risk / Recovery / Execution / Magic / calculations | **Never** | Frozen |

Commercial modules communicate via **observe / advise / entitlement status** only.

---

## 5. Phase 9 success definition

- All Board Conditions = Verified  
- Quality Gates PASS on RC  
- Core Attestation signed for release tag  
- Soft-launch eligible (Owner GO) — not automatic  

---

## 6. Related Sprint 1 controls

| Doc | Role |
|-----|------|
| `IMPLEMENTATION_GOVERNANCE.md` | Task template & rules |
| `BOARD_CONDITIONS_TRACKER.md` | Mandatory gates |
| `IMPLEMENTATION_QUEUE.md` | Serial order |
| `REGRESSION_PROTECTION.md` | Pre-merge validation |

---

*End of PHASE9_IMPLEMENTATION_PLAN.md*
