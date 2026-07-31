/**
 * Organization accounts — multi-admin, departments, members, settings.
 */
import type { Department, OrgMember, Organization } from "./types";
import {
  mutateEnterpriseStore,
  newId,
  readEnterpriseStore,
} from "./store";
import { isProductionRuntime } from "@/server/security/dev-bypass";

export function registerOrganization(input: {
  name: string;
  legalName?: string;
  domain?: string;
  country?: string;
  region?: string;
  ownerEmail: string;
  ownerName: string;
  actor: string;
}): Organization {
  let org: Organization | null = null;
  mutateEnterpriseStore((d) => {
    org = {
      id: newId("org"),
      name: input.name,
      legalName: input.legalName,
      domain: input.domain,
      country: input.country,
      region: input.region,
      status: "trial",
      settings: {
        seatLimit: d.config.defaultSeatLimit,
        allowLicenseTransfer: d.config.licensing.allowTransfer,
        requirePoOnInvoice: false,
      },
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    };
    d.organizations.unshift(org);
    d.members.unshift({
      id: newId("mem"),
      orgId: org.id,
      email: input.ownerEmail.toLowerCase(),
      name: input.ownerName,
      roleId: "owner",
      status: "active",
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    });
    d.contacts.unshift({
      id: newId("ctc"),
      orgId: org.id,
      email: input.ownerEmail.toLowerCase(),
      name: input.ownerName,
      role: "primary",
      createdAt: new Date().toISOString(),
    });
    d.audit.unshift({
      id: newId("eaud"),
      orgId: org.id,
      at: new Date().toISOString(),
      actor: input.actor,
      action: "org_register",
      detail: org.name,
      immutable: true,
    });
  });
  return org!;
}

export function updateOrganizationSettings(
  orgId: string,
  patch: Partial<Organization["settings"]> & { name?: string; status?: Organization["status"] },
  actor: string
): void {
  mutateEnterpriseStore((d) => {
    const org = d.organizations.find((o) => o.id === orgId);
    if (!org) throw new Error("ORG_NOT_FOUND");
    if (patch.name) org.name = patch.name;
    if (patch.status) org.status = patch.status;
    org.settings = { ...org.settings, ...patch };
    org.updatedAt = new Date().toISOString();
    d.audit.unshift({
      id: newId("eaud"),
      orgId,
      at: new Date().toISOString(),
      actor,
      action: "org_settings",
      detail: JSON.stringify(patch),
      immutable: true,
    });
  });
}

export function addDepartment(orgId: string, name: string, actor: string): Department {
  let dep: Department | null = null;
  mutateEnterpriseStore((d) => {
    if (!d.organizations.some((o) => o.id === orgId)) throw new Error("ORG_NOT_FOUND");
    dep = {
      id: newId("dep"),
      orgId,
      name,
      createdAt: new Date().toISOString(),
    };
    d.departments.unshift(dep);
    d.audit.unshift({
      id: newId("eaud"),
      orgId,
      at: new Date().toISOString(),
      actor,
      action: "department_add",
      detail: name,
      immutable: true,
    });
  });
  return dep!;
}

export function addOrgMember(input: {
  orgId: string;
  email: string;
  name: string;
  roleId: string;
  departmentId?: string;
  actor: string;
}): OrgMember {
  let mem: OrgMember | null = null;
  mutateEnterpriseStore((d) => {
    if (!d.organizations.some((o) => o.id === input.orgId)) throw new Error("ORG_NOT_FOUND");
    const email = input.email.toLowerCase();
    if (d.members.some((m) => m.orgId === input.orgId && m.email === email)) {
      throw new Error("MEMBER_EXISTS");
    }
    mem = {
      id: newId("mem"),
      orgId: input.orgId,
      email,
      name: input.name,
      roleId: input.roleId,
      departmentId: input.departmentId,
      status: "invited",
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    };
    d.members.unshift(mem);
    d.audit.unshift({
      id: newId("eaud"),
      orgId: input.orgId,
      at: new Date().toISOString(),
      actor: input.actor,
      action: "member_add",
      detail: `${email} role=${input.roleId}`,
      immutable: true,
    });
  });
  return mem!;
}

export function assignMemberRole(orgId: string, memberId: string, roleId: string, actor: string): void {
  mutateEnterpriseStore((d) => {
    const m = d.members.find((x) => x.id === memberId);
    if (!m || m.orgId !== orgId) throw new Error("MEMBER_NOT_FOUND");
    const prev = m.roleId;
    m.roleId = roleId;
    m.updatedAt = new Date().toISOString();
    d.audit.unshift({
      id: newId("eaud"),
      orgId,
      at: new Date().toISOString(),
      actor,
      action: "role_change",
      detail: `${memberId} ${prev}→${roleId}`,
      immutable: true,
    });
  });
}

export function listOrgActivity(orgId: string, limit = 50) {
  return readEnterpriseStore()
    .audit.filter((a) => a.orgId === orgId)
    .slice(0, limit);
}

export function getOrganization(orgId: string): Organization | undefined {
  return readEnterpriseStore().organizations.find((o) => o.id === orgId);
}

export function ensureDemoOrganization(): Organization {
  if (isProductionRuntime() && process.env.PORTAL_ALLOW_DEMO_SEED !== "true") {
    const store = readEnterpriseStore();
    const existing =
      store.organizations.find((o) => o.domain === "goldmind-enterprise.local") || store.organizations[0];
    if (existing) return existing;
    throw new Error("ENTERPRISE_DEMO_SEED_DISABLED");
  }
  const store = readEnterpriseStore();
  const existing = store.organizations.find((o) => o.domain === "goldmind-enterprise.local");
  if (existing) return existing;
  return registerOrganization({
    name: "Gold Mind Enterprise Demo",
    legalName: "Gold Mind Enterprise Demo LLC",
    domain: "goldmind-enterprise.local",
    country: "AE",
    region: "EMEA",
    ownerEmail: "owner@goldmind-enterprise.local",
    ownerName: "Enterprise Owner",
    actor: "system",
  });
}
