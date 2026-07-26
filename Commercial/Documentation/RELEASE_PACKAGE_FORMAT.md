# RELEASE_PACKAGE_FORMAT.md

**Phase:** 9 · Sprint 5  
**Artifact builder:** `CustomerPortal/web/src/server/releases/package-artifact.ts`  
**On-disk:** `.data/releases/artifacts/{packageId}.zip`

---

## Channels & manifests

| Channel | Disk manifest | Portal seed id |
|---------|---------------|----------------|
| Stable | `manifest.stable.json` | `rel_200_stable` |
| RC | `manifest.rc.json` | `rel_201_rc` |
| Development | `manifest.development.json` | `rel_dev_nightly` |

---

## ZIP layout (commercial shell)

```
bin/TGM-Professional-Launcher.cmd
bin/VERSION.txt
config/package-manifest.json
README.txt
```

SHA-256 of the **entire ZIP bytes** is stored on the release record and returned by check/download APIs.  
`ensurePackageArtifact()` regenerates invalid placeholders and keeps catalog hash/size in sync.

---

## Version metadata fields

| Field | Meaning |
|-------|---------|
| `version` | Semver (+ `-rc.N` / `-dev`) |
| `buildNumber` | Monotonic build id |
| `channel` | stable \| rc \| development |
| `releasedAt` | ISO timestamp |
| `packageFile` | Download filename |
| `packageSizeBytes` | Exact artifact size |
| `sha256` | Hex digest of ZIP |
| `signature*` | Authenticode policy / status / subject |
| `compatibility` | OS · MT5 · coreTag · coreFrozen |
| `releaseNotes` | Customer-facing notes |

---

## Compatibility matrix

Exposed on Downloads + Admin Release dashboard.  
`coreFrozen: true` means this commercial package **must not** alter Trading Engine behavior without executive approval.

---

## Serving

`GET /api/releases/download/[id]`

Headers: `X-TGM-SHA256` · `X-TGM-Signature-Status` · `X-TGM-Channel` · `X-TGM-Version` · `X-TGM-Build`  
Production: HTTPS required (`x-forwarded-proto`).

---

*End of RELEASE_PACKAGE_FORMAT.md*
