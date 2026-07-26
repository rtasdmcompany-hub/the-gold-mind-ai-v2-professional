/**
 * Configurable enterprise RBAC + licensing policy (not Core).
 */
import type { EnterpriseConfig, EnterprisePermission, EnterpriseRoleDef } from "./types";

const ALL: EnterprisePermission[] = [
  "org.manage",
  "org.members",
  "org.roles",
  "org.billing",
  "org.licenses",
  "org.support",
  "org.audit",
  "org.read",
];

export const DEFAULT_ENTERPRISE_CONFIG: EnterpriseConfig = {
  version: 1,
  defaultSeatLimit: 10,
  licensing: {
    allowTransfer: true,
    allowBulkOps: true,
    maxSeatsPerPool: 500,
  },
  builtinRoles: [
    { id: "owner", label: "Owner", permissions: ALL, builtin: true },
    {
      id: "org_admin",
      label: "Organization Admin",
      permissions: ["org.manage", "org.members", "org.roles", "org.licenses", "org.support", "org.audit", "org.read"],
      builtin: true,
    },
    {
      id: "finance_manager",
      label: "Finance Manager",
      permissions: ["org.billing", "org.read", "org.audit"],
      builtin: true,
    },
    {
      id: "operations_manager",
      label: "Operations Manager",
      permissions: ["org.licenses", "org.members", "org.read", "org.support"],
      builtin: true,
    },
    {
      id: "support_manager",
      label: "Support Manager",
      permissions: ["org.support", "org.read", "org.members"],
      builtin: true,
    },
    {
      id: "trader",
      label: "Trader",
      permissions: ["org.read"],
      builtin: true,
    },
    {
      id: "read_only_auditor",
      label: "Read-Only Auditor",
      permissions: ["org.read", "org.audit"],
      builtin: true,
    },
  ],
};

export function roleHasPermission(role: EnterpriseRoleDef | undefined, perm: EnterprisePermission): boolean {
  if (!role) return false;
  return role.permissions.includes(perm);
}
