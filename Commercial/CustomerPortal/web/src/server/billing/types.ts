/**
 * Website Edition billing — independent of Core Trading & MQL5 Market.
 */

export type PaymentProviderId = "paddle" | "paypal" | "stripe" | "sandbox";

export type PlanCode = "trial" | "monthly" | "yearly" | "lifetime";

export type NormalizedEventType =
  | "payment.succeeded"
  | "payment.failed"
  | "refund.created"
  | "subscription.created"
  | "subscription.renewed"
  | "subscription.cancelled"
  | "subscription.past_due"
  | "dispute.opened";

export interface CheckoutRequest {
  plan: PlanCode;
  customerEmail: string;
  customerName: string;
  successUrl: string;
  cancelUrl: string;
  provider?: PaymentProviderId;
}

export interface CheckoutSession {
  provider: PaymentProviderId;
  checkoutId: string;
  checkoutUrl: string;
  plan: PlanCode;
  amountCents: number;
  currency: string;
}

export interface NormalizedPaymentEvent {
  provider: PaymentProviderId;
  providerEventId: string;
  type: NormalizedEventType;
  customerEmail: string;
  customerName?: string;
  planCode?: PlanCode;
  amountCents?: number;
  currency?: string;
  providerSubscriptionId?: string;
  providerTransactionId?: string;
  occurredAt: string;
  rawSummary?: string;
}

export interface PaymentPort {
  readonly id: PaymentProviderId;
  createCheckout(req: CheckoutRequest): Promise<CheckoutSession>;
  cancelSubscription(providerRef: string): Promise<{ ok: boolean }>;
  verifyWebhook(headers: Headers, rawBody: string): Promise<NormalizedPaymentEvent | null>;
}

export type InvoiceStatus = "paid" | "open" | "void" | "refunded";
export type PaymentStatus = "succeeded" | "failed" | "refunded" | "disputed";

export interface InvoiceRecord {
  id: string;
  customerEmail: string;
  plan: PlanCode;
  amountCents: number;
  currency: string;
  status: InvoiceStatus;
  provider: PaymentProviderId;
  providerRef?: string;
  licenseId?: string;
  createdAt: string;
  paidAt?: string;
}

export interface PaymentRecord {
  id: string;
  customerEmail: string;
  amountCents: number;
  currency: string;
  status: PaymentStatus;
  provider: PaymentProviderId;
  providerEventId: string;
  providerTransactionId?: string;
  invoiceId?: string;
  plan?: PlanCode;
  createdAt: string;
  note?: string;
}

export interface BillingSubscriptionRecord {
  id: string;
  customerEmail: string;
  plan: PlanCode;
  status: "trialing" | "active" | "past_due" | "cancelled" | "expired";
  provider: PaymentProviderId;
  providerSubscriptionId?: string;
  licenseId?: string;
  renewalDate?: string;
  nextBillingDate?: string;
  cancelledAt?: string;
  createdAt: string;
  updatedAt: string;
}

export interface ProcessedWebhook {
  providerEventId: string;
  provider: PaymentProviderId;
  processedAt: string;
  type: NormalizedEventType;
}

/** Auth + outcome log for every inbound webhook attempt (retry-safe ops). */
export interface WebhookAuditEntry {
  id: string;
  provider: string;
  at: string;
  authenticated: boolean;
  duplicate?: boolean;
  eventType?: NormalizedEventType;
  providerEventId?: string;
  detail: string;
  httpStatus: number;
}

export interface EmailOutboxItem {
  id: string;
  to: string;
  template: string;
  subject: string;
  body: string;
  createdAt: string;
  status: "queued" | "sent" | "failed";
}

export interface BillingStoreData {
  version: 1;
  edition: "Professional_Website";
  invoices: InvoiceRecord[];
  payments: PaymentRecord[];
  subscriptions: BillingSubscriptionRecord[];
  processedWebhooks: ProcessedWebhook[];
  webhookAudits: WebhookAuditEntry[];
  emails: EmailOutboxItem[];
}
