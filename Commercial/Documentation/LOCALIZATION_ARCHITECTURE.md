# LOCALIZATION_ARCHITECTURE.md

**Phase:** 11 · Sprint 5  
**Surface:** `/portal/admin/localization`  
**Core Trading Engine:** ISOLATED · never imported by i18n modules

## Design

| Layer | Responsibility |
|-------|----------------|
| `types.ts` | Locale manifests, regional settings, namespaces |
| `packs.ts` | Builtin + disk packs under `locales/{code}/` |
| `runtime.ts` | `t` / `tp` · Intl date/number/currency · RTL · fallback |
| `regional.ts` | Per-region language/timezone/currency/measurement |
| `workflow.ts` | Review · approval · missing-key reports |
| `qa.ts` | Completeness · unicode · RTL integrity |
| `compliance.ts` | Privacy/terms/cookies readiness |

## Fallback chain

`locale → manifest.fallback → en → key`

## Installable packs (no code change)

Drop `manifest.json` + `messages.json` into `H:\PERSONAL\RTAS Digital Marketing Company\RTAS Softwear\THE GOLD MIND AI v2.0 Professional\Commercial\CustomerPortal\web\locales/{code}/`.

## Namespaces

- `website` (9 keys)
- `portal` (8 keys)
- `admin` (4 keys)
- `partner` (4 keys)
- `installer` (3 keys)
- `updater` (3 keys)
- `emails` (4 keys)
- `knowledge` (2 keys)
- `support` (4 keys)
- `errors` (4 keys)
- `notifications` (2 keys)
- `docs` (2 keys)
- `legal` (7 keys)

## Isolation rule

Localization must not alter business logic or the certified Core Trading Engine.
