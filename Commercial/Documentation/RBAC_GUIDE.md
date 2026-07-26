# RBAC_GUIDE.md

Builtin roles: Owner · Organization Admin · Finance Manager · Operations Manager · Support Manager · Trader · Read-Only Auditor.

Custom roles supported per organization.

## Roles loaded for demo

- **Owner** (`owner`) builtin=true · perms=org.manage, org.members, org.roles, org.billing, org.licenses, org.support, org.audit, org.read
- **Organization Admin** (`org_admin`) builtin=true · perms=org.manage, org.members, org.roles, org.licenses, org.support, org.audit, org.read
- **Finance Manager** (`finance_manager`) builtin=true · perms=org.billing, org.read, org.audit
- **Operations Manager** (`operations_manager`) builtin=true · perms=org.licenses, org.members, org.read, org.support
- **Support Manager** (`support_manager`) builtin=true · perms=org.support, org.read, org.members
- **Trader** (`trader`) builtin=true · perms=org.read
- **Read-Only Auditor** (`read_only_auditor`) builtin=true · perms=org.read, org.audit
- **Desk Lead** (`desk_lead`) builtin=false · perms=org.licenses, org.members, org.read
