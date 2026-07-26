# RELEASE_MANAGEMENT.md

**Phase:** 9 · Sprint 5  
**Admin UI:** `/portal/admin/releases`  
**API:** `GET /api/admin/releases`  
**Engine:** `src/server/releases/`

---

## Dashboard panels

| Panel | Data |
|-------|------|
| Latest Release | version · build · date · status |
| Previous Releases | catalog minus latest stable |
| Package Size | bytes / formatted |
| Build Number | per package |
| Release Date | `releasedAt` |
| Release Status | draft / published / yanked / superseded |
| Download Count | per package + total |
| Update Success Rate | success / (success+fail) |
| Rollback Events | count + event log |
| Compatibility Matrix | OS · MT5 · coreTag · frozen |

---

## Customer portal surfaces

| Route | Content |
|-------|---------|
| `/portal/downloads` | Latest · installed (telemetry) · download · notes · checksum · signature · history · matrix |
| `/portal/updates` | Channel switch · version check · notes · download · apply instructions |

---

## Channels

- **Stable** — production  
- **Release Candidate (`rc`)** — pre-prod  
- **Development** — internal  

---

## Metrics source

Updater POSTs to `/api/releases/report` after success / fail / rollback.  
Without telemetry, success rate remains vacuously 100% (no attempts).

---

## Governance

Commercial release packaging **must not** alter Core Trading Engine behavior without Owner/executive approval and an explicit Core tag change process.

---

*End of RELEASE_MANAGEMENT.md*
