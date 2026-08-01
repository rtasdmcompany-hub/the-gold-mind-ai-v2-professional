# GitHub Release 1.0.0

Upload from this folder only (canonical — no `github-assets/` mirror):

```bash
gh release create v1.0.0 \
  --title "THE GOLD MIND PROFESSIONAL 1.0.0" \
  --notes-file RELEASE_NOTES.md \
  installer/Setup.exe \
  TGM_PROFESSIONAL_1.0.0_stable.zip \
  SHA256SUMS.txt \
  SBOM.json \
  VERSION_MANIFEST.json
```
