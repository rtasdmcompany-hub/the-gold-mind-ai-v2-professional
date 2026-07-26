/**
 * Partner program types — commercial affiliate / reseller ecosystem.
 */
export type PartnerTierId =
  | "registered"
  | "silver"
  | "gold"
  | "platinum"
  | "enterprise";

export type PartnerStatus =
  | "pending"
  | "approved"
  | "verified"
  | "suspended"
  | "rejected"
  | "inactive";

export type ApplicationStatus = "submitted" | "under_review" | "approved" | "rejected";

export type ContractStatus = "none" | "sent" | "signed" | "expired";

export type CommissionType = "fixed" | "percentage" | "recurring" | "one_time" | "bonus";

export type CommissionStatus =
  | "pending_attribution"
  | "pending_approval"
  | "approved"
  | "paid"
  | "clawed_back"
  | "rejected";

export type PayoutStatus = "requested" | "approved" | "paid" | "rejected";

export type DisputeStatus = "open" | "investigating" | "resolved" | "closed";

export interface TierRule {
  id: PartnerTierId;
  label: string;
  minQualifiedSales: number;
  minRevenueCents: number;
  commissionBoostBps: number; // basis points added to percentage commissions
  description: string;
}

export interface CommissionRuleConfig {
  id: string;
  label: string;
  type: CommissionType;
  /** percentage in basis points (e.g. 1500 = 15%) or fixed cents for fixed/one_time/bonus */
  value: number;
  recurringMonths?: number;
  planCodes?: string[];
  campaignId?: string;
  active: boolean;
  requiresApproval: boolean;
  notes: string;
}

export interface AttributionPolicy {
  cookieDays: number;
  lastClickWins: boolean;
  requireVerifiedConversion: boolean;
  blockSelfReferral: boolean;
}

export interface PartnerProgramConfig {
  version: 1;
  currency: "USD";
  attribution: AttributionPolicy;
  tiers: TierRule[];
  commissionRules: CommissionRuleConfig[];
  minPayoutCents: number;
  approvalWorkflow: string[];
}

export interface PartnerProfile {
  id: string;
  email: string;
  name: string;
  company?: string;
  region?: string;
  country?: string;
  tier: PartnerTierId;
  status: PartnerStatus;
  referralCode: string;
  contractStatus: ContractStatus;
  createdAt: string;
  updatedAt: string;
  verifiedAt?: string;
  suspendedAt?: string;
  suspensionReason?: string;
}

export interface PartnerApplication {
  id: string;
  email: string;
  name: string;
  company?: string;
  region?: string;
  country?: string;
  website?: string;
  pitch: string;
  status: ApplicationStatus;
  createdAt: string;
  reviewedAt?: string;
  reviewer?: string;
  notes?: string;
}

export interface ReferralClick {
  id: string;
  partnerId: string;
  referralCode: string;
  campaignId?: string;
  visitorHash: string;
  landingPath: string;
  at: string;
  ipHash?: string;
}

export interface AttributionEvent {
  id: string;
  partnerId: string;
  referralCode: string;
  visitorHash: string;
  customerEmail?: string;
  type: "registration" | "conversion" | "sale";
  paymentId?: string;
  amountCents?: number;
  planCode?: string;
  clickId?: string;
  verified: boolean;
  at: string;
  detail: string;
}

export interface CommissionLedgerEntry {
  id: string;
  partnerId: string;
  attributionId: string;
  ruleId: string;
  type: CommissionType;
  amountCents: number;
  currency: "USD";
  status: CommissionStatus;
  saleAmountCents?: number;
  createdAt: string;
  approvedAt?: string;
  approvedBy?: string;
  paidAt?: string;
  clawbackReason?: string;
  auditNote: string;
}

export interface PartnerPayoutRequest {
  id: string;
  partnerId: string;
  amountCents: number;
  status: PayoutStatus;
  commissionIds: string[];
  requestedAt: string;
  processedAt?: string;
  processor?: string;
  detail?: string;
}

export interface PartnerDispute {
  id: string;
  partnerId: string;
  commissionId?: string;
  subject: string;
  status: DisputeStatus;
  createdAt: string;
  updatedAt: string;
  resolution?: string;
}

export interface PartnerCampaign {
  id: string;
  name: string;
  type: "bonus" | "promotional";
  ruleId: string;
  startsAt: string;
  endsAt: string;
  active: boolean;
  description: string;
}
