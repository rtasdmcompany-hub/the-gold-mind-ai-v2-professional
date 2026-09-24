import type { 
  LicenseRecord, 
  DeviceRecord, 
  SubscriptionRecord as LicenseSubscriptionRecord
} from "@/server/licensing/types";

import type { 
  BillingSubscriptionRecord, 
  InvoiceRecord, 
  PaymentRecord 
} from "@/server/billing/types";

import type { SupportTicket } from "./support-store";
import type { AuditEntry } from "@/server/cloud/types";

export interface BusinessIntelligence {
  revenueTrends: { month: string; cents: number; formatted: string }[];
  subscriptionGrowth: { active: number; billingSubs: number };
  customerRetention: number;
  activationRate: number;
  renewalRate: number;
  refundStatistics: { count: number; cents: number };
  supportPerformance: { resolvedRate: number; open: number; total: number };
  productAdoption: {
    downloads: number;
    updateSuccessRate: number;
    licensesByType: { trial: number; monthly: number; yearly: number; lifetime: number };
  };
}

export interface CustomerProfile {
  email: string;
  name: string;
  accountStatus: "active" | "suspended";
  licenses: LicenseRecord[];
  devices: DeviceRecord[];
  subscriptions: BillingSubscriptionRecord[];
  entitlements: LicenseSubscriptionRecord[];
  orders: PaymentRecord[];
  invoices: InvoiceRecord[];
  supportHistory: SupportTicket[];
  audit: AuditEntry[];
}

export interface LicenseAdminView {
  licenses: LicenseRecord[];
  activationHistory: LicenseRecord[];
  expirationMonitoring: LicenseRecord[];
  renewalQueue: { licenseId: string; email: string; type: string; expiresAt: string | null }[];
  counts: { trial: number; lifetime: number; monthly: number; yearly: number; total: number };
}

export interface SearchCustomerResult {
  email: string;
  name: string;
  licenseCount: number;
  deviceCount: number;
  accountStatus: "active" | "suspended" | "unknown";
  lastOrderAt?: string;
}