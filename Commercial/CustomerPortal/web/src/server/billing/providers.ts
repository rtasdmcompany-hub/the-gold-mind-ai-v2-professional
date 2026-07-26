import type { CheckoutRequest, CheckoutSession, NormalizedPaymentEvent, PaymentPort, PlanCode } from "./types";
import { PLAN_CATALOG, hmacSha256, id, nowIso, safeEqual } from "./util";

function baseUrl(): string {
  return process.env.NEXTAUTH_URL || "http://localhost:3000";
}

/** Sandbox provider — local/MVP checkout without live PSP credentials. */
export const sandboxPort: PaymentPort = {
  id: "sandbox",
  async createCheckout(req: CheckoutRequest): Promise<CheckoutSession> {
    const plan = PLAN_CATALOG[req.plan];
    const checkoutId = id("chk_sandbox");
    return {
      provider: "sandbox",
      checkoutId,
      checkoutUrl: `${baseUrl()}/portal/billing/checkout/sandbox?checkoutId=${checkoutId}&plan=${req.plan}&email=${encodeURIComponent(req.customerEmail)}`,
      plan: req.plan,
      amountCents: plan.amountCents,
      currency: plan.currency,
    };
  },
  async cancelSubscription() {
    return { ok: true };
  },
  async verifyWebhook(headers: Headers, rawBody: string) {
    const secret =
      process.env.SANDBOX_WEBHOOK_SECRET ||
      (process.env.NODE_ENV === "production" ? "" : "sandbox-webhook-secret");
    if (!secret || (process.env.NODE_ENV === "production" && secret === "sandbox-webhook-secret")) {
      return null;
    }
    const sig = headers.get("x-tgm-sandbox-signature") || "";
    const expected = hmacSha256(secret, rawBody);
    if (!safeEqual(sig, expected)) return null;
    const body = JSON.parse(rawBody) as NormalizedPaymentEvent;
    if (!body.providerEventId || !body.type) return null;
    return { ...body, provider: "sandbox", occurredAt: body.occurredAt || nowIso() };
  },
};

export const paddlePort: PaymentPort = {
  id: "paddle",
  async createCheckout(req: CheckoutRequest): Promise<CheckoutSession> {
    const plan = PLAN_CATALOG[req.plan];
    const vendor = process.env.PADDLE_VENDOR_ID;
    const checkoutId = id("chk_paddle");
    // Production would call Paddle API; MVP returns hosted-style URL template
    const checkoutUrl = vendor
      ? `https://buy.paddle.com/checkout/${process.env.PADDLE_PRICE_ID || "price"}?email=${encodeURIComponent(req.customerEmail)}&passthrough=${checkoutId}`
      : `${baseUrl()}/portal/billing/checkout/sandbox?checkoutId=${checkoutId}&plan=${req.plan}&email=${encodeURIComponent(req.customerEmail)}&provider=paddle`;
    return {
      provider: vendor ? "paddle" : "sandbox",
      checkoutId,
      checkoutUrl,
      plan: req.plan,
      amountCents: plan.amountCents,
      currency: plan.currency,
    };
  },
  async cancelSubscription() {
    // Wire to Paddle subscription cancel API when credentials present
    return { ok: true };
  },
  async verifyWebhook(headers: Headers, rawBody: string) {
    const secret = process.env.PADDLE_WEBHOOK_SECRET;
    if (!secret) {
      // Fallback: accept sandbox-shaped events only in non-prod
      if (process.env.NODE_ENV === "production") return null;
      return sandboxPort.verifyWebhook(headers, rawBody);
    }
    const sig = headers.get("paddle-signature") || headers.get("x-paddle-signature") || "";
    const expected = hmacSha256(secret, rawBody);
    if (!safeEqual(sig, expected) && !safeEqual(sig, `sha256=${expected}`)) return null;
    const payload = JSON.parse(rawBody) as Record<string, unknown>;
    return mapPaddleEvent(payload);
  },
};

export const paypalPort: PaymentPort = {
  id: "paypal",
  async createCheckout(req: CheckoutRequest): Promise<CheckoutSession> {
    const plan = PLAN_CATALOG[req.plan];
    const checkoutId = id("chk_paypal");
    const clientId = process.env.PAYPAL_CLIENT_ID;
    const checkoutUrl = clientId
      ? `https://www.paypal.com/checkoutnow?token=${checkoutId}`
      : `${baseUrl()}/portal/billing/checkout/sandbox?checkoutId=${checkoutId}&plan=${req.plan}&email=${encodeURIComponent(req.customerEmail)}&provider=paypal`;
    return {
      provider: clientId ? "paypal" : "sandbox",
      checkoutId,
      checkoutUrl,
      plan: req.plan,
      amountCents: plan.amountCents,
      currency: plan.currency,
    };
  },
  async cancelSubscription() {
    return { ok: true };
  },
  async verifyWebhook(headers: Headers, rawBody: string) {
    const secret = process.env.PAYPAL_WEBHOOK_ID || process.env.PAYPAL_WEBHOOK_SECRET;
    if (!secret) {
      if (process.env.NODE_ENV === "production") return null;
      return sandboxPort.verifyWebhook(headers, rawBody);
    }
    const sig = headers.get("paypal-transmission-sig") || headers.get("x-paypal-signature") || "";
    const expected = hmacSha256(secret, rawBody);
    if (!safeEqual(sig, expected)) return null;
    const payload = JSON.parse(rawBody) as Record<string, unknown>;
    return mapPaypalEvent(payload);
  },
};

