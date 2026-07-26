# VERSIONING_POLICY.md

**Phase 8 · Sprint 7**  
**Scheme:** Semantic Versioning adapted for commercial + RC/LTS  
**Applies to:** Core tag · edition packages · docs

---

## 1. Version anatomy

```
MAJOR.MINOR.PATCH[-PRERELEASE][+BUILD]
```

| Segment | Meaning | Example bump |
|---------|---------|--------------|
| **MAJOR** | Breaking commercial/API/install contract or incompatible data formats | 2.0.0 → 3.0.0 |
| **MINOR** | Compatible commercial features / modules (non-Core) or additive APIs | 2.1.0 → 2.2.0 |
| **PATCH** | Bugfixes, hardening, docs-only product fixes | 2.1.0 → 2.1.1 |
| **Hotfix** | Urgent PATCH on Stable/LTS (security/stability) | 2.1.1 → 2.1.2 |
| **Release Candidate** | Prerelease identifier | 2.2.0-rc.1 |
| **Build** | CI metadata (optional) | 2.2.0+20260726.14 |

Core and edition packages share the same `MAJOR.MINOR.PATCH` for a Public Stable release.

---

## 2. Prerelease labels

| Label | Channel |
|-------|---------|
| (none) | Public Stable / LTS |
| `-rc.N` | Release Candidate |
| `-qa.N` | Internal QA (optional) |
| `-beta.N` | Beta (future) |
| `-dev` | Development only |

---

## 3. Upgrade policy

| From → To | Policy |
|-----------|--------|
| Patch/Hotfix on same MINOR | Always supported; auto-update eligible (Website) |
| MINOR upgrade | Supported; release notes required; config migrate if needed |
| MAJOR upgrade | Migration guide mandatory; may require re-activation / backup |
| RC → Stable | Same MAJOR.MINOR.PATCH when promoted |
| Stable → LTS pin | Customer opt-in; hotfixes only on LTS branch |

---

## 4. Backward compatibility

| Layer | Compatibility rule |
|-------|--------------------|
| Core Trading behavior | Frozen — no silent strategy changes in PATCH |
| Commercial config files | MINOR may add keys with defaults; MAJOR may require migrate |
| Journal / export schemas | Additive columns preferred; breaking = MAJOR |
| License leases | Server must accept N-1 client lease format during grace window |

---

## 5. Display strings

| Surface | Example |
|---------|---------|
| About / Footer | `THE GOLD MIND PROFESSIONAL 2.1.0` |
| Market product | Align visible version with Core tag |
| Logs | `2.1.0+build` |

---

## 6. Tagging

- Git tag: `v2.1.0` for Public Stable Core  
- RC: `v2.2.0-rc.1`  
- LTS: `v2.1.0-lts` branch + hotfix tags `v2.1.2-lts`  

---

*End of VERSIONING_POLICY.md*
