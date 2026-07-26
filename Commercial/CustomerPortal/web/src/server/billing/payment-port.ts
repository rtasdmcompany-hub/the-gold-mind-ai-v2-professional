import type { PaymentPort, PaymentProviderId } from "./types";
import { paddlePort, paypalPort, sandboxPort, stripePort } from "./providers";

const registry: Record<PaymentProviderId, PaymentPort> = {
  sandbox: sandboxPort,
  paddle: paddlePort,
  paypal: paypalPort,
  stripe: stripePort,
};

/** Business logic resolves providers only through this port — never hard-codes PSP SDKs. */
export function getPaymentPort(preferred?: PaymentProviderId): PaymentPort {
  const primary = (process.env.PAYMENT_PRIMARY_PROVIDER || "paddle") as PaymentProviderId;
  const id = preferred || primary;
  if (id === "paddle" && !process.env.PADDLE_VENDOR_ID && !process.env.PADDLE_WEBHOOK_SECRET) {
    // Dev fallback to sandbox while keeping paddle as configured primary
    if (process.env.PAYMENT_FORCE_SANDBOX === "true" || process.env.NODE_ENV !== "production") {
      return registry.sandbox;
    }
  }
  return registry[id] || registry.sandbox;
}

export function getWebhookPort(provider: string): PaymentPort | null {
  const id = provider as PaymentProviderId;
  return registry[id] || null;
}

export function listProviders(): PaymentProviderId[] {
  return ["paddle", "paypal", "stripe", "sandbox"];
}
