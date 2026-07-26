"use server";

import { revalidatePath } from "next/cache";
import { requirePermission } from "@/server/licensing/session";
import { getPhase11Sprint8Dashboard, runFullPhase11Sprint8Suite } from "./suite";

function revalidate() {
  revalidatePath("/portal/admin/api-platform");
  revalidatePath("/portal/admin/api-webhooks");
  revalidatePath("/developers");
}

export async function actionRunApiSuite(): Promise<void> {
  await requirePermission("admin.launch.write");
  await runFullPhase11Sprint8Suite();
  revalidate();
}

export async function actionRefreshApi(): Promise<void> {
  await requirePermission("admin.launch.read");
  await getPhase11Sprint8Dashboard({ refresh: false });
  revalidate();
}
