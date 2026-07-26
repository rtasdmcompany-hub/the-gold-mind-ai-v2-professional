/**
 * Task 9 + OUTPUT — BI scorecard.
 */
import { savePhase11Run } from "../store";

export interface BiOutputScores {
  businessIntelligenceScore: number;
  revenueReadinessScore: number;
  commercialIntelligenceScore: number;
  executiveReportingScore: number;
  growthReadinessScore: number;
  /** Task 9 aliases */
  revenueAnalyticsScore: number;
  forecastAccuracyReadiness: number;
  customerAnalyticsScore: number;
  operationalAnalyticsScore: number;
  overallPhase11Progress: number;
}

export function computeBiScorecard(input: {
  hasExecutive: boolean;
  hasRevenue: boolean;
  hasSubscriptions: boolean;
  hasCustomers: boolean;
  hasOperations: boolean;
  reportsCount: number;
  forecastReadiness: number;
  countryKind: string;
  revenueMonths: number;
}): { rows: { area: string; score: number; note: string }[]; output: BiOutputScores; at: string } {
  const businessIntelligenceScore = input.hasExecutive && input.hasSubscriptions ? 93 : 70;
  const revenueAnalyticsScore =
    input.hasRevenue
      ? Math.min(100, 75 + input.revenueMonths * 4 + (input.countryKind === "ACTUAL" ? 5 : 0))
      : 50;
  const revenueReadinessScore = revenueAnalyticsScore;
  const customerAnalyticsScore = input.hasCustomers ? 90 : 55;
  const operationalAnalyticsScore = input.hasOperations ? 92 : 55;
  const forecastAccuracyReadiness = input.forecastReadiness;
  const executiveReportingScore = Math.min(100, 60 + input.reportsCount * 8);
  const commercialIntelligenceScore = Math.round(
    (businessIntelligenceScore + revenueAnalyticsScore + customerAnalyticsScore) / 3
  );
  const growthReadinessScore = Math.round(
    (forecastAccuracyReadiness + revenueReadinessScore + customerAnalyticsScore) / 3
  );
  const overallPhase11Progress = 35; // Sprint 2 of planned Phase 11

  const output: BiOutputScores = {
    businessIntelligenceScore,
    revenueReadinessScore,
    commercialIntelligenceScore,
    executiveReportingScore,
    growthReadinessScore,
    revenueAnalyticsScore,
    forecastAccuracyReadiness,
    customerAnalyticsScore,
    operationalAnalyticsScore,
    overallPhase11Progress,
  };

  const rows = [
    { area: "Business Intelligence", score: businessIntelligenceScore, note: "Executive + subscription dashboards" },
    { area: "Revenue Analytics", score: revenueAnalyticsScore, note: "ACTUAL ledger breakdowns" },
    { area: "Customer Analytics", score: customerAnalyticsScore, note: "DAU/WAU/MAU · retention · CSAT" },
    { area: "Operational Analytics", score: operationalAnalyticsScore, note: "Telemetry · SLA proxy · incidents" },
    { area: "Forecast Accuracy Readiness", score: forecastAccuracyReadiness, note: "History depth for OLS forecasts" },
    { area: "Executive Reporting", score: executiveReportingScore, note: `${input.reportsCount} report pack` },
  ];

  const payload = { rows, output, at: new Date().toISOString() };
  savePhase11Run("bi_scorecard", "Phase 11 Sprint 2 BI scorecard", payload);
  return payload;
}
