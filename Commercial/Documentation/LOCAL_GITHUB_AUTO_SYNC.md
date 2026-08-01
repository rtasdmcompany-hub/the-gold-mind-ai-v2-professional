# Local drive ↔ GitHub auto-sync (Owner PC)

**Product:** THE GOLD MIND PROFESSIONAL  
**Why:** Cloud agents update **GitHub + Vercel**. They cannot write to your Windows `H:` folder.  
This kit keeps your local project tree aligned whenever `main` moves on GitHub.

---

## One-time install (Owner Windows PC)

1. Open the project root (git clone), e.g.  
   `H:\PERSONAL\...\THE GOLD MIND AI v2.0 Professional`
2. Confirm it is a git repo (has a `.git` folder). If not, clone:  
   `git clone https://github.com/rtasdmcompany-hub/the-gold-mind-ai-v2-professional.git`
3. PowerShell **in that root**:

```powershell
.\Commercial\Scripts\Install-LocalGitAutoSync.ps1
```

Optional (if you often have uncommitted local edits):

```powershell
.\Commercial\Scripts\Install-LocalGitAutoSync.ps1 -AllowDirty
```

This registers Windows Scheduled Task **`TGM-LocalGitAutoSync`**:
- runs at logon  
- repeats every **5 minutes**  
- executes `Sync-LocalFromGitHub.ps1` → `git fetch` + `git pull --ff-only origin main`

---

## Manual sync anytime

Double-click:

```
Commercial\Scripts\Sync-Now.cmd
```

Or:

```powershell
.\Commercial\Scripts\Sync-LocalFromGitHub.ps1
```

---

## What gets updated locally

Everything on GitHub `main`, including:

- `Commercial/Releases/1.0.0/installer/Setup.exe` (+ `.sha256`)
- stable ZIP / manifests / docs  
- Customer Portal source under `Commercial/CustomerPortal/web`

After sync, Setup should be **~457728 bytes** and match `Setup.exe.sha256`.  
Obsolete `TheGoldMindSetup.exe` aliases are removed if found.

---

## Uninstall

```powershell
.\Commercial\Scripts\Uninstall-LocalGitAutoSync.ps1
```

---

## Notes

- Needs **git** installed and access to the GitHub repo (same credentials you already use).  
- Uses **fast-forward only** — will not rewrite your history.  
- If pull fails (divergent local commits), fix once manually, then auto-sync continues.  
- Live website deploy remains on **Vercel** (separate from this local file sync).
