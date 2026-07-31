"use server";

import { auth } from "@/auth";
import { revalidatePath } from "next/cache";
import {
  changeAccountPassword,
  setTradeAlertsEnabled,
  updateAccountProfile,
} from "@/server/accounts/service";

export async function actionUpdateNotificationPrefs(formData: FormData) {
  const session = await auth();
  const email = session?.user?.email?.toLowerCase();
  if (!email) return;

  const enabled = formData.get("tradeAlertsEnabled") === "on";
  await setTradeAlertsEnabled(email, enabled);
  revalidatePath("/portal/account");
}

export async function actionUpdateProfile(formData: FormData): Promise<{ ok: boolean; error?: string }> {
  const session = await auth();
  const email = session?.user?.email?.toLowerCase();
  if (!email) return { ok: false, error: "Not signed in" };
  const name = String(formData.get("name") || "");
  const result = await updateAccountProfile({ email, name });
  if (result.ok) revalidatePath("/portal/account");
  return result;
}

export async function actionChangePassword(formData: FormData): Promise<{ ok: boolean; error?: string }> {
  const session = await auth();
  const email = session?.user?.email?.toLowerCase();
  if (!email) return { ok: false, error: "Not signed in" };
  const currentPassword = String(formData.get("currentPassword") || "");
  const newPassword = String(formData.get("newPassword") || "");
  const result = await changeAccountPassword({ email, currentPassword, newPassword });
  if (result.ok) revalidatePath("/portal/security");
  return result;
}
