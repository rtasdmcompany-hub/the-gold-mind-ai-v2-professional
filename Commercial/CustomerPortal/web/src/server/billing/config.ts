/**
 * Billing / checkout configuration gates — fail honestly when PSP is unconfigured.
 * Never silently mint paid entitlements in production.
 */
import { isProductionRuntime } from "@/server/security/dev-bypass";
import type { PaymentProviderId, PlanCode } from "./types";
import { product } from "@/lib/product";

export function isSandboxCheckoutAllowed(): boolean {
  if (process.env.PAYMENT_FORCE_SANDBOX === "true") return true;
  return !isProductionRuntime();
}

/** Paid self-serve license mint (monthly/yearly/lifetime) outside the billing webhook. */
export function isSelfServePaidLicenseAllowed(): boolean {
  if (process.env.PORTAL_ALLOW_SELF_SERVE_LICENSE === "true") return true;
  return !isProductionRuntime();
}

export function isSelfServeLicenseTypeAllowed(type: PlanCode | string): boolean {
  if (type === "trial") return true;
  return isSelfServePaidLicenseAllowed();
}

/** Free local renew (extends expiry without payment). Never in production. */
export function isFreeRenewAllowed(): boolean {
  if (process.env.PORTAL_ALLOW_FREE_RENEW === "true") return true;
  return !isProductionRuntime();
}

export type ProviderConfigStatus = {
  id: PaymentProviderId;
  configured: boolean;
  detail: string;
};

export function getProviderConfigStatus(id: PaymentProviderId): ProviderConfigStatus {
  switch (id) {
    case "paddle":
      return {
        id,
        configured: !!(process.env.PADDLE_VENDOR_ID && process.env.PADDLE_WEBHOOK_SECRET),
        detail: process.env.PADDLE_VENDOR_ID
          ? process.env.PADDLE_WEBHOOK_SECRET
            ? "Paddle vendor + webhook secret set"
            : "PADDLE_WEBHOOK_SECRET missing"
          : "PADDLE_VENDOR_ID missing",
      };
    case "paypal":
      return {
        id,
        configured: !!(process.env.PAYPAL_CLIENT_ID && (process.env.PAYPAL_WEBHOOK_ID || process.env.PAYPAL_WEBHOOK_SECRET)),
        detail: process.env.PAYPAL_CLIENT_ID
          ? process.env.PAYPAL_WEBHOOK_ID || process.env.PAYPAL_WEBHOOK_SECRET
            ? "PayPal client + webhook id set"
            : "PAYPAL_WEBHOOK_ID / PAYPAL_WEBHOOK_SECRET missing"
          : "PAYPAL_CLIENT_ID missing",
      };
    case "stripe":
      return {
        id,
        configured: !!(process.env.STRIPE_SECRET_KEY && process.env.STRIPE_WEBHOOK_SECRET),
        detail: process.env.STRIPE_SECRET_KEY
          ? process.env.STRIPE_WEBHOOK_SECRET
            ? "Stripe secret + webhook secret set"
            : "STRIPE_WEBHOOK_SECRET missing"
          : "STRIPE_SECRET_KEY missing (Stripe checkout not live)",
      };
    case "sandbox":
      return {
        id,
        configured: isSandboxCheckoutAllowed(),
        detail: isSandboxCheckoutAllowed()
          ? "Sandbox allowed (non-production or PAYMENT_FORCE_SANDBOX)"
          : "Sandbox blocked in production",
      };
  }
}

export function resolveCheckoutProvider(preferred?: PaymentProviderId): {
  provider: PaymentProviderId;
  ok: boolean;
  error?: string;
} {
  const primary = (process.env.PAYMENT_PRIMARY_PROVIDER || product.paymentProvider) as PaymentProviderId;
  const id = preferred || primary;

  if (id === "sandbox") {
    if (!isSandboxCheckoutAllowed()) {
      return { provider: id, ok: false, error: "SANDBOX_DISABLED_IN_PRODUCTION" };
    }
    return { provider: "sandbox", ok: true };
  }

  const status = getProviderConfigStatus(id);
  if (status.configured) return { provider: id, ok: true };

  // Dev only: fall back to sandbox when live credentials missing
  if (isSandboxCheckoutAllowed()) {
    return { provider: "sandbox", ok: true };
  }

  return {
    provider: id,
    ok: false,
    error: `PAYMENT_PROVIDER_UNCONFIGURED:${id}:${status.detail}`,
  };
}

export function listLiveProviderStatuses(): ProviderConfigStatus[] {
  return (["paddle", "paypal", "stripe", "sandbox"] as PaymentProviderId[]).map(getProviderConfigStatus);
}
