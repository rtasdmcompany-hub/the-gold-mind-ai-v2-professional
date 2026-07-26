/**
 * Support analytics — commercial support ops only.
 */
import { listSupportTickets } from "@/server/admin/support-store";
import { getFeedbackSummary } from "@/server/launch/feedback-store";
import { getKbStats } from "./knowledge-base";

function hoursBetween(a: string, b: string): number {
  return Math.max(0, (Date.parse(b) - Date.parse(a)) / 3600000);
}

export function getSupportAnalytics() {
  const tickets = listSupportTickets();
  const withResponse = tickets.filter((t) => t.firstRespondedAt);
  const firstResponseHrs =
    withResponse.length === 0
      ? 0
      : Math.round(
          (withResponse.reduce((s, t) => s + hoursBetween(t.createdAt, t.firstRespondedAt!), 0) /
            withResponse.length) *
            10
        ) / 10;

  const resolved = tickets.filter((t) => t.status === "resolved" || t.status === "closed");
  const resolutionHrs =
    resolved.length === 0
      ? 0
      : Math.round(
          (resolved.reduce((s, t) => s + hoursBetween(t.createdAt, t.resolvedAt || t.updatedAt), 0) /
            resolved.length) *
            10
        ) / 10;

  const reopened = tickets.reduce((s, t) => s + (t.reopenedCount || 0), 0);
  const escalated = tickets.filter((t) => t.priority === "urgent" || t.priority === "high").length;
  const escalationRate =
    tickets.length === 0 ? 0 : Math.round((escalated / tickets.length) * 1000) / 10;

  const fb = getFeedbackSummary();
  const kb = getKbStats();

  return {
    firstResponseTimeHrs: firstResponseHrs,
    resolutionTimeHrs: resolutionHrs,
    customerSatisfaction: fb.avgSatisfaction ?? fb.dimensionAverages.supportQuality,
    reopenedTickets: reopened,
    escalationRate,
    knowledgeBaseUsage: kb.totalViews,
    openTickets: tickets.filter((t) => t.status === "open" || t.status === "pending").length,
    totalTickets: tickets.length,
    resolvedTickets: resolved.length,
    slaTargetHrs: { firstResponse: 4, resolution: 48 },
    slaFirstResponseMet: firstResponseHrs === 0 || firstResponseHrs <= 4,
    slaResolutionMet: resolutionHrs === 0 || resolutionHrs <= 48,
  };
}
