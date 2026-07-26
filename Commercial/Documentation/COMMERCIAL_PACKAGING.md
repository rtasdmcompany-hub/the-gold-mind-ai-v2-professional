# COMMERCIAL_PACKAGING.md

**Phase 8 · Sprint 9**  
**Goal:** Consistent naming customers and stores can trust  
**Companion:** `VERSIONING_POLICY.md` · `MULTI_EDITION_BUILD_SYSTEM.md`

---

## 1. Professional Product Name

| Use | Name |
|-----|------|
| Legal / brand | THE GOLD MIND |
| Website edition | **THE GOLD MIND PROFESSIONAL** |
| Market edition | **THE GOLD MIND MARKET** |
| Internal | THE GOLD MIND INTERNAL (not public) |
| Owner line | RTAS Group of Companies · RTAS Digital Marketing Company |

Do not invent alternate spellings (GoldMind, Gold-Mind) in customer packaging.

---

## 2. Edition naming

| Code | Customer label |
|------|----------------|
| `GM_EDITION_PROFESSIONAL` | Professional |
| `GM_EDITION_MARKET` | Market |
| `GM_EDITION_INTERNAL` | Internal (hidden) |

---

## 3. Version naming

Follow SemVer: `MAJOR.MINOR.PATCH[-rc.N]`  
Display: `THE GOLD MIND PROFESSIONAL 2.1.0`  
Both public editions share Core version for a release train.

---

## 4. Package naming

```
TGM_{EDITION}_{VERSION}_{CHANNEL}.zip
```

Examples:

- `TGM_PROFESSIONAL_2.1.0_stable.zip`  
- `TGM_MARKET_2.1.0_stable.zip`  
- `TGM_PROFESSIONAL_2.2.0-rc.1_rc.zip`  

Companion: `TGM_...zip.sha256`

---

## 5. Installer naming

```
TGM_Professional_Setup_{VERSION}.exe
```

(or platform-appropriate sealed installer name — keep `TGM_Professional` prefix)

Market: no Website installer; Market product package only.

---

## 6. Release Notes format

```
# THE GOLD MIND {EDITION} {VERSION}
Date: YYYY-MM-DD
Channel: Public Stable | RC | LTS

## Highlights
- (≤5 customer-visible items)

## Improvements
## Fixes
## Known issues
## Upgrade notes
## Core note
Core Trading Engine: unchanged | Owner-approved change ref ___
```

---

## 7. Changelog format (engineering)

```
## [{VERSION}] - YYYY-MM-DD
### Added
### Changed
### Fixed
### Security
### Commercial
### Notes
```

Keep customer Release Notes shorter than engineering changelog.

---

*End of COMMERCIAL_PACKAGING.md*
