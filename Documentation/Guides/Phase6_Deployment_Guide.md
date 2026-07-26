# Phase 6 — Deployment Guide

**Module:** `Include/Cloud/Deployment/` · Facade `CGmEnterpriseDeploymentEngine`

## Lifecycle

1. Detect update availability  
2. Background download + integrity / signature checks  
3. Schedule install  
4. **Defer** if Gold Mind–managed positions are open  
5. Promote Dev → Test → Staging → Production  
6. Rollback framework + backup restore hooks  

## Hard rule

Updates must never interrupt active trading or H4 execution.
