/**
 * Executive Controlled Launch Dashboard aggregations.
 */
import { getEnterpriseDashboard, getBusinessIntelligence } from "@/server/admin/ops";
import { getAdminReleaseDashboard } from "@/server/releases/release-service";
import { listSupportTickets } from "@/server/admin/support-store";
import { ensureDemoBetaParticipants, getBetaSummary } from "./beta-store";
import { ensureDemoIncidents, getIncidentSummary } from "./incident-store";
import { getFeedbackSummary } from "./feedback-store";
import { runProductionMonitoring } from "./production-monitoring";
import { getActiveLaunchMode, LAUNCH_ENVIRONMENTS } from "./environments";

export async function getExecutiveLaunchDashboard() {
  ensureDemoBetaParticipants();
  ensureDemoIncidents();

  // Await the async functions properly
  const enterprise = await getEnterpriseDashboard();
  const bi = await getBusinessIntelligence();
  const monitoring = await runProductionMonitoring(true);
  
  const releases = getAdminReleaseDashboard();
  const beta = getBetaSummary();
  const incidents = getIncidentSummary();
  const feedback = getFeedbackSummary();
  const tickets = listSupportTickets();
  const openTickets = tickets.filter((t) => t.status === "open" || t.status === "pending").length;

  // Install success proxy: update success rate when downloads exist; else 100 when no traffic
  const installSuccessRate =
    releases.totalDownloads === 0 ? 100 : Math.min(100, Math.round(releases.updateSuccessRate * 10) / 10);
  const activationSuccessRate = bi.activationRate;
  // Crash rate not instrumented on Core (frozen) — commercial portal crash proxy = unhealthy events
  const crashRate =
    monitoring.report.status === "unhealthy" ? 5 : monitoring.report.status === "degraded" ? 1 : 0;
  const updateSuccessRate = releases.updateSuccessRate;

  const env = LAUNCH_ENVIRONMENTS.find((e) => e.id === getActiveLaunchMode());

  return {
    launchMode: getActiveLaunchMode(),
    environmentName: env?.name || "Controlled Beta",
    customerAccess: env?.customerAccess || "invite_only",
    betaUsers: beta.active,
    betaTotal: beta.total,
    betaCap: beta.cohortCap,
    betaByGroup: beta.byGroup,
    activeLicenses: enterprise.activeLicenses,
    installSuccessRate,
    activationSuccessRate,
    crashRate,
    updateSuccessRate,
    supportTicketsOpen: openTickets,
    supportTicketsTotal: tickets.length,
    openIncidents: incidents.open,
    criticalIncidents: incidents.criticalOpen,
    systemHealth: monitoring.report.status,
    domains: monitoring.domains,
    feedbackAvgSatisfaction: feedback.avgSatisfaction,
    feedbackNew: feedback.newCount,
    feedbackTotal: feedback.total,
    publicStableGate: monitoring.publicStableGate,
    corePolicy: "FROZEN" as const,
    generatedAt: new Date().toISOString(),
  };
}