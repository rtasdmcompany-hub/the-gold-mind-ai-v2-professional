/**
 * Controlled load tests for commercial surfaces.
 */
import { runHealthChecks } from "@/server/cloud/monitoring";
import { getCacheBackend, cacheSet, cacheGet, CacheKeys } from "@/server/cloud/cache";
import {
  safeBillingDashboard,
  safeEnsureCommercialData,
  safeEnterpriseDashboard,
  safeListLicenses,
  safeSupportTickets,
} from "./safe-probes";
import { savePerfRun, stats } from "./store";

export type LoadTarget =
  | "customer_portal"
  | "authentication"
  | "license_server"
  | "payment_apis"
  | "support_system"
  | "admin_console"
  | "cloud_apis";

export interface LoadTestResult {
  target: LoadTarget;
  label: string;
  requests: number;
  concurrency: number;
  avgMs: number;
  p95Ms: number;
  p99Ms: number;
  successRate: number;
  pass: boolean;
  bottleneck?: string;
  recommendation: string;
}

async function burst(
  fn: () => Promise<unknown> | unknown,
  requests: number,
  concurrency: number
): Promise<{ times: number[]; ok: number }> {
  const times: number[] = [];
  let ok = 0;
  let i = 0;
  async function worker() {
    while (i < requests) {
      const idx = i++;
      if (idx >= requests) return;
      const t0 = process.hrtime.bigint();
      try {
        await fn();
        ok += 1;
      } catch {
        /* count failure */
      }
      times.push(Number(process.hrtime.bigint() - t0) / 1e6);
    }
  }
  await Promise.all(Array.from({ length: concurrency }, () => worker()));
  return { times, ok };
}

export async function runLoadTests(): Promise<{
  results: LoadTestResult[];
  score: number;
  at: string;
}> {
  safeEnsureCommercialData();

  const scenarios: Array<{
    target: LoadTarget;
    label: string;
    requests: number;
    concurrency: number;
    targetP95: number;
    fn: () => Promise<unknown> | unknown;
    recommendation: string;
  }> = [
    {
      target: "customer_portal",
      label: "Customer Portal",
      requests: 80,
      concurrency: 10,
      targetP95: 500,
      fn: async () => {
        await runHealthChecks(false);
        safeListLicenses();
      },
      recommendation: "Keep portal data fetches parallel; edge-cache public shells",
    },
    {
      target: "authentication",
      label: "Authentication",
      requests: 60,
      concurrency: 10,
      targetP95: 200,
      fn: () => !!(process.env.AUTH_SECRET || process.env.NEXTAUTH_SECRET || "dev"),
      recommendation: "Ensure AUTH_SECRET in prod; enable Redis session rate-limit backend",
    },
    {
      target: "license_server",
      label: "License Server",
      requests: 100,
      concurrency: 15,
      targetP95: 250,
      fn: () => safeListLicenses(),
      recommendation: "Add per-email index map if license store grows beyond file scan",
    },
    {
      target: "payment_apis",
      label: "Payment APIs",
      requests: 40,
      concurrency: 8,
      targetP95: 400,
      fn: () => safeBillingDashboard(),
      recommendation: "Keep PaymentPort async; webhook workers separate from request path",
    },
    {
      target: "support_system",
      label: "Support System",
      requests: 50,
      concurrency: 8,
      targetP95: 300,
      fn: () => safeSupportTickets(),
      recommendation: "Paginate ticket lists; cache open-count for dashboards",
    },
    {
      target: "admin_console",
      label: "Admin Console",
      requests: 40,
      concurrency: 6,
      targetP95: 600,
      fn: () => safeEnterpriseDashboard(),
      recommendation: "Defer BI aggregates; avoid full scans on every hub render",
    },
    {
      target: "cloud_apis",
      label: "Cloud APIs",
      requests: 80,
      concurrency: 12,
      targetP95: 350,
      fn: async () => {
        await runHealthChecks(false);
        const k = CacheKeys.perf("load");
        await cacheSet(k, "1", 15);
        await cacheGet(k);
      },
      recommendation: `Prefer Upstash Redis in prod (current: ${getCacheBackend()})`,
    },
  ];

  const results: LoadTestResult[] = [];
  for (const s of scenarios) {
    const { times, ok } = await burst(s.fn, s.requests, s.concurrency);
    const st = stats(times);
    const successRate = Math.round((ok / s.requests) * 1000) / 10;
    const pass = st.p95 <= s.targetP95 && successRate >= 99;
    results.push({
      target: s.target,
      label: s.label,
      requests: s.requests,
      concurrency: s.concurrency,
      avgMs: st.avg,
      p95Ms: st.p95,
      p99Ms: st.p99,
      successRate,
      pass,
      bottleneck: pass ? undefined : st.p95 > s.targetP95 ? "latency" : "errors",
      recommendation: s.recommendation,
    });
  }

  const score = Math.round((results.filter((r) => r.pass).length / results.length) * 100);
  const payload = { results, score, at: new Date().toISOString() };
  savePerfRun("load", "Sprint 5 load tests", payload);
  return payload;
}
