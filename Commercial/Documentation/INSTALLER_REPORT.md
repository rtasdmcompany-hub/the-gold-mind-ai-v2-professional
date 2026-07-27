# INSTALLER_REPORT.md

**Product:** THE GOLD MIND AI v2.0 PROFESSIONAL  
**Date:** 2026-07-27  
**Version:** 1.0.0 stable  
**Validation script:** `Commercial/Installer/Professional/scripts/Validate-Installer.ps1`

---

## Installer artifacts

| Artifact | Location | Status |
|----------|----------|--------|
| Inno Setup spec | `inno/TheGoldMindProfessional.iss` | Present |
| Payload scripts | `inno/payload/scripts/` | Present |
| EA binary slot | `inno/payload/ea/` | Present (CORE_SHA256.txt) |
| Launcher source | `tools/launcher/` | Present |
| Setup bootstrap | `tools/setup/` | Present |
| Build script | `scripts/Build-CommercialRelease.ps1` | Present |
| Validate script | `scripts/Validate-Installer.ps1` | Present |
| Release checksum | `Releases/1.0.0/installer/Setup.exe.sha256` | Present |
| Setup.exe binary | `Releases/1.0.0/installer/Setup.exe` | **NOT IN REPO** (hash only) |

---

## Payload structure validation (static)

The installer payload includes:

- `ea/TheGoldMindAI_Professional.ex5` (certified binary copy)
- `bin/TGM-Professional-Launcher.exe`
- `scripts/Deploy-EA-To-MT5.ps1`
- `scripts/Activate-License.ps1`
- `scripts/PostInstall-Wizard.ps1`
- `config/portal.json`, `config/version.json`
- EULA, README, INFO_BEFORE

Core SHA in payload matches frozen certification:

```
75002e46e3c200292c3696b2767bba20f2dd4200c74078555f84bc1f54a033ce
```

---

## Validation checklist

| Check | Result | Notes |
|-------|--------|-------|
| Setup.exe exists locally | **SKIP** | Binary not checked into repo |
| Payload zip structure | **PASS** (static review) | Scripts + EA slot verified |
| Silent install test | **SKIP** | Requires Setup.exe binary |
| Desktop shortcut | **NOT TESTED** | Requires live install |
| Start Menu shortcut | **NOT TESTED** | Requires live install |
| Version detection | **PASS** (static) | `version.json` present |
| License activation script | **PASS** (static) | `Activate-License.ps1` present |
| MT5 detection script | **PASS** (static) | `Deploy-EA-To-MT5.ps1 -ListOnly` |
| Uninstall registry | **NOT TESTED** | Requires live install |
| Rollback | **NOT TESTED** | Requires live install |

---

## Expected Setup.exe hash (release record)

```
52116ac997e6be90b74cd2d6b94ed0213db9e6d0c926ee6cf851758a9f049cc7  Setup.exe
```

---

## Owner actions for full installer validation

1. Place `Setup.exe` at `Commercial/Releases/1.0.0/installer/Setup.exe`
2. Run:
   ```powershell
   .\Commercial\Installer\Professional\scripts\Validate-Installer.ps1 `
     -SetupExe "Commercial\Releases\1.0.0\installer\Setup.exe"
   ```
3. Code-sign Setup.exe for Windows SmartScreen trust (see `SIGNING_WORKFLOW.md`)

---

## Verdict

**Installer packaging: READY (static)** — all scripts, payload structure, and Core SHA verified. Live silent-install validation pending Owner provision of Setup.exe binary on this machine.
