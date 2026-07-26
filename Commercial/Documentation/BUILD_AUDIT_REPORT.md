# BUILD_AUDIT_REPORT.md

**Product:** THE GOLD MIND v1.0 / AI PROFESSIONAL  
**Audit date:** 2026-07-26  
**Scope:** Repository inspection only — no features, no UI work, no Core modifications  
**Method:** Direct filesystem inspection + file hashes + source/script reads  

---

## SECTION 1 — WINDOWS INSTALLER

| Question | Evidence |
|----------|----------|
| Exists? | **Partial — PowerShell commercial shell installer only** |
| `Setup.exe` | **NOT FOUND** |
| `TheGoldMindSetup.exe` | **NOT FOUND** |
| MSI | **NOT FOUND** |
| NSIS (`.nsi`) | **NOT FOUND** under `Commercial/Installer` |
| Inno Setup (`.iss`) | **NOT FOUND** under `Commercial/Installer` |
| Portable package (committed ZIP) | **NOT FOUND** under `Commercial/Installer` or `Commercial/Releases` |

**What does exist**

| Item | Location |
|------|----------|
| Install script | `Commercial/Installer/Professional/scripts/Install-TheGoldMindProfessional.ps1` |
| Update script | `Commercial/Installer/Professional/scripts/Update-TheGoldMindProfessional.ps1` |
| Uninstall script | `Commercial/Installer/Professional/scripts/Uninstall-TheGoldMindProfessional.ps1` |
| Channel manifests | `Commercial/Installer/Professional/packages/manifest.{stable,rc,development}.json` |
| Install notes | `Commercial/Installer/Professional/packages/README_INSTALL.txt` |
| Installer README | `Commercial/Installer/Professional/README.md` |

**Version (from install script / stable manifest)**

- Product version string: `2.0.0`
- Build number: `21060` (script + `manifest.stable.json`)
- Portal package.json version (separate): `1.0.10-phase12.s1`

**Build process**

- Documented: run PowerShell install/update scripts (see Installer README).
- No Inno/NSIS/MSI project files found to compile a Windows Setup binary.
- Portal can **generate** a commercial-shell ZIP at runtime via `src/server/releases/package-artifact.ts` into `.data/releases/artifacts/` (runtime path — not a committed production artifact).

**Signing status**

- `manifest.stable.json` states: `"status": "pending_code_sign"` and placeholder Authenticode subject.
- Physical signed `Setup.exe` / signed MSI: **NOT FOUND** in repository.
- Note: `OWNER_PRODUCTION_READINESS_ATTESTATION.md` marks “Authenticode Signed Installer ✓”, but **no signed installer binary is present in this repository to verify**. Attestation ≠ artifact.

---

## SECTION 2 — MT5 EXPERT ADVISOR

| Expected name | Result |
|---------------|--------|
| `TheGoldMind.ex5` | **NOT FOUND** |
| `TheGoldMind.mq5` | **NOT FOUND** |
| `TheGoldMindAI_Professional.mq5` | **FOUND** — `Experts/TheGoldMindAI_Professional.mq5` (9235 bytes) |
| `TheGoldMindAI_Professional.ex5` | **FOUND** — `Experts/TheGoldMindAI_Professional.ex5` (2,088,936 bytes) |
| Compile log | **FOUND** — `Experts/TheGoldMindAI_Professional.log` |

**Compile status (from log tail)**

```
Result: 0 errors, 5 warnings, 128973 ms elapsed, cpu='X64 Regular'
```

**Build instructions (from root `README.md`)**

1. Keep `Experts/` and `Include/` as siblings.  
2. Compile `Experts/TheGoldMindAI_Professional.mq5` (MetaEditor F7).  
3. Attach to chart.

**Output folder**

- Compiled binary present beside source: `Experts/TheGoldMindAI_Professional.ex5`
- Include tree: `Include/` (**791** files counted)

**SHA-256 (computed this audit)**

| File | SHA-256 |
|------|---------|
| `Experts/TheGoldMindAI_Professional.mq5` | `75002e46e3c200292c3696b2767bba20f2dd4200c74078555f84bc1f54a033ce` |
| Certified value (`RC2_CORE_CERTIFICATION.txt` / portal Core constant) | `75002e46e3c200292c3696b2767bba20f2dd4200c74078555f84bc1f54a033ce` |
| Match | **YES** |
| `Experts/TheGoldMindAI_Professional.ex5` | `7883b4155aabb088e07f9f9563b413b7b63de7188d610021fb4fdca603e8c619` |

---

## SECTION 3 — COMMERCIAL RELEASE PACKAGE

