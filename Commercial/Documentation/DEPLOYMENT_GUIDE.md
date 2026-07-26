# DEPLOYMENT_GUIDE.md

**Phase 8 · Sprint 7**  
**Pipeline:** GitHub → Customer Distribution  
**Rule:** Website and Market packages from one Core tag; packaging differs

---

## 1. End-to-end deployment pipeline

```
GitHub
  ↓
Quality Validation          (QUALITY_GATES.md)
  ↓
Build Verification          (BUILD_PIPELINE.md)
  ↓
Package Generation          (MULTI_EDITION_BUILD_SYSTEM.md)
  ↓
Website Release             (Professional feed + portal)
  ↓
MQL5 Package                (Market-compliant upload path)
  ↓
Documentation               (release notes · guides · version bump docs)
  ↓
Customer Distribution       (download / Market publish live)
```

No stage may be skipped for Public Stable.

---

## 2. Stage responsibilities

| Stage | Owner | Exit criteria |
|-------|-------|---------------|
| GitHub | Engineering | Tagged commit; clean tree for release tag |
| Quality Validation | QA + Eng | Gate checklist evidence attached |
| Build Verification | CI / Release | 0 compile errors; artifacts + checksums |
| Package Generation | Release | Professional + Market + Internal (as needed) |
| Website Release | Release / Ops | Feed updated; portal download live; integrity OK |
| MQL5 Package | Publisher | Market rules satisfied; version aligned |
| Documentation | Product | Notes, known issues, upgrade policy visible |
| Customer Distribution | Ops | Announce; Support briefed |

---

## 3. Deployment safety

| Control | Spec |
|---------|------|
| Same Core tag | Both editions |
| Staged rollout (optional) | % of Professional updaters first |
| Kill switch | Pause Website update feed |
| Market | Follow MetaQuotes publish/review timing — no force |
| Rollback | Re-publish N-1 feed / prior package; Market per platform limits |

---

## 4. Post-deploy verification

- [ ] Version check returns new Stable  
- [ ] Checksum matches published  
- [ ] License validate still OK on canary seat  
- [ ] Health Summary healthy on canary install  
- [ ] Support KB updated  

---

## 5. Communication

| Audience | Message |
|----------|---------|
| Customers | Release notes · benefits · any action required |
| Support | Gate summary · known issues · diagnostics codes |
| Internal | Tag · artifact links · LTS impact |

Tone: calm, precise — no hype.

---

*End of DEPLOYMENT_GUIDE.md*
