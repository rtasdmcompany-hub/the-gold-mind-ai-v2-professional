"use server";

import { revalidatePath } from "next/cache";
import { requirePermission } from "@/server/licensing/session";
import { getPhase11Sprint1Dashboard, runFullPhase11Sprint1Suite } from "./dashboard";

function revalidate() {
  revalidatePath("/portal/admin/global-ops");
  revalidatePath("/portal/admin/business-kpis");
  revalidatePath("/portal/admin/commercial-ops");
  revalidatePath("/portal/admin/cs-operations");
}

export async function actionRunPhase11Sprint1(): Promise<void> {
  await requirePermission("admin.launch.write");
  await runFullPhase11Sprint1Suite();
  revalidate();
}

export async function actionRefreshPhase11(): Promise<void> {
  await requirePermission("admin.launch.read");
  await getPhase11Sprint1Dashboard({ refresh: false });
  revalidate();
}
