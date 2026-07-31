# FINAL_BUILD_REPORT.md

**Product:** THE GOLD MIND PROFESSIONAL 1.0.0  
**Date:** 2026-07-31  
**Release freeze:** ACTIVE

---

## Local production build

| Item | Value |
|------|-------|
| Command | `npm run build` in `Commercial/CustomerPortal/web` |
| Result | **PASS** |
| BUILD_ID | `4Xs3---i8WWGDhpEgF2Qk` |
| TypeScript | `tsc --noEmit` **PASS** |
| Framework | Next.js (App Router) |

---

## Release package build fingerprints

| Artifact | Path | SHA-256 |
|----------|------|---------|
| Stable ZIP | `Commercial/Releases/1.0.0/TGM_PROFESSIONAL_1.0.0_stable.zip` | `e61120628ba0d43d9d0f84d931cb0cd863890fa95a0e997b04d13a951d83229a` |
| Setup.exe | `Commercial/Releases/1.0.0/installer/Setup.exe` | `f48f3698a5401a66869481c7cb615505067fd4f64699b87f484db6afdfd29b07` |
| TheGoldMindSetup.exe | same bytes as Setup.exe | `f48f3698…` |
| EX5 | `Experts/TheGoldMindAI_Professional.ex5` | `890e22254ef44f86e82bc3700cd2b0dd0eaddf57c3ce91ff0f801b999c347535` |
| MQ5 | `Experts/TheGoldMindAI_Professional.mq5` | `9fd202466a0894577f12721610b4a9a80f6f8d02bb9fd908aed3d3e88654d49a` |

Sign mode: **unsigned** (Owner Authenticode pending).

---

## Generated configuration (synchronized)

| File | Purpose |
|------|---------|
| `brand.generated.json` | Brand snapshot |
| `product.generated.json` | Product snapshot |
| `Installer/.../brand-defines.iss` | Inno defines from brand+product |
| `Installer/.../payload/EULA.txt` | Summary EULA from export |

Regenerate: `cd Commercial/CustomerPortal/web && npx tsx scripts/export-brand.mjs`

---

## Reproducibility

- Release ZIP / Setup hashes match `SHA256SUMS.txt` and portal catalog constants  
- Portal `validate:releases` resolves the same ZIP locally and via public mirror path  
- Core cert constants now equal frozen MQ5 SHA (integrity match)

---

## Build status

**PASS (local production build + release artifacts)**  
**WARN (Vercel preview of latest commit failed; Production not yet on this build)**
