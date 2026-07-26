"use server";

import { revalidatePath } from "next/cache";
import { requirePermission } from "@/server/licensing/session";
import { getPhase11Sprint5Dashboard, runFullPhase11Sprint5Suite } from "./suite";
import { updateRegionalProfile } from "./regional";
import type { RegionalSettings } from "./types";
import { submitTranslationForReview, approveTranslation } from "./workflow";
import type { LocaleCode } from "./types";

function revalidate() {
  revalidatePath("/portal/admin/localization");
  revalidatePath("/portal/admin/localization-qa");
}

export async function actionRunI18nSuite(): Promise<void> {
  await requirePermission("admin.launch.write");
  await runFullPhase11Sprint5Suite();
  revalidate();
}

export async function actionRefreshI18n(): Promise<void> {
  await requirePermission("admin.launch.read");
  await getPhase11Sprint5Dashboard({ refresh: false });
  revalidate();
}

export async function actionUpdateRegional(
  regionCode: string,
  patch: Partial<RegionalSettings>
): Promise<void> {
  await requirePermission("admin.launch.write");
  updateRegionalProfile(regionCode, patch);
  revalidate();
}

export async function actionSubmitTranslation(input: {
  locale: LocaleCode;
  key: string;
  proposed: string;
}): Promise<void> {
  const session = await requirePermission("admin.launch.write");
  submitTranslationForReview({
    ...input,
    actor: session.email || "admin",
  });
  revalidate();
}

export async function actionApproveTranslation(id: string): Promise<void> {
  const session = await requirePermission("admin.launch.write");
  approveTranslation(id, session.email || "admin");
  revalidate();
}
