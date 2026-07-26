# ARCHITECTURE_REPORT.md

**Build:** 21060 · **Phases 1–7:** COMPLETE / FROZEN  
**Review type:** Enterprise architecture documentation (read-only)

---

## 1. Architectural principle

```
┌─────────────────────────────────────────────────────────────┐
│  GOLD MIND CORE  =  ONLY execution authority                │
│  (Calculation · Trading · Risk · Recovery · Session · H4)   │
└──────────────────────────▲──────────────────────────────────┘
                           │ observe / advise / report only
┌──────────────────────────┴──────────────────────────────────┐
│  ENTERPRISE LAYERS (Phases 2–7)                             │
│  Dashboard · AI · Cloud · Research · BI · Ops · Closures    │
└─────────────────────────────────────────────────────────────┘
```

Non-negotiable rules (ArchitectureFreeze):

1. Never change H4 fractions / SL / ATR TP / BE / Partial / Trail constants without explicit Core approval.  
2. Never manage Magic 0 / manual / foreign magics.  
3. New features = new modules calling APIs — do not fork frozen cores.  
4. AI / Cloud / Ecosystem never open/close/modify trades.

---

## 2. Subsystem map

### Core Engine (Phase 1 — FROZEN)
- **Calculation:** 3 Buy + 3 Sell levels from last closed H4 (`GM_LEVEL_FRAC_1/2/3`).  
- **Trading:** Pending placement, activation, closes, BE/Partial/Trail.  
- **Risk / Protection:** Lot / exposure / capital gates.  
- **Recovery:** Inventory restore, stale pending cleanup, second-attempt paths.  
- **Session:** H4 cycle orchestration (`CGmCycleEngine`, `CGmH4SessionEngine`).  
- **Ownership:** Magic gate — manual isolation.

### Dashboard (Phase 2 — FROZEN)
Read-only visualization of engine + AI snapshot. Widget manager remaps labels without changing Core.

### Analytics / Journal / Reports (Phase 2 foundation + Phase 7 ETJ/EPA/ERC)
Observe trade history → timelines, equity, investor/executive packages.

### Configuration (Phase 7 ECC)
Profiles / templates / workspace catalogs. Template apply blocked while AI trades open.

### Security / Licensing (Phase 6 Identity + ECC/MAC/EOC security layers)
License health, RBAC architecture, audit trails, tamper catalogs. Encryption largely **architecture-reserved**.

### Notification (Phase 6 ENC)
Alert queues / mobile companion API catalog — no trade authority.

### Portfolio (Phase 7 EPA)
Capital / risk / performance analytics — GM trades only.

### Backtesting / Optimization (Phase 7 ESL / EOL)
Research labs; pause heavy work when GM positions open; no auto-apply of live params.

### Trade Journal / Replay (Phase 7 ETJ)
GM magic+symbol journal; manual excluded.

### AI Decision (Phase 7 ADC + Phase 3–5 AI)
Advisory scores / recommendations; `may_auto_change_ai = false`.

### Cloud / Infrastructure (Phase 6)
Sync, remote health, VPS/multi-terminal, backup/DR, audit, API gateway, deployment — never executes.

### Administration / Command (Phase 7 EOC + MAC)
Monitor-only multi-account + ops room; `may_remote_command = false`.

---

## 3. Runtime interaction (`CApplication`)

1. **Init:** Core → validation → Cloud stack → Phase6 closure → Phase7 platforms → Phase7 closure.  
2. **OnTick:** Core trading / lifecycle path (critical).  
3. **OnTimer:** Enterprise `Process(false)` waterfall + last-wins dashboard publish.  
4. **Shutdown:** Reverse teardown of enterprise then Core helpers.

Data flows downward as **pointers / Last() snapshots** — never reverse-control into Core risk.

---

## 4. Dependency graph (simplified)

```
Core ←── Dashboard (read)
Core ←── AI (advisory)
Core ←── Cloud Identity (license observe)
ETJ → EPA → ERC
ESL → EOL
EPA/ETJ → ADC
EPA/ETJ/Identity → MAC
Cloud+MAC+ADC+EPA → EOC
All Phase7 → Phase7Closure
```

---

## 5. Extension points (for future phases — not implemented)

- New `Include/<Platform>/` + `Module.*.mqh`  
- Bind observe-only into `CApplication` timer path  
- Never edit frozen folders listed in ArchitectureFreeze  

---

*End of ARCHITECTURE_REPORT.md*
