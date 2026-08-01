# AGENT UPDATE DISCIPLINE (standing Owner rule)

When any update ships, the agent **finishes A→Z** without leaving parallel/old copies that confuse install or support.

## Mandatory behavior

1. **Replace, do not stack** — new Setup/ZIP/docs overwrite the previous file at the canonical path.  
2. **No file doubling** — one `Setup.exe`, one stable ZIP, one `VERSION_MANIFEST.json`, one source of installer wizard (`Program.net48.cs`).  
3. **No extra mirror folders** — do not keep `github-assets/` or alias binaries in git; build may stage temporarily, then discard.  
4. **Sync all consumers** — `Commercial/Releases/1.0.0/`, `public/releases/`, checksums, SBOM, portal `STABLE_SHA256` / size, CORE mq5 SHA, RELEASE notes.  
5. **Push** the branch after the update.  
6. **Deploy** production when Vercel auth is available; otherwise record **OWNER ACTION** clearly (never pretend deploy succeeded).  
7. **Neat tree** — only working artifacts and required docs; delete obsolete duplicates created by the change.  
8. **Local Windows drive** is **not** writable from cloud agents. Owner keeps `H:` (or any clone) current via  
   `Commercial/Scripts/Install-LocalGitAutoSync.ps1` (Scheduled Task pulls `origin/main`). See `LOCAL_GITHUB_AUTO_SYNC.md`.

## Canonical 1.0.0 layout

```
Commercial/Releases/1.0.0/
  installer/Setup.exe
  TGM_PROFESSIONAL_1.0.0_stable.zip
  SHA256SUMS.txt
  VERSION_MANIFEST.json
  SBOM.json
  RELEASE_NOTES.md
  RELEASE_CANDIDATE.md
  SIGNING_WORKFLOW.md
```

Portal download copy (same ZIP bytes/hash):

```
Commercial/CustomerPortal/web/public/releases/TGM_PROFESSIONAL_1.0.0_stable.zip
Commercial/CustomerPortal/web/public/releases/latest-stable.json
```

## Installer source (single)

- `Commercial/Installer/Professional/tools/setup/Program.net48.cs`  
- Build: Windows `csc` **or** Linux `mcs` (mono) with embedded `payload.zip`
