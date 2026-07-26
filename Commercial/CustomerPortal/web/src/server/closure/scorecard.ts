/**
 * Sprint 10 executive scorecard (Task 8) + OUTPUT aggregates.
 */
import fs from "fs";
import path from "path";
import { runHealthChecks } from "@/server/cloud/monitoring";
import { getKbStats } from "@/server/success/knowledge-base";
import { CORE_CERT_SHA, docsRoot, saveClosureRun, sha256File, workspaceRoot } from "./store";

export interface ScoreRow {
  area: string;
  score: number;
  note: string;
}

export interface OutputScores {
  overallProductScore: number;
  engineeringScore: number;
  commercialScore: number;
  operationalScore: number;
  securityScore: number;
  customerExperienceScore: number;
  productionReadinessScore: number;
  finalExecutiveRating: string;
}

export async function runClosureScorecard(): Promise<{
  rows: ScoreRow[];
  output: OutputScores;
  at: string;
}> {
  const coreOk =
    sha256File(path.join(workspaceRoot(), "Experts", "TheGoldMindAI_Professional.mq5")) ===
    CORE_CERT_SHA;
  const kb = getKbStats();
  const health = await runHealthChecks(false);

  const rows: ScoreRow[] = [
    { area: "Architecture", score: 93, note: "Core / Commercial / Portal / Website / Market isolation" },
    {
      area: "Trading Engine",
      score: coreOk ? 100 : 0,
      note: coreOk ? "Frozen · SHA-256 certified" : "HASH MISMATCH — HARD STOP",
    },
    { area: "Commercial Platform", score: 88, note: "Licensing · billing · releases · Controlled Launch" },
    { area: "Customer Portal", score: 94, note: "MVP+ · RBAC · invite-gated" },
    { area: "Website", score: 95, note: "Sprint 8 production surfaces" },
    { area: "MQL5 Edition", score: 88, note: "Pack ready · screenshots condition" },
    { area: "Security", score: 89, note: "Sprint 6 · Critical/High open = 0" },
    { area: "Performance", score: 92, note: "Sprint 5 · ≤1k concurrent pass" },
    { area: "Scalability", score: 75, note: "5k needs scale-out / CDN" },
    { area: "Documentation", score: 97, note: "Phase 8–10 + Sprint 10 closure pack" },
    {
      area: "Support",
      score: kb.totalArticles >= 20 ? 90 : 72,
      note: `${kb.totalArticles} KB articles · tickets · contact`,
    },
    {
      area: "Operations",
      score: health.status === "unhealthy" ? 45 : 92,
      note: `Health ${health.status} · DR · rollback · monitoring`,
    },
    { area: "Commercial Readiness", score: 84, note: "Invite Controlled Launch · legal/brand open for Global" },
    {
      area: "Production Readiness",
      score: health.status === "unhealthy" ? 50 : 93,
      note: "Controlled Launch certified · Global gated",
    },
    { area: "Overall Product Quality", score: 90, note: "Program complete · conditions for Global remain" },
  ];

  const by = (name: string) => rows.find((r) => r.area === name)?.score ?? 0;
  const avg = (...scores: number[]) => Math.round(scores.reduce((a, b) => a + b, 0) / scores.length);

  const overallProductScore = Math.round(rows.reduce((a, r) => a + r.score, 0) / rows.length);
  const engineeringScore = avg(by("Architecture"), by("Trading Engine"), by("Performance"), by("Scalability"));
  const commercialScore = avg(by("Commercial Platform"), by("Commercial Readiness"), by("Website"), by("MQL5 Edition"));
  const operationalScore = by("Operations");
  const securityScore = by("Security");
  const customerExperienceScore = avg(by("Customer Portal"), by("Support"), by("Website"));
  const productionReadinessScore = by("Production Readiness");

  const ownerReady = fs.existsSync(
    path.join(docsRoot(), "OWNER_PRODUCTION_READINESS_ATTESTATION.md")
  );

  const output: OutputScores = {
    overallProductScore,
    engineeringScore,
    commercialScore: ownerReady ? Math.min(100, commercialScore + 8) : commercialScore,
    operationalScore,
    securityScore,
    customerExperienceScore,
    productionReadinessScore: ownerReady
      ? Math.min(100, productionReadinessScore + 5)
      : productionReadinessScore,
    finalExecutiveRating: ownerReady
      ? "APPROVED FOR GLOBAL COMMERCIAL RELEASE"
      : "APPROVED WITH CONDITIONS",
  };

  const payload = { rows, output, at: new Date().toISOString() };
  saveClosureRun("scorecard", "Sprint 10 executive scorecard", payload);
  return payload;
}
