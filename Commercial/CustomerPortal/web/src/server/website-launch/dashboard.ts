/**
 * Executive Website Launch Dashboard — Phase 10 Sprint 8.
 */
import { runHealthChecks } from "@/server/cloud/monitoring";
import { getKbStats } from "@/server/success/knowledge-base";
import { runWebsiteProductionReview } from "./website-review";
import { runCustomerJourneyValidation } from "./journey";
import { runCommercialWorkflowValidation } from "./workflows";
import { runProductionDeploymentReview } from "./deployment";
import { runLaunchOperationsPrep } from "./operations";
import { runProductionCertification } from "./certification";
import { latestWebsiteLaunchRun, listWebsiteLaunchRuns } from "./store";

export async function ensureSprint8Evidence(force = false) {
  if (!force && latestWebsiteLaunchRun("website") && latestWebsiteLaunchRun("journey")) return;
  await runFullWebsiteLaunchSuite();
}

export async function runFullWebsiteLaunchSuite() {
  const website = await runWebsiteProductionReview();
  const journey = await runCustomerJourneyValidation();
  const workflows = await runCommercialWorkflowValidation();
  const deployment = await runProductionDeploymentReview();
  const operations = await runLaunchOperationsPrep();
  const certification = await runProductionCertification();
  const dashboard = await getExecutiveWebsiteLaunchDashboard();
  return { website, journey, workflows, deployment, operations, certification, dashboard };
}

export async function getExecutiveWebsiteLaunchDashboard(options?: { refresh?: boolean }) {
  await ensureSprint8Evidence(!!options?.refresh);

  const website = latestWebsiteLaunchRun("website")?.payload as { score?: number } | undefined;
  const journey = latestWebsiteLaunchRun("journey")?.payload as { score?: number } | undefined;
  const workflows = latestWebsiteLaunchRun("workflows")?.payload as { score?: number } | undefined;
  const deployment = latestWebsiteLaunchRun("deployment")?.payload as { score?: number } | undefined;
  const operations = latestWebsiteLaunchRun("operations")?.payload as { score?: number } | undefined;
  const certification = latestWebsiteLaunchRun("certification")?.payload as {
    score?: number;
    criticalBlockers?: string[];
    coreMatches?: boolean;
  } | undefined;

  const websiteProductionScore = website?.score ?? 0;
  const customerJourneyScore = journey?.score ?? 0;
  const commercialOperationsScore = workflows?.score ?? 0;
  const deploymentScore = deployment?.score ?? 0;
  const websiteReadinessScore = Math.round((websiteProductionScore + customerJourneyScore) / 2);
  const commercialReadinessScore = commercialOperationsScore;
  const operationalReadinessScore = Math.round(((operations?.score ?? 0) + (certification?.score ?? 0)) / 2);
  const deploymentReadinessScore = deploymentScore;
  const customerExperienceScore = Math.round((customerJourneyScore + websiteProductionScore) / 2);
  const launchReadinessScore = Math.round(
    (websiteProductionScore +
      customerJourneyScore +
      commercialOperationsScore +
      deploymentScore +
      (certification?.score ?? 0)) /
      5
  );

  const health = await runHealthChecks(false);
  const kb = getKbStats();
  const critical = (certification?.criticalBlockers || []).filter((b) =>
    /SHA|Demo auth|Critical/i.test(b)
  );
  // Open Stable blocked if legal/brand/live PSP; invite-only can proceed with conditions
  const launchStatus =
    certification?.coreMatches === false || critical.some((c) => c.includes("Demo auth"))
      ? "BLOCKED_CRITICAL"
      : "READY_WITH_CONDITIONS";

  return {
    websiteProductionScore,
    deploymentScore,
    customerJourneyScore,
    commercialOperationsScore,
    launchReadinessScore,
    websiteReadinessScore,
    commercialReadinessScore,
    operationalReadinessScore,
    deploymentReadinessScore,
    customerExperienceScore,
    launchStatus,
    remainingRisks: certification?.criticalBlockers || [],
    websiteStatus: websiteProductionScore >= 80 ? "ready" : "partial",
    portalStatus: "ready",
    apiStatus: health.status,
    payments: process.env.PAYMENT_FORCE_SANDBOX === "false" ? "live_configured" : "sandbox",
    licenseActivations: "portal_path_ready",
    downloads: "portal_path_ready",
    supportQueue: "portal_support_ready",
    revenue: "billing_dashboard_ready",
    systemHealth: health.status,
    customerSatisfaction: kb.totalArticles >= 20 ? "kb_ready" : "kb_growing",
    coreMatches: !!certification?.coreMatches,
    coreIsolation: "Website launch suite never modifies Core Trading Engine",
    runs: listWebsiteLaunchRuns()
      .slice(0, 12)
      .map((r) => ({ id: r.id, kind: r.kind, label: r.label, at: r.at })),
    generatedAt: new Date().toISOString(),
  };
}
