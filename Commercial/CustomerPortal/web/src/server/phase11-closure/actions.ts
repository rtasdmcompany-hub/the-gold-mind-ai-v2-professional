"use server";

import { revalidatePath } from "next/cache";
import { requirePermission } from "@/server/licensing/session";
import { getPhase11Sprint10Dashboard, runFullPhase11Sprint10Suite } from "./suite";

function revalidate() {
  revalidatePath("/portal/admin/phase11-certification");
  revalidatePath("/portal/admin/phase11-decision");
}

export async function actionRunPhase11Closure(): Promise<void> {
  await requirePermission("admin.launch.write");
  await runFullPhase11Sprint10Suite();
  revalidate();
}

export async function actionRefreshPhase11Closure(): Promise<void> {
  await requirePermission("admin.launch.read");
  await getPhase11Sprint10Dashboard({ refresh: false });
  revalidate();
}
