# RC-2 Build Index

```
Commercial/Releases/RC-2/
  VERSION.json          — version metadata
  RELEASE_NOTES.md      — customer/executive release notes
  MANIFEST.md           — artifact map
  README.md             — this file
```

Referenced (not duplicated) build sources:

- Shared Core → `Experts/` + `Include/` (frozen)
- Website Edition → `Commercial/CustomerPortal/` + `Commercial/Installer/Professional/`
- MQL5 Edition → `Commercial/MarketEdition/` + same Core
- Documentation → `Commercial/Documentation/`

Validation commands:

```bash
cd Commercial/CustomerPortal/web
npm run validate:rc2
npx tsc --noEmit
```
