/**
 * Executive Performance Dashboard aggregations.
 */
import { getUptimeSec } from "@/server/cloud/gateway";
import { runHealthChecks } from "@/server/cloud/monitoring";
import { latestPerfRun, listPerfRuns } from "./store";
import { runPerformanceBenchmarks } from "./benchmarks";
import { runScalabilitySuite } from "./scalability";
import { runLoadTests } from "./load-test";
import { reviewDatabaseOptimization } from "./database-optimization";
import { validateCloudPerformance } from "./cloud-performance";
import { runResilienceDrills } from "./resilience";

export async function ensureSprint5Evidence(force = false) {
  if (!force && latestPerfRun("benchmark") && latestPerfRun("scalability") && latestPerfRun("load")) {
    return;
  }
  await runPerformanceBenchmarks();
  await runScalabilitySuite();
  await runLoadTests();
  await reviewDatabaseOptimization();
  await validateCloudPerformance();
  await runResilienceDrills();
}

export async function getExecutivePerformanceDashboard(options?: { refresh?: boolean }) {
  await ensureSprint5Evidence(!!options?.refresh);

  const bench = latestPerfRun("benchmark")?.payload as
    | { results: Array<{ avgMs: number; p95Ms: number; pass: boolean }>; score: number }
    | undefined;
  const scale = latestPerfRun("scalability")?.payload as
    | {
        points: Array<{ concurrentUsers: number; p95ResponseMs: number; pass: boolean; cpuUsagePct: number; memoryUsageMb: number }>;
        score: number;
      }
    | undefined;
  const load = latestPerfRun("load")?.payload as
    | { results: Array<{ avgMs: number; p95Ms: number; p99Ms: number; successRate: number; pass: boolean }>; score: number }
    | undefined;
  const db = latestPerfRun("database")?.payload as { score: number } | undefined;
  const cloud = latestPerfRun("cloud")?.payload as { score: number } | undefined;
  const res = latestPerfRun("resilience")?.payload as { score: number } | undefined;

  const allLatencies = [
    ...(bench?.results || []).map((r) => r.avgMs),
    ...(load?.results || []).map((r) => r.avgMs),
  ].filter((n) => typeof n === "number");
  const p95s = [
    ...(bench?.results || []).map((r) => r.p95Ms),
    ...(load?.results || []).map((r) => r.p95Ms),
  ];
  const p99s = (load?.results || []).map((r) => r.p99Ms);

  const avg = (arr: number[]) => (arr.length ? Math.round((arr.reduce((a, b) => a + b, 0) / arr.length) * 10) / 10 : 0);
  const peak = scale?.points?.length ? Math.max(...scale.points.map((p) => p.concurrentUsers)) : 0;
  const peakPoint = scale?.points?.find((p) => p.concurrentUsers === 1000) || scale?.points?.[0];
  const health = await runHealthChecks(false);
  const apiSuccess =
    load?.results?.length
      ? Math.round((load.results.reduce((a, r) => a + r.successRate, 0) / load.results.length) * 10) / 10
      : 100;

  return {
    averageResponseTime: avg(allLatencies),
    p95ResponseTime: avg(p95s),
    p99ResponseTime: avg(p99s),
    peakConcurrentUsers: peak,
    systemUptimeSec: getUptimeSec(),
    cpuUtilization: peakPoint?.cpuUsagePct ?? 0,
    memoryUtilization: peakPoint?.memoryUsageMb ?? 0,
    databaseLoad: scale?.points?.[0]?.p95ResponseMs ? "see scalability db ms" : "n/a",
    databaseMs: scale?.points?.find((p) => p.concurrentUsers === 100)?.p95ResponseMs,
    apiSuccessRate: apiSuccess,
    platformHealth: health.status,
    scores: {
      performance: bench?.score ?? 0,
      scalability: scale?.score ?? 0,
      load: load?.score ?? 0,
      database: db?.score ?? 0,
      cloud: cloud?.score ?? 0,
      resilience: res?.score ?? 0,
    },
    coreIsolation: "Performance suite never imports or modifies Core Trading Engine",
    runs: listPerfRuns().slice(0, 12).map((r) => ({ id: r.id, kind: r.kind, label: r.label, at: r.at })),
    generatedAt: new Date().toISOString(),
  };
}

export async function runFullPerformanceSuite() {
  const benchmark = await runPerformanceBenchmarks();
  const scalability = await runScalabilitySuite();
  const load = await runLoadTests();
  const database = await reviewDatabaseOptimization();
  const cloud = await validateCloudPerformance();
  const resilience = await runResilienceDrills();
  const dashboard = await getExecutivePerformanceDashboard();
  return { benchmark, scalability, load, database, cloud, resilience, dashboard };
}
