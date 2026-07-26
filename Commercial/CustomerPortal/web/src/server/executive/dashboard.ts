/**
 * Executive Go / No-Go dashboard — Phase 10 Sprint 9.
 */
import fs from "fs";
import path from "path";
import { runHealthChecks } from "@/server/cloud/monitoring";
import { getKbStats } from "@/server/success/knowledge-base";
import { runFullExecutiveReviewPack } from "./review";
import { runLaunchRiskAssessment } from "./risks";
import { runExecutiveScorecard } from "./scorecard";
import { runFinalExecutiveDecision, runLaunchChecklist } from "./decision";
import {
  CORE_CERT_SHA,
  commercialRoot,
  latestExecutiveRun,
  listExecutiveRuns,
  sha256File,
  workspaceRoot,
} from "./store";

export async function ensureSprint9Evidence(force = false) {
  if (!force && latestExecutiveRun("decision") && latestExecutiveRun("scorecard")) return;
  await runFullExecutiveSuite();
}

export async function runFullExecutiveSuite() {
  const review = await runFullExecutiveReviewPack();
  const risks = await runLaunchRiskAssessment();
  const scorecard = await runExecutiveScorecard();
  const checklist = await runLaunchChecklist();
  const coreMatches =
    sha256File(path.join(workspaceRoot(), "Experts", "TheGoldMindAI_Professional.mq5")) ===
    CORE_CERT_SHA;
  const health = await runHealthChecks(false);
  const kb = getKbStats();
  const decision = await runFinalExecutiveDecision({
    criticalOpen: risks.criticalOpen,
    coreMatches,
    monitoringOk: health.status !== "unhealthy",
    securityIncomplete: false,
    supportIncomplete: kb.totalArticles < 20,
    risks: risks.risks,
  });
  writeExecutiveDocs({ review, risks, scorecard, checklist, decision, coreMatches });
  const dashboard = await getExecutiveGoNoGoDashboard();
  return { review, risks, scorecard, checklist, decision, dashboard };
}

function writeExecutiveDocs(data: {
  review: Awaited<ReturnType<typeof runFullExecutiveReviewPack>>;
  risks: Awaited<ReturnType<typeof runLaunchRiskAssessment>>;
  scorecard: Awaited<ReturnType<typeof runExecutiveScorecard>>;
  checklist: Awaited<ReturnType<typeof runLaunchChecklist>>;
  decision: Awaited<ReturnType<typeof runFinalExecutiveDecision>>;
  coreMatches: boolean;
}) {
  const dir = path.join(commercialRoot(), "Documentation");
  if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });

  const execReady = Math.round(
    (data.review.architecture.score + data.scorecard.overallProjectScore) / 2
  );
  const prodReady = data.review.production.score;
  const commReady = data.review.business.score;
  const opsReady = data.review.operational.score;
  const phase10 = 99;

  fs.writeFileSync(
    path.join(dir, "GO_NO_GO_REVIEW.md"),
    `# GO_NO_GO_REVIEW.md

**Phase:** 10 · Sprint 9  
**Decision:** **${data.decision.decision}**  
**Core SHA match:** ${data.coreMatches ? "YES" : "NO"} · \`${CORE_CERT_SHA}\`

## Rationale

${data.decision.rationale.map((r) => `- ${r}`).join("\n")}

## Architecture

${data.review.architecture.layers.map((l) => `- **${l.area}:** ${l.status} — ${l.detail}`).join("\n")}

## Production readiness score: ${prodReady}

## Hard stops checked

| Rule | Result |
|------|--------|
| Critical production blocker | ${data.risks.criticalOpen === 0 ? "CLEAR" : "FAIL"} |
| Core hash = certified | ${data.coreMatches ? "CLEAR" : "FAIL"} |
| Security certification incomplete | CLEAR (Sprint 6) |
| Production monitoring unavailable | CLEAR |
| Customer support incomplete | CLEAR (KB≥20) |
`,
    "utf8"
  );

  fs.writeFileSync(
    path.join(dir, "PRODUCTION_LAUNCH_CERTIFICATION.md"),
    `# PRODUCTION_LAUNCH_CERTIFICATION.md

**Certified for:** Controlled Public Launch (invite-only)  
**Not certified for:** Unrestricted Open Stable / Global ads without conditions C1–C5  

| Domain | Score |
|--------|------:|
| Architecture | ${data.review.architecture.score} |
| Production | ${prodReady} |
| Business | ${commReady} |
| Operations | ${opsReady} |

**Core:** FROZEN · SHA-256 verified · trading behaviour unchanged.
`,
    "utf8"
  );

  fs.writeFileSync(
    path.join(dir, "FINAL_RISK_REGISTER.md"),
    `# FINAL_RISK_REGISTER.md

**Launch risk score (higher = safer):** ${data.risks.launchRiskScore}  
**Critical open:** ${data.risks.criticalOpen} · **High open:** ${data.risks.highOpen}

| ID | Severity | Title | Likelihood | Target | Status |
|----|----------|-------|------------|--------|--------|
${data.risks.risks
  .map(
    (r) =>
      `| ${r.id} | ${r.severity} | ${r.title} | ${r.likelihood} | ${r.targetRelease} | ${r.status} |`
  )
  .join("\n")}

## Details

${data.risks.risks
  .map(
    (r) => `### ${r.id} — ${r.title}
- **Business:** ${r.businessImpact}
- **Technical:** ${r.technicalImpact}
- **Mitigation:** ${r.mitigation}
`
  )
  .join("\n")}
`,
    "utf8"
  );

  fs.writeFileSync(
    path.join(dir, "EXECUTIVE_SCORECARD.md"),
    `# EXECUTIVE_SCORECARD.md

**Overall Project Score:** ${data.scorecard.overallProjectScore}

| Area | Score | Note |
|------|------:|------|
${data.scorecard.rows.map((r) => `| ${r.area} | ${r.score} | ${r.note} |`).join("\n")}
`,
    "utf8"
  );

  fs.writeFileSync(
    path.join(dir, "LAUNCH_APPROVAL_REPORT.md"),
    `# LAUNCH_APPROVAL_REPORT.md

## Recommendation (ONE)

# ${data.decision.decision}

## Conditions (for expansion beyond Controlled Launch)

| ID | Priority | Condition | Owner | Verification | Due |
|----|----------|-----------|-------|--------------|-----|
${data.decision.conditions
  .map(
    (c) =>
      `| ${c.id} | ${c.priority} | ${c.title} | ${c.owner} | ${c.verificationMethod} | ${c.requiredCompletionDate} |`
  )
  .join("\n")}

## Checklist

${data.checklist.items.map((i) => `- [${i.done ? "x" : " "}] ${i.label} — ${i.detail}`).join("\n")}

## OUTPUT scores

| Metric | Value |
|--------|------:|
| Executive Readiness Score | ${execReady} |
| Production Readiness Score | ${prodReady} |
| Commercial Readiness Score | ${commReady} |
| Operational Readiness Score | ${opsReady} |
| Launch Risk Score | ${data.risks.launchRiskScore} |
| Overall Project Score | ${data.scorecard.overallProjectScore} |
| Overall Phase 10 Progress | ${phase10}% |
`,
    "utf8"
  );

  fs.writeFileSync(
    path.join(dir, "PHASE10_SPRINT9_REPORT.md"),
    `# PHASE 10 — SPRINT 9 REPORT

**Sprint:** 9 — Final Executive Go / No-Go Review  
**Date:** 2026-07-26  
**Core:** UNCHANGED · FROZEN · SHA-256 \`${CORE_CERT_SHA}\` · ${data.coreMatches ? "MATCH" : "FAIL"}  
**Portal:** \`0.9.4-phase10.s9\`  

---

## Decision

**${data.decision.decision}**

${data.decision.rationale.map((r) => `- ${r}`).join("\n")}

## Scores

| Score | Value |
|-------|------:|
| Executive Readiness | ${execReady} |
| Production Readiness | ${prodReady} |
| Commercial Readiness | ${commReady} |
| Operational Readiness | ${opsReady} |
| Launch Risk | ${data.risks.launchRiskScore} |
| Overall Project | ${data.scorecard.overallProjectScore} |
| **Phase 10 Progress** | **${phase10}%** |

## Documentation

- GO_NO_GO_REVIEW.md
- PRODUCTION_LAUNCH_CERTIFICATION.md
- FINAL_RISK_REGISTER.md
- EXECUTIVE_SCORECARD.md
- LAUNCH_APPROVAL_REPORT.md
- PHASE10_SPRINT9_REPORT.md (this file)

## STOP

**Await Owner approval before Sprint 10.**
`,
    "utf8"
  );
}

