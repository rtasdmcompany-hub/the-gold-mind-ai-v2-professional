"use server";

import { revalidatePath } from "next/cache";
import { requirePermission } from "@/server/licensing/session";
import { getPhase11Sprint2Dashboard, runFullPhase11Sprint2Suite } from "./dashboard";

function revalidate() {
  revalidatePath("/portal/admin/bi-executive");
  revalidatePath("/portal/admin/bi-revenue");
  revalidatePath("/portal/admin/bi-subscriptions");
  revalidatePath("/portal/admin/bi-customers");
}

export async function actionRunPhase11Sprint2(): Promise<void> {
  await requirePermission("admin.launch.write");
  await runFullPhase11Sprint2Suite();
  revalidate();
}

export async function actionRefreshPhase11Bi(): Promise<void> {
  await requirePermission("admin.launch.read");
  await getPhase11Sprint2Dashboard({ refresh: false });
  revalidate();
}
