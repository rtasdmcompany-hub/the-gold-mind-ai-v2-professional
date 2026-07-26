"use server";

import { revalidatePath } from "next/cache";
import { requirePermission } from "@/server/licensing/session";
import { getClosureDashboard, runFullClosureSuite } from "./dashboard";

function revalidate() {
  revalidatePath("/portal/admin/phase10-closure");
  revalidatePath("/portal/admin/go-no-go");
}

export async function actionRunClosureSuite(): Promise<void> {
  await requirePermission("admin.launch.write");
  await runFullClosureSuite();
  revalidate();
}

export async function actionRefreshClosure(): Promise<void> {
  await requirePermission("admin.launch.read");
  await getClosureDashboard({ refresh: false });
  revalidate();
}
