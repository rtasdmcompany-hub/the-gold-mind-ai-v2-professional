# INSTALLER_ARCHITECTURE.md

**Phase:** 9 · Sprint 5  
**Product:** THE GOLD MIND PROFESSIONAL (Website Edition)  
**Code:** `Commercial/Installer/Professional/`  
**Isolation:** Installer never modifies Core Trading Engine / Strategy / Risk / Recovery / Order Execution / Magic Number logic

---

## Design goal

Installation experience comparable to professional commercial software (wizard · validation · shortcuts · clean uninstall), scoped to the **commercial shell** that wraps the certified Core.

---

## Components

| Component | Path |
|-----------|------|
| Installation Wizard | `scripts/Install-TheGoldMindProfessional.ps1` |
| Secure Updater | `scripts/Update-TheGoldMindProfessional.ps1` |
| Uninstaller | `scripts/Uninstall-TheGoldMindProfessional.ps1` |
| Channel manifests | `packages/manifest.{stable,rc,development}.json` |

---

## Wizard steps

1. **System requirement validation** — Windows 10+, RAM/disk guidance  
2. **MT5 detection** — Program Files + MetaQuotes Terminal profiles (logged to `config/mt5-detection.json`)  
3. **Installation path selection** — default `%LOCALAPPDATA%\THE GOLD MIND PROFESSIONAL`  
4. **Folder layout** — `bin` · `config` · `logs` · `backup` · `updates` · `packages` · `rollback` · `icons`  
5. **Desktop + Start Menu shortcuts** (+ Uninstall shortcut) · optional `.ico`  
6. **Safe uninstall registration** — HKCU Uninstall key  

Silent mode: `-Silent` · Channel: `-Channel stable|rc|development`

---

## What is installed

- Commercial launcher (`bin/TGM-Professional-Launcher.cmd`)
- Version metadata (`config/version.json`)
- Channel manifest copy
- Icon folder placeholder

**Not installed by this sprint:** in-place mutation of Core EA source under `Experts/` / `Include/`. Licensed EA attach remains an MT5 operator step after portal activation.

---

## Uninstall safety

- Removes shortcuts + uninstall registry  
- Copies `backup/` aside before wipe  
- `-KeepLogs` preserves logs/config/backup  
- Never touches MT5 terminal installs or Core Trading Engine binaries outside the commercial root

---

*End of INSTALLER_ARCHITECTURE.md*
