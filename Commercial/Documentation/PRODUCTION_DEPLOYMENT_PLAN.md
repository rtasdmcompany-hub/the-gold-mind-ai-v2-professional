# PRODUCTION_DEPLOYMENT_PLAN.md

**Phase:** 9 · Sprint 9 · RC-2  
**Candidate:** `2.0.0-rc.2`

---

## Repository & branching (recommended)

| Item | Policy |
|------|--------|
| Default branch | `main` (production tags only) |
| Integration | `develop` / `release/rc-2` |
| Hotfix | `hotfix/*` from tag |
| Commercial code | `Commercial/**` only for portal/installer |
| Core | **read-only** — no commits without Owner waiver |

> Workspace note: current tree is not a git repository on this machine. Initialize remote GitHub and apply this strategy before production cutover.

---

## Release tags

| Tag | Meaning |
|-----|---------|
| `v2.0.0-rc.2` | This candidate |
| `v2.0.0` | Future Stable (after Authenticode + legal + live PSP) |

---

## Version numbers

| Surface | Value |
|---------|-------|
| Product | 2.0.0-rc.2 |
| Build | 21082 |
| Portal npm | 0.5.0 |
| Core cert | SHA-256 in `RC2_CORE_CERTIFICATION.txt` |

---

## Build artifacts

| Artifact | Source | Deploy target |
|----------|--------|---------------|
| Portal | `npm run build` | HTTPS host / container |
| Installer scripts | `Installer/Professional` | Downloads CDN / portal |
| Release ZIPs | portal release artifacts | `/api/releases/download` |
| Core EA | certified `.mq5` | Website package / Market package |
| Docs | `Documentation/` + `Releases/RC-2/` | Internal + portal KB |

---

## Deployment packages

1. **Portal image/bundle** — Node 20+ · env secrets · HTTPS  
2. **Installer pack** — zip of scripts + manifests  
3. **Update channel RC** — publish `2.0.0-rc.2` to rc channel  
4. **Rollback package** — previous portal build + previous installer zip retained in `Releases/`  

---

## Release archive

`Commercial/Releases/RC-2/` — VERSION · NOTES · MANIFEST retained permanently.

---

## Rollback procedure

1. Portal: redeploy previous image/tag  
2. Updater clients: fail-closed keeps prior local version automatically  
3. Billing/licensing stores: restore from encrypted backup per `DATABASE_SECURITY.md`  
4. Never rollback by modifying Core binaries  

---

## Production env checklist

- [ ] `NEXTAUTH_SECRET` / store secrets rotated  
- [ ] `UPDATE_REPORT_SECRET` set  
- [ ] PSP webhook secrets live  
- [ ] `ENFORCE_HTTPS=true`  
- [ ] Upstash Redis (recommended)  
- [ ] Admin email allow-lists  

---

*End of PRODUCTION_DEPLOYMENT_PLAN.md*
