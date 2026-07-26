/**
 * Scalability plans — 10k → 1M users (architecture planning).
 */
import type { ScalePlan } from "./types";
import { newInfraId, readInfraStore, writeInfraStore } from "./store";

export function getScalabilityPlans(): ScalePlan[] {
  return [
    {
      tier: "users_10k",
      users: 10_000,
      assumptions: [
        "Single primary region + CDN global",
        "Supabase shared compute OK",
        "API rate limits default 120/min/key",
      ],
      upgrades: ["Baseline monitoring", "Daily backups"],
      estimatedMonthlyUsd: { low: 350, high: 800 },
    },
    {
      tier: "users_50k",
      users: 50_000,
      assumptions: ["Dual-region portal", "Redis multi-region", "PgBouncer required"],
      upgrades: ["Read replica", "WAF tuning", "Webhook worker pool ×2"],
      estimatedMonthlyUsd: { low: 900, high: 2200 },
    },
    {
      tier: "users_100k",
      users: 100_000,
      assumptions: ["Dedicated DB tier", "CDN Argo", "Horizontal API workers"],
      upgrades: ["Autoscale policies", "Shard rate-limit keys", "Regional status page"],
      estimatedMonthlyUsd: { low: 2500, high: 5500 },
    },
    {
      tier: "users_250k",
      users: 250_000,
      assumptions: ["Active-active edge", "DB HA + failover runbooks proven"],
      upgrades: ["Reserved Redis", "Object storage replication", "On-call rotation"],
      estimatedMonthlyUsd: { low: 7000, high: 14000 },
    },
    {
      tier: "users_1m_planning",
      users: 1_000_000,
      assumptions: [
        "Multi-region active-active data plane",
        "Cell-based tenancy for enterprise orgs",
        "Separate analytics warehouse",
      ],
      upgrades: [
        "Regional cells (US/EU/AP/ME)",
        "Event bus (Kafka/Pulsar-class)",
        "Dedicated edge POPs + capacity reservations",
        "Formal capacity board reviews quarterly",
      ],
      estimatedMonthlyUsd: { low: 25000, high: 60000 },
    },
  ];
}

export function recordScalingEvent(tier: string, note: string) {
  const store = readInfraStore();
  store.scalingEvents.unshift({
    id: newInfraId("scale"),
    at: new Date().toISOString(),
    tier,
    note,
  });
  writeInfraStore(store);
}

export function scalabilityScorecard() {
  const plans = getScalabilityPlans();
  return {
    plans,
    documentedTiers: plans.length,
    millionUserPlanReady: plans.some((p) => p.tier === "users_1m_planning"),
    score: plans.length === 5 ? 95 : 70,
  };
}
