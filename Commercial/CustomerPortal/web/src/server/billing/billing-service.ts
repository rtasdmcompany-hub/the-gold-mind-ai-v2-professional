import { getPaymentPort } from "./payment-port";
import { processNormalizedEvent } from "./webhook-processor";
import { mutateBilling, readBillingStore } from "./store";
import { deliverBillingEmail } from "./mail-delivery";
import { isSandboxCheckoutAllowed } from "./config";
import type { CheckoutRequest, PlanCode, PaymentProviderId } from "./types";
import { PLAN_CATALOG, formatMoney, hmacSha256, id, nowIso } from "./util";
import type { NormalizedPaymentEvent } from "./types";
import { brand } from "@/lib/brand";

export async function startCheckout(req: CheckoutRequest) {
  const port = getPaymentPort(req.provider);
  return port.createCheckout(req);
}

/** Cancel local billing subscription + attempt PSP cancel when credentials exist. */
export async function cancelBillingSubscriptionForLicense(input: {
  customerEmail: string;
  licenseId: string;
}): Promise<{ localOk: boolean; providerOk: boolean | null; detail: string }> {
  const email = input.customerEmail.toLowerCase();
  const data = readBillingStore();
  const sub = data.subscriptions.find(
    (s) => s.customerEmail === email && s.licenseId === input.licenseId && (s.status === "active" || s.status === "trialing" || s.status === "past_due")
  );
  if (!sub) {
    return { localOk: false, providerOk: null, detail: "No active billing subscription linked to this license." };
  }

  let providerOk: boolean | null = null;
  if (sub.providerSubscriptionId && sub.provider !== "sandbox") {
    try {
      const port = getPaymentPort(sub.provider);
      const r = await port.cancelSubscription(sub.providerSubscriptionId);
      providerOk = r.ok;
    } catch {
      providerOk = false;
    }
  } else if (sub.provider === "sandbox") {
    providerOk = true;
  }

  mutateBilling((store) => {
    const s = store.subscriptions.find((x) => x.id === sub.id);
    if (s) {
      s.status = "cancelled";
      s.cancelledAt = nowIso();
    }
  });

  const detail =
    providerOk === false
      ? "Local subscription cancelled. Provider cancel API is not configured — cancel remotely in the PSP dashboard if needed."
      : providerOk === true
        ? "Subscription cancelled locally and at provider."
        : "Subscription cancelled locally (no remote provider subscription id).";

  return { localOk: true, providerOk, detail };
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
  if (!isSandboxCheckoutAllowed()) {
    throw new Error("SANDBOX_DISABLED_IN_PRODUCTION: Use a configured live payment provider.");
  }
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
      deliverBillingEmail({
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
    deliverBillingEmail({
      to: sub.customerEmail,
      template: "subscription_expiry",
      body: `Your ${brand.productName} (${sub.plan}) subscription period ended on ${end.slice(0, 10)}. Renew in the Customer Portal to restore Website Edition access. The Core Trading Engine is not controlled by this notice.`,
    });
    n++;
  }
  return n;
}

export { PLAN_CATALOG, formatMoney };
