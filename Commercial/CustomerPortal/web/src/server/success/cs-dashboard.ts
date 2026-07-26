/**
 * Executive Customer Success / Stabilization dashboard.
 */
import { getCustomerSuccessSummary } from "./customer-health";
import { getSupportAnalytics } from "./support-analytics";
import { getProductionStabilization } from "./production-stabilization";
import { getIssueSummary, ensureDemoIssues } from "@/server/launch/issue-store";
import { getFeedbackSummary, ensureDemoFeedback } from "@/server/launch/feedback-store";
import { getKbStats } from "./knowledge-base";
import { getUsageAnalytics, ensureDemoUsage } from "@/server/observability/usage-analytics";
import { runHealthChecks } from "@/server/cloud/monitoring";

export async function getSuccessExecutiveDashboard() {
  ensureDemoIssues();
  ensureDemoFeedback();
  ensureDemoUsage();

  const [cs, support, stab, issues, feedback, kb, usage, health] = await Promise.all([
    Promise.resolve(getCustomerSuccessSummary()),
    Promise.resolve(getSupportAnalytics()),
    getProductionStabilization(),
    Promise.resolve(getIssueSummary()),
    Promise.resolve(getFeedbackSummary()),
    Promise.resolve(getKbStats()),
    Promise.resolve(getUsageAnalytics()),
    runHealthChecks(false),
  ]);

  return {
    customerSatisfaction: feedback.avgSatisfaction ?? support.customerSatisfaction,
    resolvedIssues: issues.resolved,
    openP0: issues.p0Open,
    openP1: issues.p1Open,
    supportSla: {
      firstResponseHrs: support.firstResponseTimeHrs,
      resolutionHrs: support.resolutionTimeHrs,
      firstResponseMet: support.slaFirstResponseMet,
      resolutionMet: support.slaResolutionMet,
    },
    productStability: stab.productStabilityScore,
    platformHealth: health.status,
    retention: usage.retentionTrends,
    avgCustomerHealth: cs.avgHealthScore,
    kbArticles: kb.totalArticles,
    kbViews: kb.totalViews,
    customersTracked: cs.customersTracked,
    atRiskCustomers: cs.atRisk,
    corePolicy: "FROZEN" as const,
    featureFreeze: true,
    generatedAt: new Date().toISOString(),
  };
}
