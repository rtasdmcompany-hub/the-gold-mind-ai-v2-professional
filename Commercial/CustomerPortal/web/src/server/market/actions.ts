"use server";

import { revalidatePath } from "next/cache";
import { requirePermission } from "@/server/licensing/session";
import { runFullMarketSuite, getExecutiveMarketDashboard } from "./dashboard";
import { runEditionVerification } from "./edition";
import { runMql5ComplianceReview } from "./compliance";
import { runStoreAssetInventory } from "./assets";
import { runDocumentationInventory } from "./documentation";
import { runStoreMetadata } from "./metadata";
import { runCommercialValidation } from "./validation";
import { runSubmissionChecklist } from "./submission";

function revalidateMarket() {
  for (const p of [
    "/portal/admin/market",
    "/portal/admin/mql5-compliance",
    "/portal/admin/store-assets",
    "/portal/admin/store-metadata",
  ]) {
    revalidatePath(p);
  }
}

export async function actionRunFullMarketSuite(): Promise<void> {
  await requirePermission("admin.releases.write");
  await runFullMarketSuite();
  revalidateMarket();
}

export async function actionRunEdition(): Promise<void> {
  await requirePermission("admin.releases.write");
  await runEditionVerification();
  revalidateMarket();
}

export async function actionRunCompliance(): Promise<void> {
  await requirePermission("admin.releases.write");
  await runMql5ComplianceReview();
  revalidateMarket();
}

export async function actionRunAssets(): Promise<void> {
  await requirePermission("admin.releases.write");
  await runStoreAssetInventory();
  revalidateMarket();
}

export async function actionRunDocs(): Promise<void> {
  await requirePermission("admin.releases.write");
  await runDocumentationInventory();
  revalidateMarket();
}

export async function actionRunMetadata(): Promise<void> {
  await requirePermission("admin.releases.write");
  await runStoreMetadata();
  revalidateMarket();
}

export async function actionRunValidation(): Promise<void> {
  await requirePermission("admin.releases.write");
  await runCommercialValidation();
  revalidateMarket();
}

export async function actionRunSubmission(): Promise<void> {
  await requirePermission("admin.releases.write");
  await runSubmissionChecklist();
  revalidateMarket();
}

export async function actionRefreshMarketDashboard(): Promise<void> {
  await requirePermission("admin.releases.read");
  await getExecutiveMarketDashboard({ refresh: false });
  revalidateMarket();
}
