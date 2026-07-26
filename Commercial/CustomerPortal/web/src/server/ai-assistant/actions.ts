"use server";

import { revalidatePath } from "next/cache";
import { requirePermission } from "@/server/licensing/session";
import { getPhase11Sprint7Dashboard, runFullPhase11Sprint7Suite } from "./suite";

function revalidate() {
  revalidatePath("/portal/admin/ai-assistant");
  revalidatePath("/portal/admin/ai-analytics");
}

export async function actionRunAiSuite(): Promise<void> {
  await requirePermission("admin.launch.write");
  await runFullPhase11Sprint7Suite();
  revalidate();
}

export async function actionRefreshAi(): Promise<void> {
  await requirePermission("admin.launch.read");
  await getPhase11Sprint7Dashboard({ refresh: false });
  revalidate();
}
