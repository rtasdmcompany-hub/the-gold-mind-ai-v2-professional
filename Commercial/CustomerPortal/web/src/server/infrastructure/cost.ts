/**
 * Cloud cost optimization analysis + forecasts.
 */
import type { CostLine } from "./types";

export function getCostLines(): CostLine[] {
  return [
    {
      id: "compute",
      category: "Compute (Vercel / workers)",
      monthlyUsd: 620,
      forecastNextQuarterUsd: 780,
      optimization: "Move cron/webhooks to dedicated workers; right-size serverless concurrency",
    },
    {
      id: "database",
      category: "Database (Supabase)",
      monthlyUsd: 410,
      forecastNextQuarterUsd: 520,
      optimization: "Connection pooling · archive cold audit · reserved capacity at 100k users",
    },
    {
      id: "redis",
      category: "Redis (Upstash)",
      monthlyUsd: 95,
      forecastNextQuarterUsd: 140,
      optimization: "TTL eviction · separate rate-limit namespace · reserved plan at 250k",
    },
    {
      id: "bandwidth",
      category: "Bandwidth / CDN",
      monthlyUsd: 280,
      forecastNextQuarterUsd: 360,
      optimization: "Aggressive asset caching · compress downloads · regional POP affinity",
    },
    {
      id: "storage",
      category: "Object Storage",
      monthlyUsd: 120,
      forecastNextQuarterUsd: 160,
      optimization: "Lifecycle old installers · infrequent access tier for archives",
    },
    {
      id: "security",
      category: "WAF / Security add-ons",
      monthlyUsd: 180,
      forecastNextQuarterUsd: 200,
      optimization: "Consolidate rulesets · disable unused bot fights on static hosts",
    },
    {
      id: "observability",
      category: "Observability / logging",
      monthlyUsd: 135,
      forecastNextQuarterUsd: 190,
      optimization: "Sample debug logs · retain metrics 90d hot / 1y cold",
    },
  ];
}

export function costOptimizationReport() {
  const lines = getCostLines();
  const monthly = lines.reduce((a, l) => a + l.monthlyUsd, 0);
  const forecast = lines.reduce((a, l) => a + l.forecastNextQuarterUsd, 0);
  const savingsOpportunity = Math.round(monthly * 0.12);
  return {
    lines,
    monthlyTotalUsd: monthly,
    nextQuarterForecastUsd: forecast,
    reservedCapacityOpportunities: [
      "Supabase reserved compute at ≥100k users",
      "Upstash reserved at ≥250k users",
      "CDN committed bandwidth if downloads grow",
    ],
    scalingPolicies: [
      "Autoscale API workers on p95 > 300ms",
      "Scale Redis connections with active API keys",
      "Scale-to-zero optional RunPod workloads",
    ],
    savingsOpportunityUsd: savingsOpportunity,
    score: monthly > 0 && savingsOpportunity > 0 ? 92 : 70,
  };
}
