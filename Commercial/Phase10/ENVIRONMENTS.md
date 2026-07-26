# Launch environments — deployment rules index

Canonical definitions live in the portal:

`Commercial/CustomerPortal/web/src/server/launch/environments.ts`

| ID | Name | Customer access | Payments |
|----|------|-----------------|----------|
| development | Development | none | sandbox |
| internal_qa | Internal QA | internal | sandbox |
| staging | Staging | internal | sandbox |
| production | Production | invite_only | live |
| controlled_beta | Controlled Beta | invite_only | live |
| public_stable | Future Public Stable | public | live (blocked) |

See also: `Commercial/Documentation/CONTROLLED_LAUNCH_PLAN.md`
