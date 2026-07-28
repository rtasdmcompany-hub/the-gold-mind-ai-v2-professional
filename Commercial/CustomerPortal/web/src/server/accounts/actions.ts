"use server";

import { auth } from "@/auth";
import { revalidatePath } from "next/cache";
import { setTradeAlertsEnabled } from "@/server/accounts/service";

export async function actionUpdateNotificationPrefs(formData: FormData) {
  const session = await auth();
  const email = session?.user?.email?.toLowerCase();
  if (!email) return;

  const enabled = formData.get("tradeAlertsEnabled") === "on";
  await setTradeAlertsEnabled(email, enabled);
  revalidatePath("/portal/account");
}
