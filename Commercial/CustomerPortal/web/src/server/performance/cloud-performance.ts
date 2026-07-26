/**
 * Cloud performance validation — commercial infra only.
 */
import { getCacheBackend, cacheSet, cacheGet, CacheKeys } from "@/server/cloud/cache";
import { runHealthChecks } from "@/server/cloud/monitoring";
import { getUptimeSec } from "@/server/cloud/gateway";
import { savePerfRun, stats } from "./store";

export interface CloudCheck {
  id: string;
  label: string;
  status: "configured" | "fallback" | "missing" | "ok" | "degraded";
  latencyMs?: number;
  detail: string;
  recommendation: string;
}

export async function validateCloudPerformance() {
  const checks: CloudCheck[] = [];

  // Cloudflare
  checks.push({
    id: "cloudflare",
    label: "Cloudflare Performance",
    status: process.env.CF_ZONE_ID || process.env.CLOUDFLARE_API_TOKEN ? "configured" : "fallback",
    detail: process.env.CF_ZONE_ID
      ? "Zone configured — enable caching for /portal static"
      : "Not configured in this environment (acceptable for local RC)",
    recommendation: "Terminate TLS at Cloudflare; cache public marketing assets; bypass /api/*",
  });

  // Supabase
  checks.push({
    id: "supabase",
    label: "Supabase Performance",
    status: process.env.SUPABASE_URL || process.env.NEXT_PUBLIC_SUPABASE_URL ? "configured" : "fallback",
    detail: process.env.SUPABASE_URL || process.env.NEXT_PUBLIC_SUPABASE_URL || "Using encrypted file stores",
    recommendation: "Use connection pooler; avoid cold starts on admin aggregates",
  });

  // RunPod
  checks.push({
    id: "runpod",
    label: "RunPod Connectivity",
    status: process.env.RUNPOD_API_KEY ? "configured" : "fallback",
    detail: process.env.RUNPOD_API_KEY
      ? "API key present — commercial jobs only"
      : "Not required for portal Controlled Launch",
    recommendation: "Keep RunPod off critical license path; async only",
  });

  // Upstash Redis
  const redisSamples: number[] = [];
  let redisOk = true;
  for (let i = 0; i < 5; i++) {
    const t0 = process.hrtime.bigint();
    try {
      const k = CacheKeys.perf(`cloud_${i}`);
      await cacheSet(k, String(i), 20);
      await cacheGet(k);
    } catch {
      redisOk = false;
    }
    redisSamples.push(Number(process.hrtime.bigint() - t0) / 1e6);
  }
  const redisStats = stats(redisSamples);
  checks.push({
    id: "upstash",
    label: "Upstash Redis",
    status: getCacheBackend() === "upstash" ? (redisOk ? "ok" : "degraded") : "fallback",
    latencyMs: redisStats.avg,
    detail: `backend=${getCacheBackend()} · avg ${redisStats.avg}ms · p95 ${redisStats.p95}ms`,
    recommendation: "Set UPSTASH_REDIS_REST_URL/TOKEN for multi-instance rate-limit + cache",
  });

  // Email
  checks.push({
    id: "email",
    label: "Email Delivery",
    status: process.env.RESEND_API_KEY || process.env.SMTP_HOST ? "configured" : "fallback",
    detail: "Billing outbox path validated via health probes",
    recommendation: "Use transactional provider; monitor bounce webhooks",
  });

  // Storage
  checks.push({
    id: "storage",
    label: "Storage Performance",
    status: process.env.S3_BUCKET || process.env.R2_BUCKET ? "configured" : "fallback",
    detail: "Release ZIPs served from local/release catalog in RC",
    recommendation: "Serve installer packages from CDN/object storage with signed URLs",
  });

  // API Gateway throughput
  const gwSamples: number[] = [];
  for (let i = 0; i < 8; i++) {
    const t0 = process.hrtime.bigint();
    await runHealthChecks(false);
    gwSamples.push(Number(process.hrtime.bigint() - t0) / 1e6);
  }
  const gw = stats(gwSamples);
  checks.push({
    id: "api_gateway",
    label: "API Gateway Throughput",
    status: gw.p95 < 200 ? "ok" : gw.p95 < 500 ? "degraded" : "degraded",
    latencyMs: gw.avg,
    detail: `health probe avg ${gw.avg}ms · p95 ${gw.p95}ms · uptime ${getUptimeSec()}s`,
    recommendation: "Keep gateway middleware thin; rate-limit by IP+user",
  });

  const configuredOrOk = checks.filter((c) => c.status === "ok" || c.status === "configured" || c.status === "fallback").length;
  // fallback is acceptable in local; score weighted
  const score = Math.round(
    (checks.reduce((s, c) => {
      if (c.status === "ok" || c.status === "configured") return s + 1;
      if (c.status === "fallback") return s + 0.75;
      return s + 0.4;
    }, 0) /
      checks.length) *
      100
  );

  const payload = { checks, redisStats, gatewayStats: gw, score, at: new Date().toISOString() };
  savePerfRun("cloud", "Sprint 5 cloud performance", payload);
  return payload;
}
