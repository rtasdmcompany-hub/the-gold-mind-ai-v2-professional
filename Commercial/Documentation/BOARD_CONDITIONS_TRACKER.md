# BOARD_CONDITIONS_TRACKER.md

**Phase:** 9 · Sprint 1  
**Source:** `PHASE9_AUTHORIZATION.md` Conditions A–E  
**Statuses:** NOT STARTED · IN PROGRESS · BLOCKED · VERIFIED  
**Rule:** Public launch GO requires **all** applicable rows = VERIFIED (or Owner waiver written)

---

## Gate summary

| Gate ID | Board Condition | Owner (role) | Status | Dependencies | Verification Method |
|---------|-----------------|--------------|--------|--------------|---------------------|
| BC-LEGAL | **Legal Pack** (Privacy, Terms/EULA, Refund, Risk disclosure, Cookie if needed) | Owner + Legal / Commercial | **VERIFIED** | Owner attestation 2026-07-26 | Live URLs + Owner checklist (`OWNER_PRODUCTION_READINESS_ATTESTATION.md`) |
| BC-PAYLIC | **Payment → License Flow** (provider + generate + email + activate + device) | Engineering + Commercial | **VERIFIED** | Owner: Payment Gateway Live | Owner attestation · live PSP |
| BC-PORTAL | **Customer Portal MVP** (licenses, downloads, devices, ticket entry) | Engineering + Product | **VERIFIED** | BC-PAYLIC | Sprint 8+ · Owner production healthy |
| BC-INSTALL | **Installer + Checksum** (sealed package on Download page) | Release + Engineering | **VERIFIED** | Brand + Authenticode | Owner: Authenticode Signed Installer · SHA packages |
| BC-BRAND | **Brand Assets** in `Commercial/Assets/` | Owner / Brand | **VERIFIED** | Owner supply | Owner: Logo · Favicon · Icons final |
| BC-CORE | **Core Trading Engine Attestation** | CTO / Owner | **VERIFIED** | SHA certification | Owner SHA-256 Verified · hash MATCH certified |
| BC-QGATES | **Quality Gates** 1–10 PASS on RC | QA + Release Manager | **VERIFIED** | Ops green | Monitoring · Backup · Rollback Owner-verified |
| BC-MQL5 | **MQL5 Compliance** (audit, screenshots, same Core tag) | Commercial + Compliance | IN PROGRESS (NEAR VERIFIED) | Market build from Core tag | Listing pack ready · **live screenshots still pending** |
| BC-SUPPORT | **Support Minimum** (Top-20 KB, ticket intake, diagnostics instructions) | Support Lead + Product | **VERIFIED** | Portal + email | Owner: Support Email Working · Email Templates · KB≥20 |

---

## Condition mapping (authorization numbers)

| Gate | Auth items |
|------|------------|
| BC-LEGAL | 1–5 |
| BC-PAYLIC | 6–7 |
| BC-PORTAL | 8 |
| BC-INSTALL | 9 |
| BC-BRAND | 10 |
| BC-QGATES | 11, 13 (widget freeze as gate note) |
| BC-CORE | 12 |
| BC-MQL5 | 14–16 (if Market in launch window) |
| BC-SUPPORT | 17–19 |

---

## Tracking log

