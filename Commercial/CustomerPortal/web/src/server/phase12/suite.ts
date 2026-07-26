/**
 * Phase 12 LTS activation suite — all workstreams + docs + scorecard.
 */
import fs from "fs";
import path from "path";
import { verifyCoreSha } from "./core";
import { buildCustomerSuccessOps } from "./customer-success";
import { buildSupportExcellence } from "./support";
import { buildBusinessIntelligence } from "./bi";
import { buildOperationalExcellence } from "./operations";
import { buildReleaseManagement } from "./release";
import { buildV2Planning } from "./v2-planning";
import { computePhase12Scores, writeMonthlyExecutiveReports } from "./reports";
import {
  CORE_CERT_SHA,
  commercialRoot,
  docsRoot,
  latestPhase12Run,
  savePhase12Run,
} from "./store";
import { PHASE12_CORE_ISOLATION, PHASE12_SCOPE } from "./types";
import type { Phase12Condition, Phase12Scores } from "./types";

const PORTAL_VERSION = "1.0.10-phase12.s1";

export type Phase12Dashboard = {
  portalVersion: string;
  coreMatches: boolean;
  coreSha: string;
  isolation: string;
  scope: string;
  scores: Phase12Scores;
  conditions: Phase12Condition[];
  customerSuccess: unknown;
  support: unknown;
  bi: unknown;
  ops: unknown;
  release: unknown;
  v2Planning: unknown;
  monthly: unknown;
  v2EngineeringAuthorized: boolean;
  stopMessage: string;
  at: string;
};

export async function runFullPhase12LtsSuite(): Promise<{
  scores: Phase12Scores;
  core: ReturnType<typeof verifyCoreSha>;
  cs: Awaited<ReturnType<typeof buildCustomerSuccessOps>>;
  support: Awaited<ReturnType<typeof buildSupportExcellence>>;
  bi: Awaited<ReturnType<typeof buildBusinessIntelligence>>;
  ops: Awaited<ReturnType<typeof buildOperationalExcellence>>;
  release: Awaited<ReturnType<typeof buildReleaseManagement>>;
  v2: Awaited<ReturnType<typeof buildV2Planning>>;
  conditions: Phase12Condition[];
  reportFiles: string[];
  portalVersion: string;
  dashboard: Phase12Dashboard;
}> {
  const core = verifyCoreSha();
  if (!core.matches) {
    throw new Error(
      `Phase 12 blocked: Core SHA mismatch. expected=${core.expected} actual=${core.actual}`
    );
  }

  const cs = await buildCustomerSuccessOps();
  const support = await buildSupportExcellence();
  const bi = await buildBusinessIntelligence();
  const ops = await buildOperationalExcellence();
  const release = await buildReleaseManagement(PORTAL_VERSION);
  const v2 = await buildV2Planning();

  const scores = computePhase12Scores({
    coreMatches: core.matches,
    csRetentionPct: cs.retention.retentionPct,
    npsScore: cs.npsSample.score,
    supportWithinSlaPct: support.resolution.withinSlaPct,
    kbArticles: support.knowledgeBase.articles,
    mrr: bi.revenue.mrr,
    opsUptimePct: ops.monitoring.uptimePct,
    backupVerified: ops.backupVerification.status === "verified",
    openCriticalIncidents: ops.alerting.critical,
  });

  const conditions: Phase12Condition[] = [
    {
      id: "P11-C1",
      severity: "Medium",
      title: "MQL5 Market live screenshots (carried from Phase 11)",
      owner: "Commercial + Compliance",
      mitigation: "Complete CAPTURE_PLAN · set BC-MQL5 = VERIFIED before Market Stable upload",
      targetCompletion: "Before MQL5 Market Stable upload (does not block LTS SaaS ops)",
    },
  ];

  const reportFiles = writeMonthlyExecutiveReports({
    scores,
    core,
    cs,
    support,
    bi,
    ops,
    release,
    v2,
    portalVersion: PORTAL_VERSION,
  });

  writePhase12ActivationDocs({
    scores,
    core,
    cs,
    support,
    bi,
    ops,
    release,
    v2,
    conditions,
    reportFiles,
  });

  const scorecard = {
    scores,
    conditions,
    core,
    portalVersion: PORTAL_VERSION,
    at: new Date().toISOString(),
  };
  savePhase12Run("scorecard", "Phase 12 LTS scorecard", scorecard);
  savePhase12Run("lts_suite", "Phase 12 LTS activation suite", {
    workstreams: 7,
    coreMatches: true,
    scores,
    v2Backlog: v2.backlogCount,
    implementationBlocked: true,
    reportFiles,
    at: new Date().toISOString(),
  });

  return {
    scores,
    core,
    cs,
    support,
    bi,
    ops,
    release,
    v2,
    conditions,
    reportFiles,
    portalVersion: PORTAL_VERSION,
    dashboard: await getPhase12Dashboard(),
  };
}

