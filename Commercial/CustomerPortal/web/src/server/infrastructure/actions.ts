"use server";

import { revalidatePath } from "next/cache";
import { requirePermission } from "@/server/licensing/session";
import { getPhase11Sprint9Dashboard, runFullPhase11Sprint9Suite } from "./suite";

function revalidate() {
  revalidatePath("/portal/admin/ops-center");
  revalidatePath("/portal/admin/infra-capacity");
  revalidatePath("/portal/admin/sla-executive");
}

export async function actionRunInfraSuite(): Promise<void> {
  await requirePermission("admin.launch.write");
  await runFullPhase11Sprint9Suite();
  revalidate();
}

export async function actionRefreshInfra(): Promise<void> {
  await requirePermission("admin.launch.read");
  await getPhase11Sprint9Dashboard({ refresh: false });
  revalidate();
}
