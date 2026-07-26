"use server";

import { revalidatePath } from "next/cache";
import { requirePermission } from "@/server/licensing/session";
import { runFullWebsiteLaunchSuite, getExecutiveWebsiteLaunchDashboard } from "./dashboard";
import { runWebsiteProductionReview } from "./website-review";
import { runCustomerJourneyValidation } from "./journey";
import { runCommercialWorkflowValidation } from "./workflows";
import { runProductionDeploymentReview } from "./deployment";
import { runLaunchOperationsPrep } from "./operations";
import { runProductionCertification } from "./certification";

function revalidate() {
  for (const p of [
    "/portal/admin/website-launch",
    "/portal/admin/customer-journey",
    "/portal/admin/commercial-workflows",
    "/portal/admin/production-deployment",
  ]) {
    revalidatePath(p);
  }
}

export async function actionRunFullWebsiteLaunch(): Promise<void> {
  await requirePermission("admin.launch.write");
  await runFullWebsiteLaunchSuite();
  revalidate();
}

export async function actionRunWebsiteReview(): Promise<void> {
  await requirePermission("admin.launch.write");
  await runWebsiteProductionReview();
  revalidate();
}

export async function actionRunJourney(): Promise<void> {
  await requirePermission("admin.launch.write");
  await runCustomerJourneyValidation();
  revalidate();
}

export async function actionRunWorkflows(): Promise<void> {
  await requirePermission("admin.launch.write");
  await runCommercialWorkflowValidation();
  revalidate();
}

export async function actionRunDeployment(): Promise<void> {
  await requirePermission("admin.launch.write");
  await runProductionDeploymentReview();
  revalidate();
}

export async function actionRunOperations(): Promise<void> {
  await requirePermission("admin.launch.write");
  await runLaunchOperationsPrep();
  revalidate();
}

export async function actionRunCertification(): Promise<void> {
  await requirePermission("admin.launch.write");
  await runProductionCertification();
  revalidate();
}

export async function actionRefreshWebsiteLaunch(): Promise<void> {
  await requirePermission("admin.launch.read");
  await getExecutiveWebsiteLaunchDashboard({ refresh: false });
  revalidate();
}
