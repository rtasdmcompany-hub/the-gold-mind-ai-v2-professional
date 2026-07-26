"use server";

import { revalidatePath } from "next/cache";
import { requirePermission } from "@/server/licensing/session";
import { runFullPerformanceSuite, getExecutivePerformanceDashboard } from "./dashboard";
import { runPerformanceBenchmarks } from "./benchmarks";
import { runScalabilitySuite } from "./scalability";
import { runLoadTests } from "./load-test";
import { reviewDatabaseOptimization } from "./database-optimization";
import { validateCloudPerformance } from "./cloud-performance";
import { runResilienceDrills } from "./resilience";

function revalidatePerf() {
  revalidatePath("/portal/admin/performance");
  revalidatePath("/portal/admin/benchmarks");
  revalidatePath("/portal/admin/scalability");
  revalidatePath("/portal/admin/load-tests");
  revalidatePath("/portal/admin/database-optimization");
  revalidatePath("/portal/admin/cloud-performance");
  revalidatePath("/portal/admin/resilience");
}

export async function actionRunFullPerfSuite(): Promise<void> {
  await requirePermission("admin.observability.write");
  await runFullPerformanceSuite();
  revalidatePerf();
}

export async function actionRunBenchmarks(): Promise<void> {
  await requirePermission("admin.observability.write");
  await runPerformanceBenchmarks();
  revalidatePerf();
}

export async function actionRunScalability(): Promise<void> {
  await requirePermission("admin.observability.write");
  await runScalabilitySuite();
  revalidatePerf();
}

export async function actionRunLoadTests(): Promise<void> {
  await requirePermission("admin.observability.write");
  await runLoadTests();
  revalidatePerf();
}

export async function actionRunDbReview(): Promise<void> {
  await requirePermission("admin.observability.write");
  await reviewDatabaseOptimization();
  revalidatePerf();
}

export async function actionRunCloudValidation(): Promise<void> {
  await requirePermission("admin.observability.write");
  await validateCloudPerformance();
  revalidatePerf();
}

export async function actionRunResilience(): Promise<void> {
  await requirePermission("admin.observability.write");
  await runResilienceDrills();
  revalidatePerf();
}

export async function actionRefreshPerfDashboard(): Promise<void> {
  await requirePermission("admin.observability.read");
  await getExecutivePerformanceDashboard({ refresh: false });
  revalidatePerf();
}
