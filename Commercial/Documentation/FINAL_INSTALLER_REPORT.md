# FINAL_INSTALLER_REPORT.md

**Product:** THE GOLD MIND AI v2.0 PROFESSIONAL  
**Date:** 2026-07-27  
**Setup.exe SHA-256:** `5981f411970ed94d6f84b5099ab13e2671f29f1dad7db61c8f1614b93d42e776`

## Rebuild

Commercial wizard rebuilt via `Build-CommercialRelease.ps1` (CSC + embedded payload). No Inno dependency.

## Wizard flow (interactive)

1. Welcome  
2. License Agreement  
3. Installation Folder (+ desktop shortcut option)  
4. Detect MetaTrader 5 / choose terminal  
5. Install progress (extract · EA deploy · shortcuts · unregister)  
6. Completed — Launch / Open Portal / Activate License  

**No MessageBox chain. No visible PowerShell/CMD windows** (hidden window style). Portal URL hardcoded to production Vercel.

## Portal URL (certified)

```
https://the-gold-mind-ai-v2-professional.vercel.app
```

Google activation launch:

```
https://the-gold-mind-ai-v2-professional.vercel.app/login?provider=google&callbackUrl=%2Fportal%2Flicenses
```

Obsolete `thegoldmind.ai` is rejected if found in legacy `portal.json`.

## Validation results

| Test | Result |
|------|--------|
| Payload portalBase | **PASS** |
| Silent install | **PASS** (exit 0) |
| EA binary present | **PASS** |
| Start Menu | **PASS** |
| Uninstall registry | **PASS** |
| MT5 detection (ListOnly) | **PASS** (6 candidates) |
| Post-install portal.json | Production Vercel URL |
| Uninstall / reinstall | Executed in RC-2 suite |

## Core

Trading Engine / Core SHA untouched — packaging copies certified `.ex5` only.