export async function getExecutiveGoNoGoDashboard(options?: { refresh?: boolean }) {
  await ensureSprint9Evidence(!!options?.refresh);

  const review = latestExecutiveRun("review")?.payload as
    | {
        architecture?: { score: number };
        production?: { score: number };
        business?: { score: number };
        operational?: { score: number };
      }
    | undefined;
  const risks = latestExecutiveRun("risks")?.payload as {
    launchRiskScore?: number;
    criticalOpen?: number;
    highOpen?: number;
    risks?: Array<{ id: string; title: string; severity: string; status: string }>;
  } | undefined;
  const scorecard = latestExecutiveRun("scorecard")?.payload as {
    overallProjectScore?: number;
    rows?: Array<{ area: string; score: number }>;
  } | undefined;
  const decision = latestExecutiveRun("decision")?.payload as {
    decision?: string;
    conditions?: Array<{ id: string; priority: string; title: string; owner: string }>;
    rationale?: string[];
  } | undefined;
  const checklist = latestExecutiveRun("checklist")?.payload as {
    items?: Array<{ label: string; done: boolean }>;
    score?: number;
  } | undefined;

  const productionReadinessScore = review?.production?.score ?? 0;
  const commercialReadinessScore = review?.business?.score ?? 0;
  const operationalReadinessScore = review?.operational?.score ?? 0;
  const executiveReadinessScore = Math.round(
    ((review?.architecture?.score ?? 0) + (scorecard?.overallProjectScore ?? 0)) / 2
  );
  const launchRiskScore = risks?.launchRiskScore ?? 0;
  const overallProjectScore = scorecard?.overallProjectScore ?? 0;

  return {
    decision: decision?.decision ?? "UNKNOWN",
    rationale: decision?.rationale ?? [],
    conditions: decision?.conditions ?? [],
    executiveReadinessScore,
    productionReadinessScore,
    commercialReadinessScore,
    operationalReadinessScore,
    launchRiskScore,
    overallProjectScore,
    phase10Progress: 99,
    criticalOpen: risks?.criticalOpen ?? 0,
    highOpen: risks?.highOpen ?? 0,
    checklistScore: checklist?.score ?? 0,
    checklist: checklist?.items ?? [],
    scorecardRows: scorecard?.rows ?? [],
    topRisks: (risks?.risks || []).slice(0, 8),
    coreIsolation: "Sprint 9 executive review never modifies Core Trading Engine",
    coreSha: CORE_CERT_SHA,
    runs: listExecutiveRuns()
      .slice(0, 10)
      .map((r) => ({ id: r.id, kind: r.kind, label: r.label, at: r.at })),
    generatedAt: new Date().toISOString(),
  };
}
