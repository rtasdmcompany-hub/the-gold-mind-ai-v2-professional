"use server";

import { revalidatePath } from "next/cache";
import { requirePermission } from "@/server/licensing/session";
import { getPhase11Sprint6Dashboard, runFullPhase11Sprint6Suite } from "./suite";

function revalidate() {
  revalidatePath("/portal/admin/mobile");
  revalidatePath("/portal/admin/mobile-security");
}

export async function actionRunMobileSuite(): Promise<void> {
  await requirePermission("admin.launch.write");
  await runFullPhase11Sprint6Suite();
  revalidate();
}

export async function actionRefreshMobile(): Promise<void> {
  await requirePermission("admin.launch.read");
  await getPhase11Sprint6Dashboard({ refresh: false });
  revalidate();
}
