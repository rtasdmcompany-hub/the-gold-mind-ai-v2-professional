import { getPaymentPort } from "./payment-port";
import { processNormalizedEvent } from "./webhook-processor";
import { readBillingStore } from "./store";
import { queueCommercialEmail } from "./email";
import type { CheckoutRequest, PlanCode, PaymentProviderId } from "./types";
import { PLAN_CATALOG, formatMoney, hmacSha256, id, nowIso } from "./util";
import type { NormalizedPaymentEvent } from "./types";

export async function startCheckout(req: CheckoutRequest) {
  const port = getPaymentPort(req.provider);
  return port.createCheckout(req);
}

export function getBillingSummary(email: string) {
  const e = email.toLowerCase();
  const data = readBillingStore();
  return {
    invoices: data.invoices.filter((i) => i.customerEmail === e),
    payments: data.payments.filter((p) => p.customerEmail === e),
    subscriptions: data.subscriptions.filter((s) => s.customerEmail === e),
    emails: data.emails.filter((m) => m.to.toLowerCase() === e).slice(0, 20),
  };
}

export function getAdminBillingDashboard() {
  const data = readBillingStore();
  const succeeded = data.payments.filter((p) => p.status === "succeeded");
  const failed = data.payments.filter((p) => p.status === "failed");
  const refunds = data.payments.filter((p) => p.status === "refunded");
  const revenueCents = succeeded.reduce((a, p) => a + p.amountCents, 0);
  return {
    revenueCents,
    revenueFormatted: formatMoney(revenueCents),
    subscriptionCount: data.subscriptions.filter((s) => s.status === "active" || s.status === "trialing").length,
    failedPayments: failed,
    refunds,
    renewals: data.payments.filter((p) => p.note === "renewal"),
    recentTransactions: data.payments.slice(0, 40),
    subscriptions: data.subscriptions.slice(0, 40),
    invoices: data.invoices.slice(0, 40),
    webhookAudits: (data.webhookAudits || []).slice(0, 40),
  };
}

/** Complete sandbox checkout → synthesize authenticated webhook event */
export async function completeSandboxCheckout(input: {
  plan: PlanCode;
  customerEmail: string;
  customerName: string;
  provider?: PaymentProviderId;
}) {
  const event: NormalizedPaymentEvent = {
    provider: "sandbox",
    providerEventId: id("evt_sandbox"),
    type: input.plan === "trial" ? "subscription.created" : "payment.succeeded",
    customerEmail: input.customerEmail.toLowerCase(),
    customerName: input.customerName,
    planCode: input.plan,
    amountCents: PLAN_CATALOG[input.plan].amountCents,
    currency: "USD",
    providerTransactionId: id("txn"),
    providerSubscriptionId: input.plan === "lifetime" || input.plan === "trial" ? undefined : id("psub"),
    occurredAt: nowIso(),
    rawSummary: "sandbox.checkout.completed",
  };

  const secret = process.env.SANDBOX_WEBHOOK_SECRET || "sandbox-webhook-secret";
  const rawBody = JSON.stringify(event);
  const signature = hmacSha256(secret, rawBody);
  const headers = new Headers({ "x-tgm-sandbox-signature": signature });
  const port = getPaymentPort("sandbox");
  const verified = await port.verifyWebhook(headers, rawBody);
  if (!verified) throw new Error("SANDBOX_WEBHOOK_VERIFY_FAIL");
  return processNormalizedEvent(verified);
}

export function sendRenewalReminders(): number {
  const data = readBillingStore();
  let n = 0;
  const soon = Date.now() + 7 * 24 * 3600 * 1000;
  for (const sub of data.subscriptions) {
    if (!sub.nextBillingDate || sub.status !== "active") continue;
    if (Date.parse(sub.nextBillingDate) <= soon) {
      queueCommercialEmail({
        to: sub.customerEmail,
        template: "renewal_reminder",
        body: `Your ${sub.plan} plan renews on ${sub.nextBillingDate.slice(0, 10)}. Manage billing in the Customer Portal.`,
      });
      n++;
    }
  }
  return n;
}

/** Queue subscription_expiry emails for cancelled/expired plans past renewal. */
export function sendExpiryNotices(): number {
  const data = readBillingStore();
  let n = 0;
  const now = Date.now();
  for (const sub of data.subscriptions) {
    if (sub.plan === "lifetime") continue;
    const end = sub.renewalDate || sub.nextBillingDate;
    if (!end) continue;
    const ended = Date.parse(end) <= now;
    if (!ended) continue;
    if (sub.status !== "cancelled" && sub.status !== "expired" && sub.status !== "past_due") continue;
    queueCommercialEmail({
      to: sub.customerEmail,
      template: "subscription_expiry",
      body: `Your THE GOLD MIND PROFESSIONAL (${sub.plan}) subscription period ended on ${end.slice(0, 10)}. Renew in the Customer Portal to restore Website Edition access. The Core Trading Engine is not controlled by this notice.`,
    });
    n++;
  }
  return n;
}

export { PLAN_CATALOG, formatMoney };
