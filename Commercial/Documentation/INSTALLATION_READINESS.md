# INSTALLATION_READINESS.md

**Audit date:** 2026-07-26  
**Question:** Can the Owner install and test *from this repository* as a commercial customer would?

---

## Short answer

**Not as a finished Windows commercial installer product.**  

**Yes for developer-style EA testing** (manual MetaTrader compile/attach) and **portal SaaS testing** (run Next.js locally), with gaps noted below.

---

## Path A — Customer Windows install (commercial)

| Requirement | Ready? |
|-------------|--------|
| Download a signed Setup.exe from portal/CDN | **NO** — `Setup.exe` **NOT FOUND** |
| Run MSI / Inno / NSIS installer | **NO** — project files **NOT FOUND** |
| Installer deploys `.ex5` into MT5 | **NO** — PowerShell installer does not copy EA |
| Verify package SHA against committed checksum file | **NO** — `*.sha256` **NOT FOUND**; stable ZIP named in manifest **NOT FOUND** on disk |
| Authenticode verification of installer in repo | **NO** — signed binary **NOT FOUND** |

**Available substitute:** PowerShell commercial shell under `%LOCALAPPDATA%\THE GOLD MIND PROFESSIONAL` (folders, launcher CMD, shortcuts). That is **not** a full product install of the trading EA.

---

## Path B — Owner / engineer EA test (manual)

| Step | Ready? | How |
|------|--------|-----|
| Source present | **YES** | `Experts/TheGoldMindAI_Professional.mq5` |
| Compiled `.ex5` present | **YES** | `Experts/TheGoldMindAI_Professional.ex5` |
| Compile evidence | **YES** | Log: **0 errors, 5 warnings** |
| Core SHA match | **YES** | MQ5 hash = certified `75002e46…a033ce` |
| Instructions | **YES** | Root `README.md` (F7 compile, attach) |
| Automatic MT5 Experts folder install | **NO** | Manual copy / MetaEditor deploy required |

---

## Path C — Customer Portal / license test

| Step | Ready? | Evidence |
|------|--------|----------|
| Start portal | **YES (commands exist)** | `cd Commercial/CustomerPortal/web` → `npm run dev` or `npm run build` + `npm start` |
| Login / register routes | **YES** | `src/app/login`, `register`, `portal/*` |
| Licenses UI | **YES** | `portal/licenses` |
| Activation API | **YES** | `/api/licenses/actions` |
| Downloads UI | **YES** | `portal/downloads` |
| Production env secrets | **OWNER-DEPENDENT** | `.env.local` / `.env.local.example` present; live PSP/hosting not re-verified in this audit |

---

## Installer behavior (verified from script)

`Install-TheGoldMindProfessional.ps1` performs:

1. OS/RAM/disk checks  
2. MT5 path detection (does not fail hard if missing)  
3. Creates install root folders  
4. Copies **manifest + README** only from `packages/`  
5. Writes `TGM-Professional-Launcher.cmd` (message to attach EA from portal)  
6. Shortcuts + HKCU uninstall registration  

It **never** installs `TheGoldMindAI_Professional.ex5`.

---

## Residual board item (Market)

- Live MQL5 Market screenshots folder file count observed: **0** under `Commercial/MarketEdition/Screenshots` (listing pack docs exist; live captures still outstanding per prior board condition).

---

## Conclusion

Installation readiness for **commercial end-user install testing** is blocked until missing release binaries/packages and EA deploy packaging exist (see `MISSING_COMPONENTS.md`).  

Installation readiness for **Core EA attach testing** is available via existing `.mq5` / `.ex5` and MetaEditor instructions.
