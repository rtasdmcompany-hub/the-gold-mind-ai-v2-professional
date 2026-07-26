# TRANSLATION_WORKFLOW.md

## Repository

- Path: `H:\PERSONAL\RTAS Digital Marketing Company\RTAS Softwear\THE GOLD MIND AI v2.0 Professional\Commercial\CustomerPortal\web\locales`
- Version control: per-pack `manifest.version` + `messages.json`
- Status dashboard: admin Localization · CLI suite

## Status (demo run)

| Locale | % | Missing | Status |
|--------|--:|--------:|--------|
| en | 100 | 0 | published |
| ur | 100 | 0 | published |
| ar | 100 | 0 | published |
| fr | 100 | 0 | published |
| de | 100 | 0 | published |
| es | 100 | 0 | published |
| tr | 100 | 0 | published |

## Workflow

1. Translator proposes string → `submitTranslationForReview`
2. Reviewer approves → `approveTranslation`
3. Publish by updating pack `messages.json` and bumping `manifest.version`
4. Missing keys: `missingTranslationReport(locale)`