export async function getPhase12Dashboard(opts?: { refresh?: boolean }): Promise<Phase12Dashboard> {
  if (opts?.refresh) await runFullPhase12LtsSuite();
  const suite = latestPhase12Run("lts_suite");
  const scorecard = latestPhase12Run("scorecard");
  const cs = latestPhase12Run("cs_suite");
  const support = latestPhase12Run("support_suite");
  const bi = latestPhase12Run("bi_suite");
  const ops = latestPhase12Run("ops_suite");
  const release = latestPhase12Run("release_suite");
  const v2 = latestPhase12Run("v2_planning");
  const monthly = latestPhase12Run("monthly_reports");

  if (!suite || !scorecard) {
    return (await runFullPhase12LtsSuite()).dashboard;
  }

  const sc = scorecard.payload as {
    scores: Phase12Scores;
    conditions: Phase12Condition[];
    core: ReturnType<typeof verifyCoreSha>;
    portalVersion: string;
  };

  return {
    portalVersion: sc.portalVersion || PORTAL_VERSION,
    coreMatches: sc.core?.matches ?? true,
    coreSha: CORE_CERT_SHA,
    isolation: PHASE12_CORE_ISOLATION,
    scope: PHASE12_SCOPE,
    scores: sc.scores,
    conditions: sc.conditions || [],
    customerSuccess: cs?.payload || null,
    support: support?.payload || null,
    bi: bi?.payload || null,
    ops: ops?.payload || null,
    release: release?.payload || null,
    v2Planning: v2?.payload || null,
    monthly: monthly?.payload || null,
    v2EngineeringAuthorized: false,
    stopMessage: "Await Owner approval before Version 2.x Engineering Program.",
    at: scorecard.at,
  };
}

export async function ensurePhase12Evidence() {
  if (!latestPhase12Run("lts_suite")) await runFullPhase12LtsSuite();
}

