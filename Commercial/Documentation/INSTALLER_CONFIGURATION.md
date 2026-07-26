# INSTALLER_CONFIGURATION.md

**Product:** THE GOLD MIND PROFESSIONAL Setup.exe  
**Core:** Frozen — packaging only  

---

## Current configuration (as built)

| Setting | Value | Source |
|---------|-------|--------|
| Portal base URL | `https://thegoldmind.ai` | `inno/payload/config/portal.json` |
| Build script default | `https://thegoldmind.ai` | `scripts/Build-CommercialRelease.ps1` `-PortalBase` |
| Activation API | `{portalBase}/api/licenses/actions` | `Activate-License.ps1` |
| Google login open | `{portalBase}/login?provider=google&return=/portal/licenses` | `Activate-License.ps1` |
| Setup.exe location | `Commercial/Releases/1.0.0/installer/Setup.exe` | Last commercial packaging build |

Installer does **not** hardcode trading endpoints. It only opens the commercial portal base for license activation.

---

## Required change for Vercel Production Test Mode

Once Owner provides the **verified** Vercel URL (from Vercel dashboard / `.vercel` link / CLI):

```powershell
cd "Commercial\Installer\Professional\scripts"
powershell -ExecutionPolicy Bypass -File .\Build-CommercialRelease.ps1 `
  -Version "1.0.0" `
  -PortalBase "https://YOUR-PROJECT.vercel.app" `
  -SignMode unsigned
```

This rewrites:

- `payload/config/portal.json`
- `payload/config/version.json`
- embedded payload inside new `Setup.exe`

**Not run in this session** — Vercel URL was not present in deployment configuration (no guessing).

---

## Post-rebuild customer flow

1. Run `Setup.exe`  
2. Activate License → calls Vercel `/api/licenses/actions`  
3. Optional Google login → Vercel `/login`  
4. EA deploy to MT5 remains local (unchanged; Core binary copy only)
