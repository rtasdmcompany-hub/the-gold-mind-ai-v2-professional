"use server";

import { revalidatePath } from "next/cache";
import { requirePermission } from "@/server/licensing/session";
import { runFullSecuritySuite, getExecutiveSecurityDashboard } from "./dashboard";
import { runSecurityAssessment } from "./assessment";
import { runPenetrationTests } from "./penetration";
import { runOwaspReview } from "./owasp";
import { runSecretManagementReview } from "./secrets-review";
import { runDataProtectionReview } from "./data-protection";
import { runDisasterRecoveryValidation } from "./disaster-recovery";
import { runComplianceReview } from "./compliance";

function revalidateSec() {
  for (const p of [
    "/portal/admin/security-audit",
    "/portal/admin/pentest",
    "/portal/admin/owasp",
    "/portal/admin/secret-management",
    "/portal/admin/disaster-recovery",
    "/portal/admin/compliance",
    "/portal/admin/data-protection",
  ]) {
    revalidatePath(p);
  }
}

export async function actionRunFullSecuritySuite(): Promise<void> {
  await requirePermission("admin.security.manage");
  await runFullSecuritySuite();
  revalidateSec();
}

export async function actionRunAssessment(): Promise<void> {
  await requirePermission("admin.security.manage");
  await runSecurityAssessment();
  revalidateSec();
}

export async function actionRunPentest(): Promise<void> {
  await requirePermission("admin.security.manage");
  await runPenetrationTests();
  revalidateSec();
}

export async function actionRunOwasp(): Promise<void> {
  await requirePermission("admin.security.manage");
  await runOwaspReview();
  revalidateSec();
}

export async function actionRunSecrets(): Promise<void> {
  await requirePermission("admin.security.manage");
  await runSecretManagementReview();
  revalidateSec();
}

export async function actionRunDataProtection(): Promise<void> {
  await requirePermission("admin.security.manage");
  await runDataProtectionReview();
  revalidateSec();
}

export async function actionRunDr(): Promise<void> {
  await requirePermission("admin.security.manage");
  await runDisasterRecoveryValidation();
  revalidateSec();
}

export async function actionRunCompliance(): Promise<void> {
  await requirePermission("admin.security.manage");
  await runComplianceReview();
  revalidateSec();
}

export async function actionRefreshSecurityDashboard(): Promise<void> {
  await requirePermission("admin.security.manage");
  await getExecutiveSecurityDashboard({ refresh: false });
  revalidateSec();
}
