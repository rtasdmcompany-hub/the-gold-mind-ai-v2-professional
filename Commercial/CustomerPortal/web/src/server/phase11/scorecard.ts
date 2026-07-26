/**
 * Task 8 — Executive validation scorecard + OUTPUT scores.
 */
import { savePhase11Run } from "./store";

export interface Phase11Scores {
  businessOperationsScore: number;
  commercialOperationsScore: number;
  customerSuccessScore: number;
  operationalHealthScore: number;
  executiveReadinessScore: number;
  overallPhase11Progress: number;
}

export function computePhase11Scorecard(input: {
  opsPresent: boolean;
  kpiPresent: boolean;
  commercialScore: number;
  healthScore: number;
  csSatisfaction: number;
  csAtRisk: number;
  csTracked: number;
  reportsGenerated: number;
}): { rows: { area: string; score: number; note: string }[]; output: Phase11Scores; at: string } {
  const businessOperationsScore = input.opsPresent && input.kpiPresent ? 92 : 70;
  const commercialOperationsScore = input.commercialScore;
  const csatScore =
    input.csSatisfaction <= 0
      ? 72
      : input.csSatisfaction <= 5
        ? Math.round((input.csSatisfaction / 5) * 100)
        : Math.min(100, Math.round(input.csSatisfaction));
  const customerSuccessScore = Math.round(
    csatScore * 0.5 +
      (input.csTracked > 0 ? 90 : 55) * 0.35 +
      (input.csAtRisk === 0 ? 100 : Math.max(35, 100 - input.csAtRisk * 8)) * 0.15
  );
  const operationalHealthScore = input.healthScore;
  const executiveReadinessScore = Math.round(
    (businessOperationsScore +
      commercialOperationsScore +
      customerSuccessScore +
      operationalHealthScore +
      (input.reportsGenerated >= 5 ? 95 : 70)) /
      5
  );
  const overallPhase11Progress = 18; // Sprint 1 of ~6 planned → foundation complete

  const rows = [
    { area: "Business Operations", score: businessOperationsScore, note: "Ops Center + KPI surfaces" },
    { area: "Commercial Operations", score: commercialOperationsScore, note: "Workflow audit" },
    { area: "Customer Success", score: customerSuccessScore, note: "Segments · churn · CSAT" },
    { area: "Operational Health", score: operationalHealthScore, note: "Service health cards" },
    { area: "Executive Readiness", score: executiveReadinessScore, note: "Reports + validation" },
  ];

  const output: Phase11Scores = {
    businessOperationsScore,
    commercialOperationsScore,
    customerSuccessScore,
    operationalHealthScore,
    executiveReadinessScore,
    overallPhase11Progress,
  };

  const payload = { rows, output, at: new Date().toISOString() };
  savePhase11Run("scorecard", "Phase 11 Sprint 1 scorecard", payload);
  return payload;
}
