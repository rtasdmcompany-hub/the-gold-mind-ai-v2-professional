"use server";

import { revalidatePath } from "next/cache";
import { requirePermission } from "@/server/licensing/session";
import { getPhase11Sprint4Dashboard, runFullPhase11Sprint4Suite } from "./suite";

function revalidate() {
  revalidatePath("/portal/admin/enterprise-crm");
  revalidatePath("/portal/admin/organizations");
  revalidatePath("/portal/admin/enterprise-success");
}

export async function actionRunEnterpriseSuite(): Promise<void> {
  await requirePermission("admin.launch.write");
  await runFullPhase11Sprint4Suite();
  revalidate();
}

export async function actionRefreshEnterprise(): Promise<void> {
  await requirePermission("admin.launch.read");
  await getPhase11Sprint4Dashboard({ refresh: false });
  revalidate();
}
