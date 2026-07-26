/**
 * Enterprise CRM / org types — multi-tenant commercial layer only.
 */
export type OrgStatus = "active" | "trial" | "suspended" | "churned";
export type LeadStatus = "new" | "qualified" | "won" | "lost";
export type CrmContactRole = "primary" | "billing" | "technical" | "executive" | "other";

export type EnterprisePermission =
  | "org.manage"
  | "org.members"
  | "org.roles"
  | "org.billing"
  | "org.licenses"
  | "org.support"
  | "org.audit"
  | "org.read";

export type BuiltinEnterpriseRoleId =
  | "owner"
  | "org_admin"
  | "finance_manager"
  | "operations_manager"
  | "support_manager"
  | "trader"
  | "read_only_auditor";

export interface EnterpriseRoleDef {
  id: string;
  label: string;
  permissions: EnterprisePermission[];
  builtin: boolean;
  orgId?: string; // custom roles scoped to org
}

export interface Organization {
  id: string;
  name: string;
  legalName?: string;
  domain?: string;
  country?: string;
  region?: string;
  status: OrgStatus;
  settings: {
    seatLimit: number;
    allowLicenseTransfer: boolean;
    requirePoOnInvoice: boolean;
  };
  createdAt: string;
  updatedAt: string;
}

export interface Department {
  id: string;
  orgId: string;
  name: string;
  createdAt: string;
}

export interface OrgMember {
  id: string;
  orgId: string;
  email: string;
  name: string;
  roleId: string;
  departmentId?: string;
  status: "active" | "invited" | "disabled";
  createdAt: string;
  updatedAt: string;
}

export interface CrmContact {
  id: string;
  orgId: string;
  email: string;
  name: string;
  role: CrmContactRole;
  phone?: string;
  createdAt: string;
}

export interface CrmLead {
  id: string;
  company: string;
  contactEmail: string;
  contactName: string;
  status: LeadStatus;
  source?: string;
  orgId?: string;
  createdAt: string;
  updatedAt: string;
}

export interface SeatLicense {
  id: string;
  orgId: string;
  poolId: string;
  seatIndex: number;
  assignedMemberId?: string;
  assignedEmail?: string;
  status: "available" | "assigned" | "revoked" | "disabled";
  createdAt: string;
  updatedAt: string;
}

export interface LicensePool {
  id: string;
  orgId: string;
  name: string;
  planCode: string;
  totalSeats: number;
  subscriptionId?: string;
  status: "active" | "expired" | "suspended";
  createdAt: string;
  updatedAt: string;
}

export interface OrgSubscription {
  id: string;
  orgId: string;
  planCode: string;
  status: "trialing" | "active" | "past_due" | "cancelled" | "expired";
  seats: number;
  amountCents: number;
  renewalDate?: string;
  createdAt: string;
  updatedAt: string;
}

export interface OrgInvoice {
  id: string;
  orgId: string;
  subscriptionId?: string;
  amountCents: number;
  status: "open" | "paid" | "void" | "refunded";
  poNumber?: string;
  billingContactEmail?: string;
  createdAt: string;
  paidAt?: string;
}

export interface PurchaseOrder {
  id: string;
  orgId: string;
  poNumber: string;
  amountCents: number;
  status: "open" | "matched" | "closed";
  createdAt: string;
}

export interface EnterpriseAuditEntry {
  id: string;
  orgId: string;
  at: string;
  actor: string;
  action: string;
  detail: string;
  /** Immutable once written — store never mutates existing rows */
  immutable: true;
}

export interface LicenseAuditEntry {
  id: string;
  orgId: string;
  poolId: string;
  seatId?: string;
  at: string;
  actor: string;
  action:
    | "assign"
    | "revoke"
    | "transfer"
    | "bulk_activate"
    | "bulk_deactivate"
    | "pool_create"
    | "pool_resize";
  detail: string;
}

export interface EnterpriseConfig {
  version: 1;
  defaultSeatLimit: number;
  builtinRoles: EnterpriseRoleDef[];
  /** Licensing policy — configurable without Core changes */
  licensing: {
    allowTransfer: boolean;
    allowBulkOps: boolean;
    maxSeatsPerPool: number;
  };
}
