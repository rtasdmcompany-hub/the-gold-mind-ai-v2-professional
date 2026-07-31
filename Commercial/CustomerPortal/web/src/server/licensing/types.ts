/**
 * THE GOLD MIND Licensing Engine — types
 * Commercial service only. Zero Core Trading Engine dependency.
 */

export type LicenseType = "trial" | "monthly" | "yearly" | "lifetime";

export type LicenseStatus =
  | "pending"
  | "active"
  | "grace"
  | "cancelled"
  | "expired"
  | "revoked";

export type SubscriptionStatus =
  | "trialing"
  | "active"
  | "grace"
  | "cancelled"
  | "expired"
  | "renewed";

export type DeviceStatus = "active" | "inactive" | "pending_transfer";

export type AuditAction =
  | "license.created"
  | "license.activated"
  | "license.validated"
  | "license.grace"
  | "license.expired"
  | "license.cancelled"
  | "license.renewed"
  | "device.registered"
  | "device.renamed"
  | "device.deactivated"
  | "device.transfer_requested"
  | "device.transfer_completed"
  | "subscription.updated"
  | "tamper.detected"
  | "admin.lookup";

export interface LicenseRecord {
  id: string;
  customerEmail: string;
  customerName: string;
  /** SHA-256 of full key — never return raw key after creation except once */
  keyHash: string;
  keyPrefix: string;
  /** Last segment only for masked display — never enough to reconstruct key */
  keyLast4: string;
  type: LicenseType;
  status: LicenseStatus;
  edition: string;
  seatsMax: number;
  createdAt: string;
  activatedAt: string | null;
  expiresAt: string | null;
  graceEndsAt: string | null;
  lastValidatedAt: string | null;
  /** HMAC of canonical license fields for tamper detection */
  integrityMac: string;
}

export interface DeviceRecord {
  id: string;
  licenseId: string;
  customerEmail: string;
  name: string;
  fingerprintHash: string;
  status: DeviceStatus;
  activationDate: string;
  lastActiveAt: string;
  transferRequestedAt: string | null;
}

export interface SubscriptionRecord {
  id: string;
  licenseId: string;
  customerEmail: string;
  plan: LicenseType;
  status: SubscriptionStatus;
  renewalDate: string | null;
  expirationDate: string | null;
  graceEndsAt: string | null;
  cancelledAt: string | null;
  renewedAt: string | null;
  /** Reserved for future upgrade/downgrade */
  pendingPlanChange: LicenseType | null;
}

export interface AuditEvent {
  id: string;
  at: string;
  actorEmail: string;
  action: AuditAction;
  entityType: "license" | "device" | "subscription" | "system";
  entityId: string;
  detail: string;
  meta?: Record<string, string>;
}

export interface LicenseStoreData {
  version: 1;
  licenses: LicenseRecord[];
  devices: DeviceRecord[];
  subscriptions: SubscriptionRecord[];
  audit: AuditEvent[];
}

/** Safe DTO — never includes keyHash or full key */
export interface LicensePublicDto {
  id: string;
  keyMasked: string;
  type: LicenseType;
  status: LicenseStatus;
  edition: string;
  seatsUsed: number;
  seatsMax: number;
  activatedAt: string | null;
  expiresAt: string | null;
  graceEndsAt: string | null;
  renewalStatus: string;
  lastValidatedAt: string | null;
}

export interface DevicePublicDto {
  id: string;
  licenseId: string;
  name: string;
  status: DeviceStatus;
  activationDate: string;
  lastActiveAt: string;
  transferRequestedAt: string | null;
  fingerprintMasked: string;
}

export interface SubscriptionPublicDto {
  id: string;
  licenseId: string;
  plan: LicenseType;
  status: SubscriptionStatus;
  renewalDate: string | null;
  expirationDate: string | null;
  graceEndsAt: string | null;
  cancelledAt: string | null;
  renewedAt: string | null;
  pendingPlanChange: LicenseType | null;
}
