"use server";

import { revalidatePath } from "next/cache";
import { requirePermission } from "@/server/licensing/session";

function revalidateSuccess() {
  revalidatePath("/portal/admin/success");
  revalidatePath("/portal/admin/customer-success");
  revalidatePath("/portal/admin/support-analytics");
  revalidatePath("/portal/admin/stabilization");
  revalidatePath("/portal/knowledge-base");
}

export async function actionRefreshSuccessDashboards(): Promise<void> {
  await requirePermission("admin.launch.read");
  revalidateSuccess();
}
