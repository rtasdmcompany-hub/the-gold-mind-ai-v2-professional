# MISSING_COMPONENTS.md

**Audit date:** 2026-07-26  
**Rule:** Listed only if not physically found (or found only as design/docs without artifact).  
**Action:** Do NOT implement in this audit.

---

## Critical (blocks commercial install-and-test)

| # | Missing item | Why required | Effort estimate |
|---|--------------|--------------|-----------------|
| 1 | `Setup.exe` / `TheGoldMindSetup.exe` or MSI | Customers need a standard Windows installer; PS1 alone is not a signed retail installer | **5–10 engineer-days** (Inno/NSIS project + branding + QA) |
| 2 | Inno Setup (`.iss`) or NSIS (`.nsi`) project | Build reproducibility for the installer binary | **2–4 days** (with #1) |
| 3 | Production release ZIP containing EA deploy layout | Manifest names `TGM_PROFESSIONAL_2.0.0_stable.zip` but file **NOT FOUND**; portal ZIP builder explicitly **does not embed** Trading Engine binaries | **3–6 days** (packaging script + MT5 folder layout + tests) |
| 4 | Installer step that installs `.ex5` into MT5 data `Experts` | Without this, “install” does not make the EA runnable | **2–4 days** (detect terminal ID, copy, permissions, docs) |
| 5 | Committed checksum files (`*.sha256`) for release artifacts | Integrity verification for download/update | **0.5–1 day** once ZIP exists |
| 6 | Verifiable Authenticode-signed installer binary in release store | Customer trust / SmartScreen; Owner attestation cannot be verified against repo artifact | **1–3 days** (cert + signtool + pipeline) — assumes cert available |

---

## High (blocks polished release / automation)

| # | Missing item | Why required | Effort estimate |
|---|--------------|--------------|-----------------|
| 7 | GitHub Actions / CI workflows | `BUILD_PIPELINE.md` assumes GitHub CI; `.github/workflows` **NOT FOUND** | **3–5 days** |
| 8 | SBOM (`sbom.json` / CycloneDX / SPDX) | Enterprise procurement / security reviews | **1–2 days** |
| 9 | Dedicated offline license validator + license cache module | Docs describe offline grace; `server/licensing` has **no** offline implementation symbols | **3–5 days** |
| 10 | `TheGoldMind.exe` (if product promises a desktop companion EXE) | **NOT FOUND**; only `.cmd` launcher stub | **5–15 days** if a real desktop app is in scope; **N/A** if intentionally MT5-only |

---

## Medium (naming / Market / ops)

| # | Missing item | Why required | Effort estimate |
|---|--------------|--------------|-----------------|
| 11 | Files named `TheGoldMind.mq5` / `TheGoldMind.ex5` | Spec examples use short names; repo uses `TheGoldMindAI_Professional.*` — document or alias | **0.5 day** (docs/alias) |
| 12 | Live Market screenshots in `MarketEdition/Screenshots` | Count observed **0**; required before Market Stable upload | **1–2 days** (capture + QA) |
| 13 | Rollback ZIP retained under `Commercial/Releases/` | Updater supports rollback folder locally; committed previous package **NOT FOUND** | **0.5 day** once packages exist |
| 14 | End-to-end “package:release” npm/CLI that writes artifacts to `Commercial/Releases/<ver>/` | Today packaging is split (PS + portal runtime) | **2–3 days** |

---

## Present but incomplete relative to “commercial shell ZIP”

Portal `buildCommercialPackageZip` produces only:

- `bin/TGM-Professional-Launcher.cmd`
- `bin/VERSION.txt`
- `config/package-manifest.json`
- `README.txt`

**Missing inside that ZIP (by design in code comments):** Core `.ex5` / Include tree.

---

## Not missing (do not re-build)

- Certified Core `.mq5` + matching SHA  
- Compiled `.ex5` with 0-error log  
- Portal license activation / device binding / renew APIs  
- PowerShell install/update/uninstall scripts  
- RC-2 release notes / version metadata  
- Market package *metadata* files  

---

## Priority order recommended (Owner)

1. Define product install contract: **MT5-only** vs **Setup.exe + EA deploy**.  
2. Produce release ZIP with EA layout + SHA256.  
3. Wire installer/updater to that ZIP (or Setup.exe wrapping it).  
4. Sign installer; publish checksums.  
5. Add CI to reproduce artifacts.  
6. Offline license cache if required by EA runtime.  
7. SBOM + Market screenshots.
