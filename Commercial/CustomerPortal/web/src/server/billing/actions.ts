"use server";

import { revalidatePath } from "next/cache";
import { requirePermission, requireSession } from "@/server/licensing/session";
import {
  completeSandboxCheckout,
  startCheckout,
  sendRenewalReminders,
  sendExpiryNotices,
} from "@/server/billing/billing-service";
import { ensureBillingStoreLoaded, flushBillingStore } from "@/server/billing/store";
import { isSandboxCheckoutAllowed } from "@/server/billing/config";
import { resolveBaseUrl } from "@/server/billing/base-url";
import type { PlanCode, PaymentProviderId } from "@/server/billing/types";
import { product } from "@/lib/product";

export async function actionStartCheckout(formData: FormData) {
  const s = await requireSession();
  await ensureBillingStoreLoaded();
  const plan = String(formData.get("plan") || product.defaultLicenseType) as PlanCode;
  const rawProvider = String(formData.get("provider") || "").trim();
  const provider = (rawProvider || undefined) as PaymentProviderId | undefined;
  const base = resolveBaseUrl();
  try {
    const checkout = await startCheckout({
      plan,
      customerEmail: s.email,
      customerName: s.name,
      successUrl: `${base}/portal/billing?ok=1`,
      cancelUrl: `${base}/portal/billing?cancelled=1`,
      provider,
    });
    return checkout;
  } catch (e) {
    return {
      provider: (provider || product.paymentProvider) as PaymentProviderId,
      checkoutId: "",
      checkoutUrl: "",
      plan,
      amountCents: 0,
      currency: product.defaultCurrency,
      error: e instanceof Error ? e.message : "CHECKOUT_FAILED",
    };
  }
}

export async function actionCompleteSandboxCheckout(formData: FormData) {
  const s = await requireSession();
  if (!isSandboxCheckoutAllowed()) {
    return {
      ok: false,
      detail: "Sandbox checkout is disabled in production. Configure Paddle/PayPal/Stripe and use live checkout.",
      licenseId: undefined as string | undefined,
      plaintextKey: undefined as string | undefined,
    };
  }
  await ensureBillingStoreLoaded();
  const plan = String(formData.get("plan") || "monthly") as PlanCode;
  const result = await completeSandboxCheckout({
    plan,
    customerEmail: s.email,
    customerName: s.name,
  });
  await flushBillingStore();
  revalidatePath("/portal");
  revalidatePath("/portal/billing");
  revalidatePath("/portal/licenses");
  revalidatePath("/portal/subscriptions");
  revalidatePath("/portal/invoices");
  revalidatePath("/portal/orders");
  revalidatePath("/portal/admin/billing");
  return {
    ok: result.ok,
    detail: result.detail,
    licenseId: result.licenseId,
    plaintextKey: result.plaintextKey,
  };
}

export async function actionRunRenewalReminders(): Promise<void> {
  await requirePermission("admin.billing.write");
  await ensureBillingStoreLoaded();
  sendRenewalReminders();
  revalidatePath("/portal/admin/billing");
}

export async function actionRunExpiryNotices(): Promise<void> {
  await requirePermission("admin.billing.write");
  await ensureBillingStoreLoaded();
  sendExpiryNotices();
  revalidatePath("/portal/admin/billing");
}
