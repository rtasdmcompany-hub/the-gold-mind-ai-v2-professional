# FINAL_BUILD_DECISION.md

**Audit date:** 2026-07-26  
**Product:** THE GOLD MIND v1.0  
**Core SHA-256 (mq5):** `75002e46e3c200292c3696b2767bba20f2dd4200c74078555f84bc1f54a033ce` — **MATCH** certified value  
**Core modified during audit:** NO  

---

## FINAL ANSWER

# C) NOT READY

List of everything preventing commercial installation-from-repository:

1. **`Setup.exe` / `TheGoldMindSetup.exe` / MSI — NOT FOUND**  
2. **Inno Setup / NSIS project files — NOT FOUND**  
3. **Committed production ZIP** named by stable manifest (`TGM_PROFESSIONAL_2.0.0_stable.zip`) — **NOT FOUND**  
4. **Committed checksum files (`*.sha256`) — NOT FOUND**  
5. **SBOM — NOT FOUND**  
6. **GitHub Actions CI/CD workflows — NOT FOUND**  
7. **Installer does not deploy `TheGoldMindAI_Professional.ex5` into MT5 Experts** — verified in `Install-TheGoldMindProfessional.ps1`  
8. **`TheGoldMind.exe` — NOT FOUND** (launcher is `.cmd` stub only)  
9. **Signed installer binary not present in repo** — cannot verify Authenticode against an artifact here (attestation doc exists; binary does not)  
10. **Portal-generated ZIP explicitly excludes Trading Engine binaries** — commercial shell only  

---

## Why not A) READY FOR INSTALLATION

A requires everything needed already exists for immediate customer install. Missing Setup/ZIP/EA-deploy packaging fails that bar.

## Why not B) READY TO BUILD

B requires the repository to be *complete* such that only executing final build/packaging commands yields installable artifacts.  

Observed gaps are not “run one command” gaps:

- No installer project to compile  
- No packaging command that emits Setup.exe  
- No packaging path that embeds the certified `.ex5` into the customer ZIP (portal code deliberately omits it)  

Therefore the repo is **not** build-complete for commercial installers.

---

## What *can* be tested today (Owner/engineering)

| Test | How |
|------|-----|
| Core EA attach | Use existing `Experts/TheGoldMindAI_Professional.ex5` (or recompile `.mq5` with F7) in MetaTrader 5 manually |
| Portal / licensing | `cd Commercial/CustomerPortal/web` → `npm run dev` (env configured) |
| Commercial shell folders | `powershell -ExecutionPolicy Bypass -File Commercial\Installer\Professional\scripts\Install-TheGoldMindProfessional.ps1` |

These do **not** equal “customer downloads Setup and installs EA.”

---

## Companion documents

| Document | Path |
|----------|------|
| Full audit | `Commercial/Documentation/BUILD_AUDIT_REPORT.md` |
| Install readiness | `Commercial/Documentation/INSTALLATION_READINESS.md` |
| Artifact map | `Commercial/Documentation/RELEASE_ARTIFACTS.md` |
| Missing list | `Commercial/Documentation/MISSING_COMPONENTS.md` |

---

## STOP

No implementation performed. Awaiting Owner decision on packaging contract (Setup.exe + EA deploy vs MT5-manual-only) before any build/packaging work.
