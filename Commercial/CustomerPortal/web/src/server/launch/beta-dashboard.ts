/**
 * Executive Beta Dashboard aggregations — Phase 10 Sprint 2.
 */
import { runProductionMonitoring } from "./production-monitoring";
import {
  ensureDemoBetaParticipants,
  getBetaSummary,
  getEnrollmentFunnel,
  listCanonicalBetaGroups,
  BETA_GROUP_LABELS,
} from "./beta-store";
import { ensureDemoMetrics, getProductionMetrics } from "./metrics-store";
import { ensureDemoIssues, getIssueSummary } from "./issue-store";
import { ensureDemoFeedback, getFeedbackSummary } from "./feedback-store";
import { getActiveLaunchMode } from "./environments";

export async function getExecutiveBetaDashboard() {
  ensureDemoBetaParticipants();
  ensureDemoMetrics();
  ensureDemoIssues();
  ensureDemoFeedback();

  const [monitoring, beta, metrics, issues, feedback, funnel] = await Promise.all([
    runProductionMonitoring(true),
    Promise.resolve(getBetaSummary()),
    Promise.resolve(getProductionMetrics()),
    Promise.resolve(getIssueSummary()),
    Promise.resolve(getFeedbackSummary()),
    Promise.resolve(getEnrollmentFunnel()),
  ]);

  const commercialReview = {
    onboarding: beta.avgEnrollmentPct >= 70 ? "good" : beta.avgEnrollmentPct >= 40 ? "fair" : "needs_work",
    installation: metrics.installationSuccessRate >= 95 ? "good" : metrics.installationSuccessRate >= 85 ? "fair" : "needs_work",
    licensing: metrics.licenseValidationRate >= 98 ? "good" : metrics.licenseValidationRate >= 90 ? "fair" : "needs_work",
    portal: metrics.loginSuccessRate >= 98 ? "good" : "fair",
    support: metrics.supportRequests <= 5 && (feedback.dimensionAverages.supportQuality || 5) >= 4 ? "good" : "fair",
    documentation: (feedback.dimensionAverages.documentation || 0) >= 4 ? "good" : "fair",
    customerConfidence: (feedback.avgSatisfaction || 0) >= 4 ? "good" : "fair",
    brandExperience: "fair" as const, // BC-BRAND still open
  };

  return {
    launchMode: getActiveLaunchMode(),
    invitedUsers: beta.total,
    activeUsers: beta.active,
    dailyActiveUsers: beta.dau,
    installSuccess: metrics.installationSuccessRate,
    activationSuccess: metrics.activationSuccessRate,
    crashRate: metrics.crashRate,
    openIssues: issues.open,
    resolvedIssues: issues.resolved,
    p0Open: issues.p0Open,
    averageSatisfaction: feedback.avgSatisfaction,
    systemHealth: monitoring.report.status,
    betaByGroup: beta.byGroup,
    groupLabels: BETA_GROUP_LABELS,
    canonicalGroups: listCanonicalBetaGroups(),
    enrollmentFunnel: funnel,
    avgEnrollmentPct: beta.avgEnrollmentPct,
    fullyEnrolled: beta.fullyEnrolled,
    metrics,
    issues,
    feedback,
    commercialReview,
    domains: monitoring.domains,
    corePolicy: "FROZEN" as const,
    featureFreeze: true,
    generatedAt: new Date().toISOString(),
  };
}
