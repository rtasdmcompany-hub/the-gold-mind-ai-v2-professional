# BUILD_PIPELINE.md

**Phase 8 · Sprint 7**  
**Companion to:** `DEPLOYMENT_GUIDE.md` · `MULTI_EDITION_BUILD_SYSTEM.md`  
**Rule:** Pipeline design — Core frozen; no trade logic changes via CI

---

## 1. Pipeline stages (logical)

```
Source (GitHub)
  → Checkout tagged commit / channel branch
  → Dependency / include path prepare
  → Compile (MetaEditor / build agents) — target 0 errors
  → Static checks (lint/scripts as available)
  → Unit/smoke harness (non-trading where possible)
  → Edition packaging (Professional / Market / Internal)
  → Checksum / sign (when keys available)
  → Publish artifacts to channel bucket (not public until gates)
  → Attach build metadata (version, commit, edition, Core tag)
```

---

## 2. Build matrix

| Job | Profile | Output |
|-----|---------|--------|
| `build-internal-dev` | internal-dev | Internal package |
| `build-qa` | internal-qa | QA package |
| `build-prof-rc` | prof-rc | Professional RC |
| `build-market-rc` | market-rc | Market RC package |
| `build-prof-stable` | prof-stable | Website release candidate artifact |
| `build-market-stable` | market-stable | Market release artifact |

Stable jobs run **only** on approved tags after gate workflow.

---

## 3. Compile verification

| Check | Requirement |
|-------|-------------|
| EA compile | `TheGoldMindAI_Professional.mq5` (and Market entry if separate) → **0 errors** |
| Include path | Project root `/include` convention preserved |
| Warnings policy | Known accepted warnings documented; new warnings reviewed |

---

## 4. Artifact naming

```
TGM_{EDITION}_{VERSION}_{CHANNEL}_{COMMITSHORT}.zip
```

Example: `TGM_PROFESSIONAL_2.1.0_stable_a1b2c3d.zip`

Checksum file: `*.sha256`

---

## 5. Secrets & signing

| Secret | Use |
|--------|-----|
| Code sign cert | Professional packages |
| Update feed credentials | Publish Stable/RC feeds |
| Market publisher credentials | Human-operated or secured vault — Market upload |

Never store broker/customer credentials in CI.

---

## 6. Failure handling

- Failed compile → block promotion  
- Failed checksum → delete artifact · Security log  
- Partial matrix fail → no Public Stable  

---

*End of BUILD_PIPELINE.md*