| Capability | In repo? | Evidence |
|------------|----------|----------|
| Windows Installer (Setup.exe/MSI) | **NOT FOUND** | No binary / no ISS/NSI |
| ZIP Package (committed) | **NOT FOUND** | No `.zip` under Installer/Releases; manifests *name* `TGM_PROFESSIONAL_2.0.0_stable.zip` but file absent |
| ZIP Package (runtime generator) | **EXISTS (code)** | `CustomerPortal/web/src/server/releases/package-artifact.ts` builds commercial-shell ZIP (launcher/README/manifest only — **does not embed `.ex5`**) |
| Release Manifest | **EXISTS** | `Commercial/Releases/RC-2/MANIFEST.md` + installer `manifest.*.json` + Market `MarketEdition/Package/MANIFEST.json` |
| Checksums (committed `*.sha256`) | **NOT FOUND** | No checksum files in Installer/Releases |
| Checksums (runtime) | **EXISTS (code)** | SHA-256 computed when portal ensures artifacts |
| Release Notes | **EXISTS** | `Commercial/Releases/RC-2/RELEASE_NOTES.md` |
| Rollback Package | **PARTIAL** | Updater script keeps `rollback/previous`; no committed rollback ZIP |
| Version Metadata | **EXISTS** | `Commercial/Releases/RC-2/VERSION.json` |
| SBOM | **NOT FOUND** | `sbom.json` / CycloneDX / SPDX: **NOT FOUND** |

---

## SECTION 4 — INSTALLATION PROCESS (customer journey)

| Step | Status | Why |
|------|--------|-----|
| Download | **PARTIAL** | Portal pages/APIs exist (`/portal/downloads`, `/api/releases/download/[id]`). Committed production ZIP for customers: **NOT FOUND**. Requires running portal + artifact generation. |
| Install | **PARTIAL** | PowerShell commercial shell only. No Setup.exe. Installer **does not** copy EA into MT5 `Experts`. |
| Login | **EXISTS (code)** | `src/app/login`, portal auth stack |
| License Activation | **EXISTS (code)** | `/portal/licenses`, `/api/licenses/actions` (`activateLicense`) |
| MT5 Detection | **EXISTS (script)** | Installer detects MT5 paths / MetaQuotes profiles; writes `mt5-detection.json` |
| EA Installation | **MISSING in installer** | Scripts instruct user to attach EA from “licensed package”; no automatic `.ex5` deploy into terminal data folder |
| First Launch | **PARTIAL** | Installer creates `bin\TGM-Professional-Launcher.cmd` (echo + pause). `TheGoldMind.exe`: **NOT FOUND** |
| Software Update | **EXISTS (script + API)** | `Update-TheGoldMindProfessional.ps1` + `/api/releases/check` — updates commercial shell ZIP contents only |

---

## SECTION 5 — LICENSE SYSTEM

| Item | Status | Evidence |
|------|--------|----------|
| License Server | **EXISTS (portal service)** | `CustomerPortal/web/src/server/licensing/` encrypted store + APIs |
| Activation API | **EXISTS** | `POST` actions via `/api/licenses/actions` (`activate`) |
| Machine Binding | **EXISTS** | Device fingerprint hash + device records in `license-service.ts` |
| Subscription Validation | **EXISTS** | Status lifecycle + `validateLicenseOnline` + grace |
| Offline Handling | **NOT FOUND (dedicated offline validator)** | No `offline` symbols under `server/licensing/`. Docs mention offline grace; implementation found is **online** validation + short-lived token (1-day) |
| License Cache | **PARTIAL** | Validation token issued; dedicated persistent offline license cache module: **NOT FOUND** in licensing server |
| Renewal | **EXISTS** | `renewLicense` in `license-service.ts` |

`Commercial/Licensing/Professional/README.md` still says design/deferred historically; **implementation lives in the portal**, not that folder.

---

## SECTION 6 — BUILD PIPELINE

| Item | Status | Evidence |
|------|--------|----------|
| Portal build | **EXISTS** | `npm run build` / `dev` / `start` in `CustomerPortal/web/package.json` |
| Validation harness | **EXISTS** | `npm run validate:rc2` and phase scripts |
| Packaging commands | **PARTIAL** | Runtime `ensurePackageArtifact` / PowerShell install — no `npm run package:installer` producing Setup.exe |
| Installer compile commands | **NOT FOUND** | No ISCC/makensis scripts |
| Environment variables | **PARTIAL** | `.env.local` / `.env.local.example` present under portal (names observed; contents not disclosed in this report) |
| GitHub Actions | **NOT FOUND** | `.github/workflows`: **NOT FOUND** at repo root or portal |
| CI/CD automation | **DESIGN DOCS ONLY** | `BUILD_PIPELINE.md`, `DEPLOYMENT_GUIDE.md` describe GitHub→artifact flow; no workflow YAML found |
| Release automation | **PARTIAL** | Portal release store + admin UI; no end-to-end GitHub release pipeline |

---

## SECTION 7 — EXPECTED PRODUCTION BUILD OUTPUTS (should exist)

See companion `RELEASE_ARTIFACTS.md`.

---

## SECTION 8 — SUMMARY OF MISSING ITEMS

See companion `MISSING_COMPONENTS.md`.

---

## SECTION 9 — FINAL DECISION

See companion `FINAL_BUILD_DECISION.md`.

**Verdict preview:** **C) NOT READY** for commercial customer install-from-repo as a signed Windows product. EA source/binary for **manual** MetaEditor/MT5 testing **does** exist.
