# Release sync — local folder ↔ website (same version everywhere)

## Goal

When the local commercial package is updated (freeze `.ex5`, presets, installer payload), the Customer Portal download and live website must serve **the same version** automatically after one command (and a Git push that triggers Vercel).

## One command

```powershell
cd "Commercial\Installer\Professional\scripts"
powershell -ExecutionPolicy Bypass -File .\Sync-ReleaseEverywhere.ps1 -Version 1.0.1 -Push
```

Without `-Push`, artifacts are built locally only. With `-Push`, GitHub `main` is updated so Vercel redeploys.

## What the script does

1. **Freeze EX5 gate** — packages only  
   `21503FA83938CF80AA24947A512EBE2F238AC7512BF9E48A21FBFF647D77F9B7`  
   (restore from payload if `Experts\` drifted).
2. Syncs Phase18 default preset into installer payload.
3. Runs `Build-CommercialRelease.ps1` → `Commercial/Releases/<version>/` + Setup.exe + ZIP.
4. Copies ZIP into `CustomerPortal/web/public/releases/` and writes `latest-stable.json`.
5. Updates portal version defaults (`brand.ts`, `product.ts`, `commercial-source.ts`, `package.json`).
6. Verifies the ZIP’s embedded EX5 equals the freeze hash.
7. Optional: `git commit` + `git push` → live site refresh.

## After every local update

1. Put the authorized freeze `.ex5` in  
   `Commercial/Installer/Professional/inno/payload/ea/`  
   (and/or `Experts/`).
2. Bump `-Version` if needed (e.g. `1.0.2`).
3. Run `Sync-ReleaseEverywhere.ps1 -Push`.
4. Wait for Vercel deploy, then confirm live ZIP EX5 SHA matches freeze.

## Live check

```powershell
# After deploy: download and hash the EX5 inside the ZIP
# Must equal: 21503FA83938CF80AA24947A512EBE2F238AC7512BF9E48A21FBFF647D77F9B7
```

Portal: https://the-gold-mind-ai-v2-professional.vercel.app

## Notes

- Do **not** recompile production EX5 unless Owner authorizes a new freeze hash.
- `SkipMq5Gate` allows packaging when `.mq5` source hash drifted but EX5 freeze is intact.
- Vercel token is not required if the GitHub repo is already linked to the Vercel project (push = deploy).
