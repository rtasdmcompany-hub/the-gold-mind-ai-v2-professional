"use server";

import { revalidatePath } from "next/cache";
import { requireSession } from "@/server/licensing/session";
import {
  completeSandboxCheckout,
  startCheckout,
  sendRenewalReminders,
  sendExpiryNotices,
} from "@/server/billing/billing-service";
import type { PlanCode, PaymentProviderId } from "@/server/billing/types";

export async function actionStartCheckout(formData: FormData) {
  const s = await requireSession();
  const plan = String(formData.get("plan") || "monthly") as PlanCode;
  const rawProvider = String(formData.get("provider") || "").trim();
  const provider = (rawProvider || undefined) as PaymentProviderId | undefined;
  const base = process.env.NEXTAUTH_URL || "http://localhost:3000";
  const checkout = await startCheckout({
    plan,
    customerEmail: s.email,
    customerName: s.name,
    successUrl: `${base}/portal/billing?ok=1`,
    cancelUrl: `${base}/portal/billing?cancelled=1`,
    provider,
  });
  return checkout;
}

export async function actionCompleteSandboxCheckout(formData: FormData) {
  const s = await requireSession();
  const plan = String(formData.get("plan") || "monthly") as PlanCode;
  const result = await completeSandboxCheckout({
    plan,
    customerEmail: s.email,
    customerName: s.name,
  });
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
    // one-time key for portal display after sandbox purchase
    plaintextKey: result.plaintextKey,
  };
}

export async function actionRunRenewalReminders(): Promise<void> {
  const s = await requireSession();
  if (s.role !== "admin" && s.email !== "admin@goldmind.local") return;
  sendRenewalReminders();
  revalidatePath("/portal/admin/billing");
}

export async function actionRunExpiryNotices(): Promise<void> {
  const s = await requireSession();
  if (s.role !== "admin" && s.email !== "admin@goldmind.local") return;
  sendExpiryNotices();
  revalidatePath("/portal/admin/billing");
}
