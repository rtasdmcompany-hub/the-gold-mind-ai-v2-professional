import { mutateBilling } from "./store";
import { readBillingStore } from "./store";
import { id, nowIso } from "./util";

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
  purchase_confirmation: "Purchase confirmed — THE GOLD MIND PROFESSIONAL",
  invoice: "Your invoice — THE GOLD MIND PROFESSIONAL",
  receipt: "Payment receipt — THE GOLD MIND PROFESSIONAL",
  license_delivery: "Your license key — THE GOLD MIND PROFESSIONAL",
  renewal_reminder: "Renewal reminder — THE GOLD MIND PROFESSIONAL",
  payment_failure: "Payment failed — action needed",
  subscription_expiry: "Subscription expired",
  cancellation_confirmation: "Subscription cancelled",
  support_ticket: "Support ticket received — THE GOLD MIND PROFESSIONAL",
  support_reply: "Support reply — THE GOLD MIND PROFESSIONAL",
};

export function queueCommercialEmail(input: {
  to: string;
  template: EmailTemplate;
  body: string;
  subject?: string;
}): void {
  mutateBilling((data) => {
    data.emails.unshift({
      id: id("eml"),
      to: input.to,
      template: input.template,
      subject: input.subject || SUBJECTS[input.template],
      body: input.body,
      createdAt: nowIso(),
      status: "sent",
    });
  });

  if (process.env.NODE_ENV !== "production" || process.env.BILLING_EMAIL_LOG === "true") {
    console.info(`[billing-email] → ${input.to} · ${input.template}`);
  }
}

export function listEmailsForCustomer(email: string) {
  return readBillingStore().emails.filter((e) => e.to.toLowerCase() === email.toLowerCase());
}

export function listAllEmailsAdmin(limit = 50) {
  return readBillingStore().emails.slice(0, limit);
}