/** Future provider — fail-closed without STRIPE_WEBHOOK_SECRET; HMAC verify when set. */
export const stripePort: PaymentPort = {
  id: "stripe",
  async createCheckout(req) {
    const plan = PLAN_CATALOG[req.plan];
    const checkoutId = id("chk_stripe");
    return {
      provider: "stripe",
      checkoutId,
      checkoutUrl: `${baseUrl()}/portal/billing?stripe=future&plan=${req.plan}`,
      plan: req.plan,
      amountCents: plan.amountCents,
      currency: plan.currency,
    };
  },
  async cancelSubscription() {
    return { ok: false };
  },
  async verifyWebhook(headers: Headers, rawBody: string) {
    const secret = process.env.STRIPE_WEBHOOK_SECRET;
    if (!secret) return null;
    const sig = headers.get("stripe-signature") || headers.get("x-stripe-signature") || "";
    // Controlled Launch: HMAC of raw body (full Stripe signed-payload parser when going live)
    const expected = hmacSha256(secret, rawBody);
    const candidates = sig.split(",").map((p) => p.trim().replace(/^v1=/, ""));
    if (!candidates.some((c) => safeEqual(c, expected) || safeEqual(sig, expected))) return null;
    try {
      const payload = JSON.parse(rawBody) as Record<string, unknown>;
      const eventId = String(payload.id || "");
      const typeRaw = String(payload.type || "");
      const data = (payload.data as { object?: Record<string, unknown> } | undefined)?.object || {};
      const email = String(data.customer_email || data.receipt_email || "").toLowerCase();
      if (!eventId || !email) return null;
      const type =
        typeRaw.includes("succeeded") || typeRaw.includes("paid")
          ? "payment.succeeded"
          : typeRaw.includes("failed")
            ? "payment.failed"
            : typeRaw.includes("canceled") || typeRaw.includes("cancelled")
              ? "subscription.cancelled"
              : null;
      if (!type) return null;
      return {
        provider: "stripe",
        providerEventId: eventId,
        type,
        customerEmail: email,
        planCode: (data.plan_code as PlanCode) || "monthly",
        amountCents: Number(data.amount_total || data.amount || 0) || undefined,
        currency: String(data.currency || "USD").toUpperCase(),
        occurredAt: nowIso(),
      };
    } catch {
      return null;
    }
  },
};

function mapPaddleEvent(payload: Record<string, unknown>): NormalizedPaymentEvent | null {
  const eventId = String(payload.alert_id || payload.event_id || payload.id || "");
  const alert = String(payload.alert_name || payload.event_type || "");
  const email = String(payload.email || payload.customer_email || "").toLowerCase();
  if (!eventId || !email) return null;
  const type = paddleAlertToType(alert);
  if (!type) return null;
  return {
    provider: "paddle",
    providerEventId: eventId,
    type,
    customerEmail: email,
    planCode: (payload.plan_code as PlanCode) || "monthly",
    amountCents: Math.round(Number(payload.sale_gross || payload.amount || 0) * 100) || undefined,
    currency: String(payload.currency || "USD"),
    providerSubscriptionId: String(payload.subscription_id || "") || undefined,
    providerTransactionId: String(payload.order_id || payload.transaction_id || "") || undefined,
    occurredAt: nowIso(),
    rawSummary: alert,
  };
}

function paddleAlertToType(alert: string): NormalizedPaymentEvent["type"] | null {
  const a = alert.toLowerCase();
  if (a.includes("payment_succeeded") || a.includes("transaction.completed")) return "payment.succeeded";
  if (a.includes("payment_failed") || a.includes("transaction.payment_failed")) return "payment.failed";
  if (a.includes("refund")) return "refund.created";
  if (a.includes("subscription_created")) return "subscription.created";
  if (a.includes("subscription_payment_succeeded") || a.includes("subscription.renewed")) return "subscription.renewed";
  if (a.includes("subscription_cancelled") || a.includes("subscription.canceled")) return "subscription.cancelled";
  if (a.includes("subscription_payment_failed")) return "subscription.past_due";
  if (a.includes("dispute") || a.includes("chargeback")) return "dispute.opened";
  return null;
}

function mapPaypalEvent(payload: Record<string, unknown>): NormalizedPaymentEvent | null {
  const eventId = String(payload.id || "");
  const eventType = String(payload.event_type || "");
  const resource = (payload.resource || {}) as Record<string, unknown>;
  const email = String(
    (resource.subscriber as { email_address?: string } | undefined)?.email_address ||
      resource.email ||
      ""
  ).toLowerCase();
  if (!eventId) return null;
  let type: NormalizedPaymentEvent["type"] | null = null;
  if (eventType.includes("PAYMENT.CAPTURE.COMPLETED") || eventType.includes("SALE.COMPLETED")) type = "payment.succeeded";
  else if (eventType.includes("PAYMENT.CAPTURE.DENIED") || eventType.includes("FAILED")) type = "payment.failed";
  else if (eventType.includes("REFUND")) type = "refund.created";
  else if (eventType.includes("SUBSCRIPTION.ACTIVATED")) type = "subscription.created";
  else if (eventType.includes("SUBSCRIPTION.PAYMENT") || eventType.includes("BILLING.SUBSCRIPTION.RENEWED"))
    type = "subscription.renewed";
  else if (eventType.includes("SUBSCRIPTION.CANCELLED") || eventType.includes("CANCELED")) type = "subscription.cancelled";
  else if (eventType.includes("DISPUTE")) type = "dispute.opened";
  if (!type) return null;
  return {
    provider: "paypal",
    providerEventId: eventId,
    type,
    customerEmail: email || "unknown@paypal.local",
    planCode: "monthly",
    amountCents: resource.amount
      ? Math.round(Number((resource.amount as { value?: string }).value || 0) * 100)
      : undefined,
    currency: "USD",
    providerSubscriptionId: String(resource.id || "") || undefined,
    occurredAt: nowIso(),
    rawSummary: eventType,
  };
}
