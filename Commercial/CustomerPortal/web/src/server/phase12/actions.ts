"use server";

import { revalidatePath } from "next/cache";
import { requirePermission } from "@/server/licensing/session";
import { getPhase12Dashboard, runFullPhase12LtsSuite } from "./suite";

function revalidate() {
  revalidatePath("/portal/admin/phase12-lts");
  revalidatePath("/portal/admin/phase12-customer-success");
  revalidatePath("/portal/admin/phase12-monthly");
  revalidatePath("/portal/admin/phase12-v2-planning");
}

export async function actionRunPhase12Lts(): Promise<void> {
  await requirePermission("admin.launch.write");
  await runFullPhase12LtsSuite();
  revalidate();
}

export async function actionRefreshPhase12(): Promise<void> {
  await requirePermission("admin.launch.read");
  await getPhase12Dashboard({ refresh: false });
  revalidate();
}
