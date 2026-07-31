# COMMERCIAL_RELEASE_REPORT.md

**Product:** THE GOLD MIND PROFESSIONAL  
**Version:** 1.0.0  
**Channel:** stable  
**Build number:** 26211  
**Generated:** 2026-07-31  
**Package status:** RELEASE CANDIDATE — commercially packaged; Authenticode pending Owner certificate

---

## Package contents

Location: `Commercial/Releases/1.0.0/`

| File | Purpose | SHA-256 |
|------|---------|---------|
| `installer/Setup.exe` | Commercial WinForms installer | `f48f3698a5401a66869481c7cb615505067fd4f64699b87f484db6afdfd29b07` |
| `installer/TheGoldMindSetup.exe` | Same binary (branded name) | `f48f3698a5401a66869481c7cb615505067fd4f64699b87f484db6afdfd29b07` |
| `TGM_PROFESSIONAL_1.0.0_stable.zip` | Customer ZIP (installer + payload) | `e61120628ba0d43d9d0f84d931cb0cd863890fa95a0e997b04d13a951d83229a` |
| `SHA256SUMS.txt` | Checksums | — |
| `VERSION_MANIFEST.json` | Version / Core / artifact manifest | — |
| `SBOM.json` | Software bill of materials | — |
| `RELEASE_NOTES.md` | Customer release notes | — |
| `github-assets/` | Mirror for GitHub Release upload | — |

Portal mirror: `Commercial/CustomerPortal/web/public/releases/TGM_PROFESSIONAL_1.0.0_stable.zip` (identical SHA).  
Catalog seed: `public/releases/latest-stable.json` (`rel_100_stable`, signature **Code signing pending**).

---

## Core / EA

| Item | Value |
|------|-------|
| EX5 | `TheGoldMindAI_Professional.ex5` |
| EX5 size | 251018 |
| EX5 SHA-256 | `890e22254ef44f86e82bc3700cd2b0dd0eaddf57c3ce91ff0f801b999c347535` |
| mq5 SHA-256 (gate) | `9fd202466a0894577f12721610b4a9a80f6f8d02bb9fd908aed3d3e88654d49a` |
| Trading Engine | FROZEN |
| AI | Phase 11E dynamic pre-activation supervisor (Owner-approved actions only) |

---

## Installer commercial capabilities

- Standard installation wizard + progress UI  
- Desktop shortcut + Start Menu shortcut  
- Programs & Features uninstall via launcher `/uninstall`  
- Version detection / repair / update / uninstall paths  
- Automatic MT5 detection  
- Automatic Experts (and supporting Images/Presets) installation  
- License activation + portal/MT5 launch actions from WinForms shell  
- Helper scripts execute **hidden** (no customer-facing PowerShell/CMD windows)  
- Post-install / first-run guidance in payload docs  

Validation: **Validate-Installer PASSED** (`-SkipActivation`).

---

## Customer delivery path

1. Authenticated portal → Downloads / Updates  
2. `GET /api/releases/download/rel_100_stable` (auth + license entitlement)  
3. Extract ZIP → run `Setup.exe`  
4. Activate with license email/key  
5. Confirm EA under MT5 Navigator → The Gold Mind  

Public static `/releases/*` is **not** the customer download advertisement path.

---

## Support documentation package

Under `Commercial/Documentation/`:

- Installation / First-run / Release package guides  
- Customer support / recovery / admin operational docs  
- Phase 11E AI policy documentation (under Guides)  
- This commercial release report set  

---

## Go-live gate

Internal packaging and portal RC work is complete.

**Must complete before open commercial sales:** all items in `OWNER_ACTION_REQUIRED.md` (code signing, Paddle live, Resend DNS, domain DNS, production env, Google OAuth, legal, Upstash, admin allow-lists, SmartScreen).

---

## Release identity stamp

```
product: THE GOLD MIND PROFESSIONAL
version: 1.0.0
channel: stable
build: 26211
zip_sha256: e61120628ba0d43d9d0f84d931cb0cd863890fa95a0e997b04d13a951d83229a
setup_sha256: f48f3698a5401a66869481c7cb615505067fd4f64699b87f484db6afdfd29b07
ex5_sha256: 890e22254ef44f86e82bc3700cd2b0dd0eaddf57c3ce91ff0f801b999c347535
sign_status: pending_code_sign
```
