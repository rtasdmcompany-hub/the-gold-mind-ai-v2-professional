/**
 * AI administration analytics — usage, feedback, coverage, health.
 */
import { readAiStore } from "./store";
import { knowledgeCoverageReport } from "./knowledge";
import { securityPolicySummary } from "./security";
import { AI_TRADING_PROHIBITED } from "./types";

export function buildAiAdminDashboard() {
  const store = readAiStore();
  const convs = store.conversations;
  const messages = convs.reduce((a, c) => a + c.messages.length, 0);
  const assistantMsgs = convs.flatMap((c) => c.messages.filter((m) => m.role === "assistant"));
  const blocked = assistantMsgs.filter((m) => m.blocked).length;
  const avgConfidence =
    assistantMsgs.filter((m) => typeof m.confidence === "number").length === 0
      ? 0
      : assistantMsgs
          .filter((m) => typeof m.confidence === "number")
          .reduce((a, m) => a + (m.confidence || 0), 0) /
        assistantMsgs.filter((m) => typeof m.confidence === "number").length;

  const bySurface: Record<string, number> = {};
  for (const c of convs) bySurface[c.surface] = (bySurface[c.surface] || 0) + 1;

  const ratings = store.feedback.map((f) => f.rating);
  const avgCsat =
    ratings.length === 0 ? 0 : Math.round((ratings.reduce((a, r) => a + r, 0) / ratings.length) * 10) / 10;

  const escalated = convs.filter((c) => c.status === "escalated").length;
  const coverage = knowledgeCoverageReport();

  const health = {
    status: "healthy" as const,
    tradingProhibited: AI_TRADING_PROHIBITED,
    knowledgeDocs: coverage.total,
    encryption: "AES-256-GCM",
    auditEntries: store.audit.length,
    unansweredOpen: store.unanswered.length,
    rateBuckets: Object.keys(store.rateBuckets).length,
  };

  return {
    usage: {
      conversations: convs.length,
      messages,
      bySurface,
      blockedReplies: blocked,
      avgConfidence: Math.round(avgConfidence * 1000) / 1000,
      escalated,
    },
    feedback: {
      count: store.feedback.length,
      averageCsat: avgCsat,
      recent: store.feedback.slice(0, 10),
    },
    knowledgeCoverage: coverage,
    unanswered: store.unanswered.slice(0, 20),
    health,
    security: securityPolicySummary(),
    recentAudit: store.audit.slice(0, 15),
    at: new Date().toISOString(),
  };
}
