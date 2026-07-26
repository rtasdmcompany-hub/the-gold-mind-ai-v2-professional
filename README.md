# THE GOLD MIND AI PROFESSIONAL

**Proprietary enterprise trading system**  
**Owner:** RTAS Group of Companies  
**Division:** RTAS Digital Marketing Company  
**Development:** RTAS Softwear

| Field | Value |
|-------|-------|
| Product | THE GOLD MIND AI PROFESSIONAL |
| Version | 2.0.0 (build 1002) |
| Sprint | Phase 1 / Sprint 1 |
| Scope | Foundation + ownership / recovery contracts — **no strategy execution yet** |

---

## Non-Negotiable Rules

1. Manage **only** trades created by this EA  
2. **Never** touch manual trades  
3. **Never** manage other EA trades  
4. **Magic Number** is the sole ownership key  

See [Trading Rules](Documentation/Architecture/TradingRules.md) and [Engine Separation](Documentation/Architecture/EngineSeparation.md).

---

## Quick Start

1. Keep `Experts/` and `Include/` as siblings.
2. Compile `Experts/TheGoldMindAI_Professional.mq5` (F7).
3. Attach to chart — startup logs ownership rules + recovery scan. No orders in Sprint 1.

---

## Documentation Index

| Document | Purpose |
|----------|---------|
| [Architecture Overview](Documentation/Architecture/Overview.md) | System design |
| [Trading Rules](Documentation/Architecture/TradingRules.md) | Rules #1–#4, startup, recovery |
| [Engine Separation](Documentation/Architecture/EngineSeparation.md) | Strategy / Trade / Risk / Recovery / AI / Analytics |
| [Folder Structure](Documentation/Architecture/FolderStructure.md) | Directories |
| [Module Catalog](Documentation/Modules/ModuleCatalog.md) | Modules |
| [Class Catalog](Documentation/Classes/ClassCatalog.md) | Classes |
| [Sprint 1 Report](Documentation/Guides/Sprint1_Report.md) | Validation |

---

*Await Sprint 2 approval before implementing strategy / order execution.*
