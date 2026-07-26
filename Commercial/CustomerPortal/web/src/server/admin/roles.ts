/**
 * Enterprise Admin RBAC — commercial operations only.
 * Never grants Trading Engine access.
 */

export type AdminRole =
  | "super_admin"
  | "commercial_manager"
  | "support_agent"
  | "finance_manager"
  | "qa_manager"
  | "auditor"
  | "admin" // legacy alias → treated as super_admin
  | "support" // legacy alias → support_agent
  | "customer";

export type AdminPermission =
  | "admin.dashboard"
  | "admin.customers.read"
  | "admin.customers.write"
  | "admin.licenses.read"
  | "admin.licenses.write"
  | "admin.subscriptions.read"
  | "admin.billing.read"
  | "admin.billing.write"
  | "admin.support.read"
  | "admin.support.write"
  | "admin.releases.read"
  | "admin.releases.write"
  | "admin.bi.read"
  | "admin.audit.read"
  | "admin.audit.export"
  | "admin.cloud.read"
  | "admin.security.manage"
  | "admin.roles.manage"
  | "admin.launch.read"
  | "admin.launch.write"
  | "admin.observability.read"
  | "admin.observability.write";

const ALL: AdminPermission[] = [
  "admin.dashboard",
  "admin.customers.read",
  "admin.customers.write",
  "admin.licenses.read",
  "admin.licenses.write",
  "admin.subscriptions.read",
  "admin.billing.read",
  "admin.billing.write",
  "admin.support.read",
  "admin.support.write",
  "admin.releases.read",
  "admin.releases.write",
  "admin.bi.read",
  "admin.audit.read",
  "admin.audit.export",
  "admin.cloud.read",
  "admin.security.manage",
  "admin.roles.manage",
  "admin.launch.read",
  "admin.launch.write",
  "admin.observability.read",
  "admin.observability.write",
];

export const ROLE_PERMISSIONS: Record<string, AdminPermission[]> = {
  super_admin: ALL,
  admin: ALL,
  commercial_manager: [
    "admin.dashboard",
    "admin.customers.read",
    "admin.customers.write",
    "admin.licenses.read",
    "admin.licenses.write",
    "admin.subscriptions.read",
    "admin.billing.read",
    "admin.releases.read",
    "admin.bi.read",
    "admin.audit.read",
    "admin.launch.read",
    "admin.launch.write",
    "admin.observability.read",
  ],
  support_agent: [
    "admin.dashboard",
    "admin.customers.read",
    "admin.licenses.read",
    "admin.support.read",
    "admin.support.write",
    "admin.audit.read",
    "admin.launch.read",
    "admin.observability.read",
  ],
  support: [
    "admin.dashboard",
    "admin.customers.read",
    "admin.licenses.read",
    "admin.support.read",
    "admin.support.write",
    "admin.audit.read",
    "admin.launch.read",
    "admin.observability.read",
  ],
  finance_manager: [
    "admin.dashboard",
    "admin.customers.read",
    "admin.subscriptions.read",
    "admin.billing.read",
    "admin.billing.write",
    "admin.bi.read",
    "admin.audit.read",
    "admin.audit.export",
    "admin.launch.read",
    "admin.observability.read",
  ],
  qa_manager: [
    "admin.dashboard",
    "admin.releases.read",
    "admin.releases.write",
    "admin.cloud.read",
    "admin.audit.read",
    "admin.bi.read",
    "admin.launch.read",
    "admin.launch.write",
    "admin.observability.read",
    "admin.observability.write",
  ],
  auditor: [
    "admin.dashboard",
    "admin.customers.read",
    "admin.licenses.read",
    "admin.subscriptions.read",
    "admin.billing.read",
    "admin.support.read",
    "admin.releases.read",
    "admin.bi.read",
    "admin.audit.read",
    "admin.audit.export",
    "admin.cloud.read",
    "admin.launch.read",
    "admin.observability.read",
  ],
  customer: [],
};

export function normalizeAdminRole(role?: string): AdminRole {
  if (!role) return "customer";
  if (role === "admin") return "super_admin";
  if (role === "support") return "support_agent";
  return role as AdminRole;
}

export function hasPermission(role: string | undefined, permission: AdminPermission): boolean {
  const r = normalizeAdminRole(role);
  return (ROLE_PERMISSIONS[r] || []).includes(permission);
}

export function listPermissions(role: string | undefined): AdminPermission[] {
  return ROLE_PERMISSIONS[normalizeAdminRole(role)] || [];
}

export function canAccessAdminConsole(role: string | undefined): boolean {
  return listPermissions(role).length > 0;
}

export const ROLE_LABELS: Record<string, string> = {
  super_admin: "Super Administrator",
  admin: "Super Administrator",
  commercial_manager: "Commercial Manager",
  support_agent: "Support Agent",
  support: "Support Agent",
  finance_manager: "Finance Manager",
  qa_manager: "QA Manager",
  auditor: "Read-only Auditor",
  customer: "Customer",
};

export function getRolePermissionMatrix() {
  const roles = [
    "super_admin",
    "commercial_manager",
    "support_agent",
    "finance_manager",
    "qa_manager",
    "auditor",
  ] as const;
  return roles.map((role) => ({
    role,
    label: ROLE_LABELS[role],
    permissions: ROLE_PERMISSIONS[role],
  }));
}
