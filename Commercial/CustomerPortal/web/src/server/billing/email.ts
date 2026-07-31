import { mutateBilling } from "./store";
import { readBillingStore } from "./store";
import { id, nowIso } from "./util";
import { brand } from "@/lib/brand";

export type EmailTemplate =
  | "purchase_confirmation"
  | "invoice"
  | "receipt"
  | "license_delivery"
  | "renewal_reminder"
  | "payment_failure"
  | "subscription_expiry"
  | "cancellation_confirmation"
  | "support_ticket"
  | "support_reply";

const SUBJECTS: Record<EmailTemplate, string> = {
  purchase_confirmation: `Purchase confirmed — ${brand.productName}`,
  invoice: `Your invoice — ${brand.productName}`,
  receipt: `Payment receipt — ${brand.productName}`,
  license_delivery: `Your license key — ${brand.productName}`,
  renewal_reminder: `Renewal reminder — ${brand.productName}`,
  payment_failure: "Payment failed — action needed",
  subscription_expiry: "Subscription expired",
  cancellation_confirmation: "Subscription cancelled",
  support_ticket: `Support ticket received — ${brand.productName}`,
  support_reply: `Support reply — ${brand.productName}`,
};

export function commercialEmailSubject(template: EmailTemplate): string {
  return SUBJECTS[template];
}

export function queueCommercialEmail(input: {
  to: string;
  template: EmailTemplate;
  body: string;
  subject?: string;
  status?: "queued" | "sent" | "failed";
}): string {
  const emailId = id("eml");
  mutateBilling((data) => {
    data.emails.unshift({
      id: emailId,
      to: input.to,
      template: input.template,
      subject: input.subject || SUBJECTS[input.template],
      body: input.body,
      createdAt: nowIso(),
      status: input.status || "queued",
    });
  });

  if (process.env.NODE_ENV !== "production" || process.env.BILLING_EMAIL_LOG === "true") {
    console.info(`[billing-email] → ${input.to} · ${input.template}`);
  }
  return emailId;
}

export function updateCommercialEmailStatus(
  emailId: string | undefined,
  status: "queued" | "sent" | "failed",
  note?: string
): void {
  if (!emailId) return;
  void note;
  mutateBilling((data) => {
    const row = data.emails.find((e) => e.id === emailId);
    if (row) row.status = status;
  });
}

export function listEmailsForCustomer(email: string) {
  return readBillingStore().emails.filter((e) => e.to.toLowerCase() === email.toLowerCase());
}

export function listAllEmailsAdmin(limit = 50) {
  return readBillingStore().emails.slice(0, limit);
}
