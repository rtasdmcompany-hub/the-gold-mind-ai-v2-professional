# MULTI_EDITION_BUILD_SYSTEM.md

**Phase 8 · Sprint 7**  
**Editions:** Professional (Website) · Market (MQL5) · Internal Development  
**Invariant:** One shared Core Trading Engine for all editions

---

## 1. Edition definitions

| Edition | Code | Distribution | Audience |
|---------|------|--------------|----------|
| THE GOLD MIND PROFESSIONAL | `GM_EDITION_PROFESSIONAL` | Official Website | Premium customers |
| THE GOLD MIND MARKET | `GM_EDITION_MARKET` | MQL5 Market | Market customers |
| Internal Development | `GM_EDITION_INTERNAL` | Private | Eng / QA / diagnostics |

See also: `PRODUCT_EDITIONS.md` (Sprint 1).

---

## 2. Shared modules (all editions)

| Layer | Content |
|-------|---------|
| Core Trading Engine | Frozen — sole execution authority |
| Gold Mind strategy math | Shared |
| Risk / Recovery / Order execution | Shared |
| AI Decision Logic | Shared (observe/advise boundaries unchanged) |
| Common utilities / logging primitives | Shared |
| Version identity of Core | Single SemVer Core tag per release |

**Rule:** Edition packaging never forks Core source into divergent trade behavior.

---

## 3. Edition-specific modules

| Area | Professional | Market | Internal |
|------|--------------|--------|----------|
| Website license / portal hooks | Yes | No (Market rules) | Optional stubs |
| Customer Portal deep links | Yes | Limited / none | Dev tools |
| Auto-update (Website) | Yes | Via MQL5 Market only | Dev channels |
| Welcome Wizard full | Yes | Simplified / compliant | Full + debug pages |
| Diagnostics pack export | Yes | Allowed if Market-compliant | Verbose |
| Enterprise analytics UI | Full | Reduced surface | Full + probes |
| Feature flags admin | Portal-backed | Compile-time / Market-safe | Force-on diagnostics |

---

## 4. Build profiles

| Profile | Defines |
|---------|---------|
| `prof-stable` | Professional · Public Stable · release flags |
| `prof-rc` | Professional · RC · diagnostics richer |
| `market-stable` | Market · Public Stable · MQL5-legal surface |
| `market-rc` | Market · RC |
| `internal-qa` | Internal · QA · max diagnostics |
| `internal-dev` | Internal · Development · TRACE allowed |

Profiles select: edition macros, included commercial folders, signing, log default level, updater endpoint.

---

## 5. Feature flags

| Flag type | Use |
|-----------|-----|
| Compile-time | Edition hard exclusions (e.g. no external license server in Market) |
| Runtime (Professional) | Entitlement-gated commercial UI |
| Kill switch (ops) | Disable non-Core commercial feature remotely (Professional) |

Flags must **never** alter Core lot/SL/TP/recovery algorithms.

---

## 6. Packaging rules

| Edition | Package contents |
|---------|------------------|
| Professional | Installer/sealed zip · EA · Include (as licensed) · commercial docs · checksum · license readme |
| Market | MQL5 Market–compliant product package only — no illegal externals |
| Internal | + diagnostics tools · gate scripts · unsigned OK |

Both customer editions from the **same Core git tag**.

---

## 7. Synchronization contract

```
Single Core tag (e.g. core-2.1.0)
    ├── package Professional 2.1.0 (commercial shell N)
    └── package Market 2.1.0 (Market shell M)
```

Commercial shell version may carry edition suffix in filename; **Core version string remains aligned**.

---

*End of MULTI_EDITION_BUILD_SYSTEM.md*
