import { createLicense, renewLicense } from "@/server/licensing/license-service";
import type { LicenseType } from "@/server/licensing/types";
import { queueCommercialEmail } from "./email";
import { mutateBilling, readBillingStore } from "./store";
import type { NormalizedPaymentEvent, PlanCode } from "./types";
import { PLAN_CATALOG, formatMoney, id, nowIso } from "./util";

function planToLicenseType(plan: PlanCode): LicenseType {
  return plan;
}

/**
 * Idempotent webhook processor.
 * Authenticated upstream via PaymentPort.verifyWebhook.
 * Never touches Core Trading Engine.
 * Retry-safe: duplicate providerEventId returns success without re-applying.
 */
export function processNormalizedEvent(event: NormalizedPaymentEvent): {
  ok: boolean;
  duplicate?: boolean;
  detail: string;
  licenseId?: string;
  plaintextKey?: string;
} {
  const store = readBillingStore();
  if (store.processedWebhooks.some((w) => w.providerEventId === event.providerEventId)) {
    return { ok: true, duplicate: true, detail: "Already processed (idempotent)" };
  }

  let licenseId: string | undefined;
  let plaintextKey: string | undefined;
  let detail: string = event.type;

  switch (event.type) {
    case "payment.succeeded":
    case "subscription.created": {
      const plan = event.planCode || "monthly";
      const amount = event.amountCents ?? PLAN_CATALOG[plan].amountCents;
      const created = createLicense({
        customerEmail: event.customerEmail,
        customerName: event.customerName || event.customerEmail,
        type: planToLicenseType(plan),
        actorEmail: `billing:${event.provider}`,
      });
      licenseId = created.license.id;
      plaintextKey = created.plaintextKey;

      mutateBilling((data) => {
        markProcessed(data, event);
        const invId = id("inv");
        data.invoices.unshift({
          id: invId,
          customerEmail: event.customerEmail,
          plan,
          amountCents: amount,
          currency: event.currency || "USD",
          status: "paid",
          provider: event.provider,
          providerRef: event.providerTransactionId,
          licenseId,
          createdAt: nowIso(),
          paidAt: nowIso(),
        });
        data.payments.unshift({
          id: id("pay"),
          customerEmail: event.customerEmail,
          amountCents: amount,
          currency: event.currency || "USD",
          status: "succeeded",
          provider: event.provider,
          providerEventId: event.providerEventId,
          providerTransactionId: event.providerTransactionId,
          invoiceId: invId,
          plan,
          createdAt: nowIso(),
        });
        const existing = data.subscriptions.find(
          (s) => s.customerEmail === event.customerEmail && s.plan === plan && (s.status === "active" || s.status === "trialing")
        );
        if (!existing) {
          data.subscriptions.unshift({
            id: id("bsub"),
            customerEmail: event.customerEmail,
            plan,
            status: plan === "trial" ? "trialing" : "active",
            provider: event.provider,
            providerSubscriptionId: event.providerSubscriptionId,
            licenseId,
            renewalDate: created.license.expiresAt || undefined,
            nextBillingDate: plan === "lifetime" ? undefined : created.license.expiresAt || undefined,
            createdAt: nowIso(),
            updatedAt: nowIso(),
          });
        } else {
          existing.licenseId = licenseId;
          existing.updatedAt = nowIso();
          existing.status = plan === "trial" ? "trialing" : "active";
          existing.providerSubscriptionId = event.providerSubscriptionId || existing.providerSubscriptionId;
        }
      });

      queueCommercialEmail({
        to: event.customerEmail,
        template: "purchase_confirmation",
        body: `Thank you for purchasing THE GOLD MIND PROFESSIONAL (${plan}). Amount ${formatMoney(amount)}.`,
      });
      queueCommercialEmail({
        to: event.customerEmail,
        template: "invoice",
        body: `Invoice for ${plan}: ${formatMoney(amount)}. License assigned: ${licenseId}.`,
      });
      queueCommercialEmail({
        to: event.customerEmail,
        template: "receipt",
        body: `Receipt ${event.providerTransactionId || event.providerEventId}: ${formatMoney(amount)} paid via ${event.provider}.`,
      });
      queueCommercialEmail({
        to: event.customerEmail,
        template: "license_delivery",
        body: `Your license key (store securely): ${plaintextKey}\nActivate in Customer Portal → My Licenses.`,
      });
      detail = `Payment OK · license ${licenseId}`;
      break;
    }

    case "subscription.renewed": {
      let renewedLicense: string | undefined;
      mutateBilling((data) => {
        markProcessed(data, event);
        const sub = data.subscriptions.find(
          (s) =>
            s.customerEmail === event.customerEmail &&
            (s.providerSubscriptionId === event.providerSubscriptionId ||
              s.status === "active" ||
              s.status === "past_due")
        );
        if (sub?.licenseId) {
          renewedLicense = sub.licenseId;
          sub.status = "active";
          sub.updatedAt = nowIso();
          sub.nextBillingDate = event.occurredAt;
        }
        const amount = event.amountCents ?? (sub ? PLAN_CATALOG[sub.plan].amountCents : 0);
        data.payments.unshift({
          id: id("pay"),
          customerEmail: event.customerEmail,
          amountCents: amount,
          currency: event.currency || "USD",
          status: "succeeded",
          provider: event.provider,
          providerEventId: event.providerEventId,
          plan: sub?.plan,
          createdAt: nowIso(),
          note: "renewal",
        });
      });
      if (renewedLicense) {
        renewLicense(renewedLicense, `billing:${event.provider}`);
        licenseId = renewedLicense;
      }
      queueCommercialEmail({
        to: event.customerEmail,
        template: "receipt",
        body: `Renewal payment received. Your Professional subscription continues.`,
      });
      detail = `Renewed · license ${licenseId || "n/a"}`;
      break;
    }

    case "payment.failed":
    case "subscription.past_due": {
      mutateBilling((data) => {
        markProcessed(data, event);
        data.payments.unshift({
          id: id("pay"),
          customerEmail: event.customerEmail,
          amountCents: event.amountCents || 0,
          currency: event.currency || "USD",
          status: "failed",
          provider: event.provider,
          providerEventId: event.providerEventId,
          plan: event.planCode,
          createdAt: nowIso(),
        });
        const sub = data.subscriptions.find(
          (s) => s.customerEmail === event.customerEmail && (s.status === "active" || s.status === "trialing")
        );
        if (sub) {
          sub.status = "past_due";
          sub.updatedAt = nowIso();
        }
      });
      queueCommercialEmail({
        to: event.customerEmail,
        template: "payment_failure",
        body: `We could not process your payment for THE GOLD MIND PROFESSIONAL. Update billing in the Customer Portal. The Core Trading Engine is unaffected.`,
      });
      detail = "Payment failed recorded";
      break;
    }

    case "refund.created": {
      mutateBilling((data) => {
        markProcessed(data, event);
        data.payments.unshift({
          id: id("pay"),
          customerEmail: event.customerEmail,
          amountCents: event.amountCents || 0,
          currency: event.currency || "USD",
          status: "refunded",
          provider: event.provider,
          providerEventId: event.providerEventId,
          createdAt: nowIso(),
        });
        const inv = data.invoices.find((i) => i.customerEmail === event.customerEmail && i.status === "paid");
        if (inv) inv.status = "refunded";
      });
      detail = "Refund recorded";
      break;
    }

    case "subscription.cancelled": {
      mutateBilling((data) => {
        markProcessed(data, event);
        const sub = data.subscriptions.find((s) => s.customerEmail === event.customerEmail && s.status !== "cancelled");
        if (sub) {
          sub.status = "cancelled";
          sub.cancelledAt = nowIso();
          sub.updatedAt = nowIso();
        }
      });
      queueCommercialEmail({
        to: event.customerEmail,
        template: "cancellation_confirmation",
        body: `Your Professional subscription has been cancelled. Access continues until period end per policy.`,
      });
      detail = "Cancellation recorded";
      break;
    }

    case "dispute.opened": {
      mutateBilling((data) => {
        markProcessed(data, event);
        data.payments.unshift({
          id: id("pay"),
          customerEmail: event.customerEmail,
          amountCents: event.amountCents || 0,
          currency: event.currency || "USD",
          status: "disputed",
          provider: event.provider,
          providerEventId: event.providerEventId,
          createdAt: nowIso(),
          note: "chargeback/dispute",
        });
      });
      detail = "Dispute logged";
      break;
    }

    default:
      mutateBilling((data) => markProcessed(data, event));
      detail = "Unhandled type (acked)";
  }

  return { ok: true, detail, licenseId, plaintextKey };
}

function markProcessed(
  data: import("./types").BillingStoreData,
  event: NormalizedPaymentEvent
): void {
  data.processedWebhooks.unshift({
    providerEventId: event.providerEventId,
    provider: event.provider,
    processedAt: nowIso(),
    type: event.type,
  });
}
