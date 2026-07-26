# Phase 7 — Handover Package

**From:** Phase 6 Sprint 10 (build 21050)  
**Freeze:** `GM_PHASE6_INFRASTRUCTURE_FROZEN`

## Infrastructure freeze

All `Include/Cloud/**` platforms (Sprints 1–9) are frozen. Extend beside them; do not rewrite.

## Dependency graph

```
Cloud Core
  └─ Remote Monitor / Telemetry
       └─ Notifications / Mobile API
            └─ Infrastructure (VPS / Multi-Terminal / Control)
                 └─ Identity / License
                      └─ Backup / DR / Continuity
                           └─ Audit / Compliance
                                └─ API Gateway / Integration Hub
                                     └─ Deployment / Release
                                          └─ Phase 6 Closure / Certification
```

Timer path only: `CApplication::OnTimer` → each facade `Process` → dashboard publish.

## Service registry (facades)

| Service | Class | Member |
|---------|-------|--------|
| Cloud | `CGmEnterpriseCloudEngine` | `m_cloud` |
| Remote | `CGmEnterpriseRemoteMonitorEngine` | `m_remote` |
| Notify | `CGmEnterpriseNotificationEngine` | `m_notify_center` |
| Infra | `CGmEnterpriseInfrastructureEngine` | `m_infra` |
| Identity | `CGmEnterpriseIdentityEngine` | `m_identity` |
| Backup | `CGmEnterpriseBackupEngine` | `m_backup` |
| Audit | `CGmEnterpriseAuditEngine` | `m_audit` |
| API | `CGmEnterpriseApiGatewayEngine` | `m_api` |
| Deploy | `CGmEnterpriseDeploymentEngine` | `m_deploy` |
| Closure | `CGmPhase6ClosureEngine` | `m_phase6_closure` |

## Database schemas

`GM_CLOUD_*` · `GM_CLOUD_RM_*` · `GM_CLOUD_ENC_*` · `GM_CLOUD_EIF_*` · `GM_CLOUD_ELM_*` · `GM_CLOUD_BDR_*` · `GM_CLOUD_EAC_*` · `GM_CLOUD_EAP_*` · `GM_CLOUD_EDP_*` · `GM_PHASE6_*` reports

## Extension rule

New Phase 7 modules must:

1. Live in a new folder (e.g. `Include/Cloud/<NewService>/` or approved Phase 7 root)  
2. Bind observe-only to frozen facades  
3. Never call trade/risk/order modification APIs  
4. Run on timer / background path only