| Date | Gate | Change | By |
|------|------|--------|-----|
| 2026-07-26 | ALL | Tracker created — Phase 9 Sprint 1 | Phase 9 governance |
| 2026-07-26 | BC-PORTAL | IN PROGRESS — Next.js MVP (auth, 12 sections, read-only mocks) | Phase 9 Sprint 2 |
| 2026-07-26 | BC-PAYLIC / BC-PORTAL | License engine + devices + subscriptions wired; payment still open | Phase 9 Sprint 3 |
| 2026-07-26 | BC-PAYLIC | Billing Port + webhooks + emails + portal billing (sandbox) | Phase 9 Sprint 4 |
| 2026-07-26 | BC-PAYLIC | Webhook public route + audit log + PaymentPort checkout + expiry emails | Phase 9 Sprint 4 harden |
| 2026-07-26 | BC-INSTALL | Installer/updater scripts + release portal/admin | Phase 9 Sprint 5 |
| 2026-07-26 | BC-INSTALL | Verified ZIP artifacts · updater telemetry · channel manifests · matrix | Phase 9 Sprint 5 harden |
| 2026-07-26 | BC-PORTAL / BC-PAYLIC | Enterprise cloud gateway · audit · health · RBAC · Upstash-ready cache | Phase 9 Sprint 6 |
| 2026-07-26 | BC-PORTAL / BC-SUPPORT | Enterprise Admin Console · BI · audit center · support console · 6-role matrix | Phase 9 Sprint 7 |
| 2026-07-26 | BC-QGATES / BC-CORE | RC-2 validation · Core SHA-256 certification · tsc PASS · harness 16/16 | Phase 9 Sprint 8 |
| 2026-07-26 | BC-QGATES / BC-CORE | RC-2 executive certification · FINAL_QUALITY_GATE PASS · READY FOR RC-2 | Phase 9 Sprint 9 |
| 2026-07-26 | ALL | Sprint 10 Final Executive Review · Phase 9 COMPLETE · decision APPROVED WITH CONDITIONS · Phase 10 await Owner | Phase 9 Sprint 10 |
| 2026-07-26 | — | Phase 10 Sprint 1 started — Controlled Launch foundation (beta/monitoring/incidents/feedback/dashboard); public Stable still blocked | Phase 10 Sprint 1 |
| 2026-07-26 | — | Phase 10 Sprint 2 — Invite-only beta enrollment/metrics/issues/structured feedback; feature freeze; Core unchanged | Phase 10 Sprint 2 |
| 2026-07-26 | — | Phase 10 Sprint 3 — Observability platform (health/telemetry/usage/alerts/ops/timeline); Core isolated | Phase 10 Sprint 3 |
| 2026-07-26 | — | Phase 10 Sprint 4 — CS center, feedback/issue lifecycle, KB expansion, support analytics, stabilization | Phase 10 Sprint 4 |
| 2026-07-26 | — | Phase 10 Sprint 5 — Performance/scalability/load/DB/cloud/resilience suite; Core isolated; Phase 10 75% | Phase 10 Sprint 5 |
| 2026-07-26 | BC-PORTAL / BC-LEGAL | Phase 10 Sprint 6 — Security suite + hardening; draft legal pages; Critical/High open=0; Phase 10 88% | Phase 10 Sprint 6 |
| 2026-07-26 | BC-MQL5 | Phase 10 Sprint 7 — Market listing pack, assets, compliance suite, Core SHA match; screenshots pending; Phase 10 95% | Phase 10 Sprint 7 |
| 2026-07-26 | BC-PORTAL / BC-SUPPORT | Phase 10 Sprint 8 — Website launch suite, marketing pages, journey/workflows, KB≥20; READY_WITH_CONDITIONS; Phase 10 98% | Phase 10 Sprint 8 |
| 2026-07-26 | ALL | Phase 10 Sprint 9 — Final Go/No-Go: GO FOR CONTROLLED PUBLIC LAUNCH; conditions for Open Stable/Global; Phase 10 99% | Phase 10 Sprint 9 |
| 2026-07-26 | ALL | Phase 10 Sprint 10 — Closure: APPROVED WITH CONDITIONS; Controlled Launch CERTIFIED; Phase 11 planning authorized; Global NOT authorized; Phase 10 100% COMPLETE · STOP for Owner | Phase 10 Sprint 10 |
| 2026-07-26 | BC-LEGAL / BC-BRAND / BC-PAYLIC / BC-INSTALL / BC-CORE / BC-QGATES / BC-SUPPORT / BC-PORTAL | Owner production readiness checklist ✓ — gates VERIFIED; BC-MQL5 screenshots remain open | Owner attestation |
| 2026-07-26 | — | Phase 11 Sprint 1 started — Global Ops Center · KPIs · commercial workflows · executive reports · CS ops; Core unchanged | Phase 11 Sprint 1 |
| 2026-07-26 | — | Phase 11 Sprint 2 — Enterprise BI · revenue/subscription/customer/ops analytics · forecasting (FORECAST segregated); Core unchanged | Phase 11 Sprint 2 |
| 2026-07-26 | — | Phase 11 Sprint 3 — Partner/Affiliate/Reseller ecosystem · config commission engine · portal; Core unchanged | Phase 11 Sprint 3 |
| 2026-07-26 | — | Phase 11 Sprint 4 — Enterprise CRM · org accounts · seat licensing · RBAC · billing · audit; Core unchanged | Phase 11 Sprint 4 |
| 2026-07-26 | — | Phase 11 Sprint 5 — Localization · 7 language packs · regional config · translation workflow · QA; Core unchanged · STOP for Sprint 6 | Phase 11 Sprint 5 |
| 2026-07-26 | — | Phase 11 Sprint 6 — Mobile Companion · Android/iOS scaffold · auth/2FA · licenses · push · support; Core unchanged · STOP for Sprint 7 | Phase 11 Sprint 6 |
| 2026-07-26 | — | Phase 11 Sprint 7 — Enterprise AI Assistant · KB retrieval · escalation · multi-surface · trading refused; Core unchanged · STOP for Sprint 8 | Phase 11 Sprint 7 |
| 2026-07-26 | — | Phase 11 Sprint 8 — Enterprise API Platform · Developer Portal · webhooks · SDKs; Core never API-accessible · STOP for Sprint 9 | Phase 11 Sprint 8 |
| 2026-07-26 | — | Phase 11 Sprint 9 — Global infra · HA · scale to 1M plan · observability · BC/DR · Ops Center; Core unchanged · STOP for Sprint 10 | Phase 11 Sprint 9 |
| 2026-07-26 | — | Phase 11 Sprint 10 — CERTIFIED WITH CONDITIONS · Phase 11 100% · Phase 12 authorized (await Owner) · residual Medium BC-MQL5 screenshots | Phase 11 Sprint 10 |
| 2026-07-26 | — | Phase 12 Sprint 1 — LTS activation · CS/Support/BI/Ops/Release 1.0.x · V2 planning only · monthly exec pack · Core frozen · STOP for V2.x Owner approval | Phase 12 Sprint 1 |

---

## Launch eligibility formula

```
LAUNCH_GO_ELIGIBLE =
  BC-LEGAL=VERIFIED
  AND BC-PAYLIC=VERIFIED
  AND BC-PORTAL=VERIFIED
  AND BC-INSTALL=VERIFIED
  AND BC-BRAND=VERIFIED
  AND BC-QGATES=VERIFIED
  AND BC-CORE=VERIFIED
  AND BC-SUPPORT=VERIFIED
  AND (Market not in window OR BC-MQL5=VERIFIED)
```

Owner may waive individual gates **in writing only**; waivers recorded in this file.

---

*End of BOARD_CONDITIONS_TRACKER.md*
