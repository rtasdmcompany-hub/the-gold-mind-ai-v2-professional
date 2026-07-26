"use server";

import { revalidatePath } from "next/cache";
import { requirePermission } from "@/server/licensing/session";
import { runFullExecutiveSuite, getExecutiveGoNoGoDashboard } from "./dashboard";

function revalidate() {
  revalidatePath("/portal/admin/go-no-go");
  revalidatePath("/portal/admin/executive-scorecard");
}

export async function actionRunExecutiveSuite(): Promise<void> {
  await requirePermission("admin.launch.write");
  await runFullExecutiveSuite();
  revalidate();
}

export async function actionRefreshExecutive(): Promise<void> {
  await requirePermission("admin.launch.read");
  await getExecutiveGoNoGoDashboard({ refresh: false });
  revalidate();
}
