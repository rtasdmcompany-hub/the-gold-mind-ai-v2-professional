import type { PaymentPort, PaymentProviderId } from "./types";
import { paddlePort, paypalPort, sandboxPort, stripePort } from "./providers";
import { resolveCheckoutProvider } from "./config";

const registry: Record<PaymentProviderId, PaymentPort> = {
  sandbox: sandboxPort,
  paddle: paddlePort,
  paypal: paypalPort,
  stripe: stripePort,
};

/**
 * Business logic resolves providers only through this port — never hard-codes PSP SDKs.
 * Throws when production has no configured provider (no silent sandbox fallback).
 */
export function getPaymentPort(preferred?: PaymentProviderId): PaymentPort {
  const resolved = resolveCheckoutProvider(preferred);
  if (!resolved.ok) {
    throw new Error(resolved.error || "PAYMENT_PROVIDER_UNCONFIGURED");
  }
  return registry[resolved.provider] || registry.sandbox;
}

/** Non-throwing resolve for UI banners. */
export function tryGetPaymentPort(preferred?: PaymentProviderId): {
  port: PaymentPort | null;
  error?: string;
  provider?: PaymentProviderId;
} {
  try {
    const resolved = resolveCheckoutProvider(preferred);
    if (!resolved.ok) return { port: null, error: resolved.error, provider: resolved.provider };
    return { port: registry[resolved.provider], provider: resolved.provider };
  } catch (e) {
    return { port: null, error: e instanceof Error ? e.message : "PAYMENT_PROVIDER_UNCONFIGURED" };
  }
}

export function getWebhookPort(provider: string): PaymentPort | null {
  const id = provider as PaymentProviderId;
  return registry[id] || null;
}

export function listProviders(): PaymentProviderId[] {
  return ["paddle", "paypal", "stripe", "sandbox"];
}
