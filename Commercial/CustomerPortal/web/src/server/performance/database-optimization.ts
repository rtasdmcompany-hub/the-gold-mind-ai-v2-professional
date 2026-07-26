/**
 * Database / persistence optimization review — commercial stores.
 */
import fs from "fs";
import path from "path";
import { safeBillingDashboard, safeEnsureCommercialData, safeListLicenses, safeSupportTickets } from "./safe-probes";
import { savePerfRun, stats } from "./store";

export interface DbOptimizationFinding {
  area: string;
  status: "ok" | "improve" | "risk";
  detail: string;
  recommendation: string;
}

export async function reviewDatabaseOptimization() {
  safeEnsureCommercialData();

  const samples: number[] = [];
  for (let i = 0; i < 10; i++) {
    const t0 = process.hrtime.bigint();
    safeListLicenses();
    safeBillingDashboard();
    safeSupportTickets();
    samples.push(Number(process.hrtime.bigint() - t0) / 1e6);
  }
  const st = stats(samples);

  const dataRoots = [
    process.env.LICENSE_DATA_DIR || path.join(process.cwd(), ".data", "licensing"),
    process.env.BILLING_DATA_DIR || path.join(process.cwd(), ".data", "billing"),
    process.env.SUPPORT_DATA_DIR || path.join(process.cwd(), ".data", "support"),
  ];
  const storeSizes = dataRoots.map((dir) => {
    let bytes = 0;
    if (fs.existsSync(dir)) {
      for (const f of fs.readdirSync(dir)) {
        try {
          bytes += fs.statSync(path.join(dir, f)).size;
        } catch {
          /* ignore */
        }
      }
    }
    return { dir, bytes };
  });

  const findings: DbOptimizationFinding[] = [
    {
      area: "Indexes",
      status: storeSizes.some((s) => s.bytes > 5_000_000) ? "improve" : "ok",
      detail: "Encrypted file stores use full-scan list APIs today",
      recommendation: "Add email→id secondary maps when license count > 10k",
    },
    {
      area: "Slow Queries",
      status: st.p95 > 80 ? "risk" : st.p95 > 40 ? "improve" : "ok",
      detail: `Aggregate read p95 ${st.p95.toFixed(1)}ms`,
      recommendation: "Cache dashboard aggregates 30–60s for admin hubs",
    },
    {
      area: "Connection Pooling",
      status: process.env.DATABASE_URL ? "ok" : "improve",
      detail: process.env.DATABASE_URL
        ? "External DB URL present — ensure pool max configured"
        : "File-backed stores (no SQL pool). Plan pool when migrating to Postgres/Supabase",
      recommendation: "When adopting Supabase: pooler (PgBouncer) + max 10–20 for Controlled Launch",
    },
    {
      area: "Caching",
      status: process.env.UPSTASH_REDIS_REST_URL ? "ok" : "improve",
      detail: "Hot paths should use Upstash/memory cache facade",
      recommendation: "Cache health rollups and open-ticket counts",
    },
    {
      area: "Migration Performance",
      status: "ok",
      detail: "Commercial schema migrations are additive JSON store versions",
      recommendation: "Keep versioned store migrations offline before promote",
    },
    {
      area: "Backup Speed",
      status: "ok",
      detail: `Store footprint ~${Math.round(storeSizes.reduce((a, s) => a + s.bytes, 0) / 1024)} KB`,
      recommendation: "Nightly copy of .data/** to object storage; test restore drill",
    },
  ];

  const score = Math.round(
    (findings.filter((f) => f.status === "ok").length / findings.length) * 100
  );
  const payload = { findings, queryStats: st, storeSizes, score, at: new Date().toISOString() };
  savePerfRun("database", "Sprint 5 database optimization", payload);
  return payload;
}
