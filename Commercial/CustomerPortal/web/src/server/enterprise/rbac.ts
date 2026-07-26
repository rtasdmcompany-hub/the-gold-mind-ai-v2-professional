/**
 * Enterprise RBAC — builtin + custom org-scoped roles.
 */
import type { EnterprisePermission, EnterpriseRoleDef } from "./types";
import { roleHasPermission } from "./config";
import { mutateEnterpriseStore, newId, readEnterpriseStore } from "./store";

export function listRolesForOrg(orgId: string): EnterpriseRoleDef[] {
  const store = readEnterpriseStore();
  return [
    ...store.config.builtinRoles,
    ...store.customRoles.filter((r) => r.orgId === orgId),
  ];
}

export function createCustomRole(input: {
  orgId: string;
  id: string;
  label: string;
  permissions: EnterprisePermission[];
  actor: string;
}): EnterpriseRoleDef {
  let role: EnterpriseRoleDef | null = null;
  mutateEnterpriseStore((d) => {
    if (d.config.builtinRoles.some((r) => r.id === input.id)) throw new Error("ROLE_ID_RESERVED");
    if (d.customRoles.some((r) => r.orgId === input.orgId && r.id === input.id)) {
      throw new Error("ROLE_EXISTS");
    }
    role = {
      id: input.id,
      label: input.label,
      permissions: input.permissions,
      builtin: false,
      orgId: input.orgId,
    };
    d.customRoles.unshift(role);
    d.audit.unshift({
      id: newId("eaud"),
      orgId: input.orgId,
      at: new Date().toISOString(),
      actor: input.actor,
      action: "custom_role_create",
      detail: input.id,
      immutable: true,
    });
  });
  return role!;
}

export function memberHasPermission(orgId: string, email: string, perm: EnterprisePermission): boolean {
  const store = readEnterpriseStore();
  const member = store.members.find(
    (m) => m.orgId === orgId && m.email === email.toLowerCase() && m.status === "active"
  );
  if (!member) return false;
  const role = listRolesForOrg(orgId).find((r) => r.id === member.roleId);
  return roleHasPermission(role, perm);
}

export function recordLogin(orgId: string, email: string, result: "success" | "denied"): void {
  mutateEnterpriseStore((d) => {
    d.logins.unshift({
      id: newId("login"),
      orgId,
      email: email.toLowerCase(),
      at: new Date().toISOString(),
      result,
    });
    d.audit.unshift({
      id: newId("eaud"),
      orgId,
      at: new Date().toISOString(),
      actor: email.toLowerCase(),
      action: "user_login",
      detail: result,
      immutable: true,
    });
  });
}
