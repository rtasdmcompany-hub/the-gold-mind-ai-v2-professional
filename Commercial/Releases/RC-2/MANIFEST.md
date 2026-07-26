# THE GOLD MIND RC-2 — Release Manifest

| Component | Location | Version / Tag |
|-----------|----------|---------------|
| Core EA | `Experts/TheGoldMindAI_Professional.mq5` | SHA-256 certified |
| Website Portal | `Commercial/CustomerPortal/web` | 0.5.0 / RC-2 |
| Installer | `Commercial/Installer/Professional` | RC-2 |
| Market Shell | `Commercial/MarketEdition` | RC-2 shell |
| Docs | `Commercial/Documentation` | Phase 9 Sprint 1–9 |
| Release archive | `Commercial/Releases/RC-2/` | this pack |

## Channels

| Channel | Package intent |
|---------|----------------|
| stable | Deferred until Authenticode + live PSP + legal VERIFIED |
| rc | **RC-2 active candidate** |
| development | Internal only |

## Rollback

Updater keeps `rollback/previous` · uninstall preserves backup copies · release archive retained under `Commercial/Releases/RC-2/`.

## Deployment packages

| Package | How to produce |
|---------|----------------|
| Portal | `npm run build` in CustomerPortal/web |
| Installer scripts | ship `Installer/Professional` folder |
| Core | ship certified `.mq5` + Include tree for Market/Website packaging pipelines |
| Docs PDF/MD | Documentation root |

Tag recommendation (when git available): `v2.0.0-rc.2`
