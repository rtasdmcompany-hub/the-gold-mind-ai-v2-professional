# COMMERCIAL_READINESS.md

**Release Candidate:** RC-1  
**Build:** 21060 · Version string `2.0.0`  
**Review:** Commercial readiness (planning + scoring only)

---

## 1. Commercial Readiness Score: **74 / 100**

| Dimension | Score | Notes |
|-----------|------:|-------|
| Installation | 78 | Single EA attach; needs installer/docs packaging for non-dev users |
| Configuration | 80 | ECC catalogs exist; UX still developer-oriented |
| Documentation | 85 | Extensive Guides; needs customer-facing quickstart consolidation |
| Licensing | 72 | Identity/license engines present; Market vs Website license split not productized |
| Updates | 70 | Deployment/auto-update architecture; not a finished customer updater UX |
| Error handling | 78 | Logger + error manager; user-facing recovery messages vary |
| Logging | 88 | Strong module tags / closures |
| Support readiness | 65 | Needs support runbook + severity matrix for customers |
| Onboarding | 62 | No guided first-run wizard for retail buyers yet |
| Versioning | 90 | Build 21060 / sprint labels / freeze banners |
| Backup / Recovery | 75 | BDR platform architecture; encrypted package often ARCH |
| Security packaging | 70 | RBAC/encryption largely architecture-ready |

---

## 2. Edition separation plan (PLANNING ONLY — do not implement)

### Edition 1 — Website Professional Edition
| Item | Plan |
|------|------|
| Enabled | Full Core + Dashboard + AI advisory + Phase 7 research/BI + Cloud license check |
| Disabled / limited | Public SDK write APIs; internal FutureInterfaces; raw developer dumps |
| Licensing | RTAS website license server + device activation (Identity stack) |
| Distribution | Private download portal / installer bundle |
| Updates | Signed package via Deployment engine when hardened |
| Security | Device bind + online/offline grace |

### Edition 2 — MQL5 Market Edition
| Item | Plan |
|------|------|
| Enabled | Core trading + compact dashboard + essential risk/recovery |
| Disabled | Heavy Cloud admin, multi-account enterprise, API gateway developer hub, internal closures UI noise |
| Licensing | MQL5 Market license API |
| Distribution | MetaTrader Market product page |
| Updates | Market automatic update channel |
| Security | Market DRM + Magic isolation unchanged |

### Edition 3 — Internal Development Edition
| Item | Plan |
|------|------|
| Enabled | Everything + Phase closures + verbose logging + export dumps |
| Disabled | Nothing (or experimental flags on) |
| Licensing | Internal RTAS keys |
| Distribution | Private repo / build server |
| Updates | Continuous internal builds |
| Security | Dev certificates; never ship secrets |

---

## 3. RC-1 subsystem marks

| Subsystem | Mark | Notes |
|-----------|------|-------|
| Core Trading Engine | **PASS WITH NOTES** | Needs broker soak; strategy intact |
| Risk / Recovery | **PASS WITH NOTES** | Validate across brokers/symbols |
| Manual isolation | **PASS** | Magic 0 + foreign magic rejected |
| Dashboard | **PASS WITH NOTES** | Sprint remaps confuse continuity |
| AI Advisory | **PASS WITH NOTES** | Large surface; ensure advisory-only in all builds |
| Cloud / License | **PASS WITH NOTES** | Production license ops still maturing |
| Trade Journal / Labs | **PASS WITH NOTES** | Research quality vs real tick fidelity TBD |
| Portfolio / Reporting | **PASS WITH NOTES** | File DB; investor PDF still ARCH |
| Configuration | **PASS WITH NOTES** | Template lock OK; encrypted backup ARCH |
| AI Decision / MAC / EOC | **PASS WITH NOTES** | Monitoring catalogs; multi-terminal federation limited to local observe |
| Phase closures | **PASS** | Compile + freeze flags present |
| Market packaging | **FAIL** | No dedicated Market edition build matrix yet |
| Customer onboarding UX | **FAIL** | No first-run commercial wizard |
| Support playbooks | **FAIL** | Internal guides ≠ customer support kit |

### FAIL explanations (technical)

1. **Market packaging FAIL:** Single monolithic Professional EA includes enterprise surfaces not suitable for Market review constraints without a stripped build target and input/feature matrix.  
2. **Onboarding FAIL:** No guided attach checklist productized for non-technical buyers (symbol, magic, risk inputs, VPS guidance).  
3. **Support FAIL:** Missing severity taxonomy, SLA templates, and “safe restart” customer card separate from developer Operations Manual.

---

## 4. Before Phase 8 — commercial blockers (priority)

1. Define edition feature flags / build profiles (Website / Market / Internal).  
2. Customer Quick Start (≤5 pages) + video checklist.  
3. Clear News cast warnings (5).  
4. Broker compatibility matrix (demo → live).  
5. Support runbook + known-issues list.  
6. Decide Market vs Website license story.  
7. Stabilize dashboard information architecture (stop sprint-label churn for RC builds).  
8. Long-run stability soak (≥2 weeks) on target broker.

---

*End of COMMERCIAL_READINESS.md*