function writePhase12ActivationDocs(data: {
  scores: Phase12Scores;
  core: ReturnType<typeof verifyCoreSha>;
  cs: Awaited<ReturnType<typeof buildCustomerSuccessOps>>;
  support: Awaited<ReturnType<typeof buildSupportExcellence>>;
  bi: Awaited<ReturnType<typeof buildBusinessIntelligence>>;
  ops: Awaited<ReturnType<typeof buildOperationalExcellence>>;
  release: Awaited<ReturnType<typeof buildReleaseManagement>>;
  v2: Awaited<ReturnType<typeof buildV2Planning>>;
  conditions: Phase12Condition[];
  reportFiles: string[];
}) {
  const dir = docsRoot();
  if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
  const date = new Date().toISOString().slice(0, 10);
  const s = data.scores;

  fs.writeFileSync(
    path.join(dir, "PHASE12_LTS_ACTIVATION.md"),
    `# PHASE12_LTS_ACTIVATION.md

**Date:** ${date}  
**Portal:** \`${PORTAL_VERSION}\`  
**Status:** Version 1.0 entered Long-Term Support  
**Core:** MATCH · \`${CORE_CERT_SHA}\`

## Absolute rule

${PHASE12_CORE_ISOLATION}

## Scope

${PHASE12_SCOPE}

## Workstreams activated

1. Customer Success  
2. Support Excellence  
3. Business Intelligence  
4. Operational Excellence  
5. Release Management (1.0.x only)  
6. Version 2.0 Planning (collect only — DO NOT IMPLEMENT)  
7. Monthly Executive Reports  

## OUTPUT scores

| Score | Value |
|-------|------:|
| Customer Success | ${s.customerSuccessScore} |
| Support | ${s.supportScore} |
| Business Growth | ${s.businessGrowthScore} |
| Operational Excellence | ${s.operationalExcellenceScore} |
| Infrastructure Health | ${s.infrastructureHealth} |
| Overall Platform Health | ${s.overallPlatformHealth} |

## STOP

Await Owner approval before Version 2.x Engineering Program.
`,
    "utf8"
  );

  fs.writeFileSync(
    path.join(dir, "PHASE12_RELEASE_POLICY_1.0.md"),
    `# PHASE12_RELEASE_POLICY_1.0.md

**Line:** 1.0.x LTS  
**Current portal:** \`${PORTAL_VERSION}\`

## Allowed

${data.release.allowed.map((a) => `- ${a}`).join("\n")}

## Forbidden

${data.release.forbidden.map((a) => `- ${a}`).join("\n")}

## Cadence

- Security patches: ${data.release.cadence.securityPatches}
- Maintenance windows: ${data.release.cadence.maintenanceWindows}
- Documentation: ${data.release.cadence.minorDocs}

## Core rule

${data.release.coreRule}
`,
    "utf8"
  );

  fs.writeFileSync(
    path.join(dir, "PHASE12_V2_PLANNING_BACKLOG.md"),
    `# PHASE12_V2_PLANNING_BACKLOG.md

**Rule:** ${data.v2.rule}

## Backlog (${data.v2.backlogCount})

| ID | Category | Title | Implement in Phase 12 |
|----|----------|-------|----------------------|
${data.v2.backlog
  .map((b) => `| ${b.id} | ${b.category} | ${b.title} | NO |`)
  .join("\n")}

## Details

${data.v2.backlog.map((b) => `### ${b.id} — ${b.title}\n${b.detail}\n`).join("\n")}
`,
    "utf8"
  );

  fs.writeFileSync(
    path.join(dir, "PHASE12_SPRINT1_REPORT.md"),
    `# PHASE 12 — SPRINT 1 REPORT

**Sprint:** 1 — LTS Activation & Operational Excellence  
**Date:** ${date}  
**Portal:** \`${PORTAL_VERSION}\`  
**Core:** MATCH · \`${CORE_CERT_SHA}\`

## OUTPUT

| Score | Value |
|-------|------:|
| Customer Success Score | ${s.customerSuccessScore} |
| Support Score | ${s.supportScore} |
| Business Growth Score | ${s.businessGrowthScore} |
| Operational Excellence Score | ${s.operationalExcellenceScore} |
| Infrastructure Health | ${s.infrastructureHealth} |
| Overall Platform Health | ${s.overallPlatformHealth} |
| Phase 12 Progress | ${s.phase12Progress}% |

## Residual conditions

| ID | Severity | Title | Owner |
|----|----------|-------|-------|
${data.conditions.map((c) => `| ${c.id} | ${c.severity} | ${c.title} | ${c.owner} |`).join("\n")}

## Monthly pack

${data.reportFiles.map((f) => `- ${f}`).join("\n")}

## STOP

**Await Owner approval before Version 2.x Engineering Program.**
`,
    "utf8"
  );

  const phase12Dir = path.join(commercialRoot(), "Phase12");
  if (!fs.existsSync(phase12Dir)) fs.mkdirSync(phase12Dir, { recursive: true });
  fs.writeFileSync(
    path.join(phase12Dir, "README.md"),
    `# Phase 12 — Continuous Innovation & LTS Operations

**Status:** Sprint 1 ACTIVE — Version 1.0 Long-Term Support  
**Core:** Permanently frozen · SHA MATCH  
**V2.x Engineering:** NOT AUTHORIZED (planning only)

## Surfaces

| Surface | Path |
|---------|------|
| LTS Ops Hub | \`/portal/admin/phase12-lts\` |
| Customer Success | \`/portal/admin/phase12-customer-success\` |
| Monthly Reports | \`/portal/admin/phase12-monthly\` |
| V2 Planning | \`/portal/admin/phase12-v2-planning\` |
| Admin API | \`/api/admin/phase12\` |
| CLI | \`npm run phase12:sprint1\` |

## Hard rules

- No Core Trading Engine modifications
- 1.0.x = bugfix / security / performance / compatibility / docs only
- V2 backlog = collect only

## Residual

- P11-C1 (Medium): MQL5 Market live screenshots
`,
    "utf8"
  );
}
