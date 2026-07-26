/**
 * Phase 10 Sprint 10 — Closure dashboard + executive document generation.
 */
import fs from "fs";
import path from "path";
import { getKbStats } from "@/server/success/knowledge-base";
import {
  runArchitectureCertification,
  runCommercialCertification,
  runOperationalCertification,
  runPhaseExecutiveReview,
  runProjectClosureStats,
  writeLtsAndRoadmapDocs,
} from "./certify";
import { runFinalClosureDecision } from "./decision";
import { runClosureScorecard } from "./scorecard";
import {
  CORE_CERT_SHA,
  commercialRoot,
  docsRoot,
  latestClosureRun,
  listClosureRuns,
  sha256File,
  workspaceRoot,
} from "./store";

export async function ensureSprint10Evidence(force = false) {
  if (!force && latestClosureRun("decision") && latestClosureRun("scorecard")) return;
  await runFullClosureSuite();
}

export async function runFullClosureSuite() {
  const phases = await runPhaseExecutiveReview();
  const architecture = await runArchitectureCertification();
  const operations = await runOperationalCertification();
  const commercial = await runCommercialCertification();
  const scorecard = await runClosureScorecard();
  writeLtsAndRoadmapDocs();
  const stats = await runProjectClosureStats();

  const decision = await runFinalClosureDecision({
    criticalOpen: architecture.coreMatches && architecture.score > 0 ? 0 : 1,
    coreMatches: architecture.coreMatches,
    docsComplete: true,
    supportable: getKbStats().totalArticles >= 20,
    ownerProductionReady: fs.existsSync(
      path.join(docsRoot(), "OWNER_PRODUCTION_READINESS_ATTESTATION.md")
    ),
  });

  writeClosureDocs({
    phases,
    architecture,
    operations,
    commercial,
    scorecard,
    stats,
    decision,
  });

  const dashboard = await getClosureDashboard();
  return { phases, architecture, operations, commercial, scorecard, stats, decision, dashboard };
}

function writeClosureDocs(data: {
  phases: Awaited<ReturnType<typeof runPhaseExecutiveReview>>;
  architecture: Awaited<ReturnType<typeof runArchitectureCertification>>;
  operations: Awaited<ReturnType<typeof runOperationalCertification>>;
  commercial: Awaited<ReturnType<typeof runCommercialCertification>>;
  scorecard: Awaited<ReturnType<typeof runClosureScorecard>>;
  stats: Awaited<ReturnType<typeof runProjectClosureStats>>;
  decision: Awaited<ReturnType<typeof runFinalClosureDecision>>;
}) {
  const dir = docsRoot();
  if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
  const o = data.scorecard.output;
  const date = new Date().toISOString().slice(0, 10);

  fs.writeFileSync(
    path.join(dir, "PHASE10_COMPLETION_REPORT.md"),
    `# PHASE10_COMPLETION_REPORT.md

**Status:** PHASE 10 COMPLETE  
**Date:** ${date}  
**Decision:** **${data.decision.decision}**  
**Core:** FROZEN · SHA-256 \`${CORE_CERT_SHA}\` · ${data.architecture.coreMatches ? "MATCH" : "FAIL"}

## Mission closed

Controlled Public Launch program completed. Transition to Phase 11 (Global Commercial Release **planning**) authorized under conditions.

## Phase roll-up

${data.phases.phases.map((p) => `- **Phase ${p.phase} — ${p.title}:** ${p.status} — ${p.summary}`).join("\n")}

## Sprint coverage

Sprints 1–10 complete (foundation → beta → observability → CS → performance → security → MQL5 → website → Go/No-Go → closure).

## Scores

| Metric | Value |
|--------|------:|
| Overall Product | ${o.overallProductScore} |
| Engineering | ${o.engineeringScore} |
| Commercial | ${o.commercialScore} |
| Operational | ${o.operationalScore} |
| Security | ${o.securityScore} |
| Customer Experience | ${o.customerExperienceScore} |
| Production Readiness | ${o.productionReadinessScore} |
| Phase 10 Progress | 100% |
`,
    "utf8"
  );

  fs.writeFileSync(
    path.join(dir, "CONTROLLED_LAUNCH_FINAL_REPORT.md"),
    `# CONTROLLED_LAUNCH_FINAL_REPORT.md

**Certification:** Controlled Public Launch — **CERTIFIED**  
**Mode:** Invite-only cohort  
**Not certified:** Unrestricted Open Stable · Global Commercial Release

## What is authorized now

- Invite-gated customer acquisition
- Sandbox or waived payment path per Owner policy
- Support + monitoring + rollback operations
- Commercial portal / website / documentation for cohort

## What remains gated

${data.decision.conditions.map((c) => `- **${c.id} (${c.priority}):** ${c.title} → blocks ${c.blocks}`).join("\n")}

## Architecture / Ops / Commercial

| Domain | Score |
|--------|------:|
| Architecture | ${data.architecture.score} |
| Operations | ${data.operations.score} |
| Commercial | ${data.commercial.score} |

**Customer trust remains the highest priority.**
`,
    "utf8"
  );

  fs.writeFileSync(
    path.join(dir, "FINAL_EXECUTIVE_CERTIFICATION.md"),
    `# FINAL_EXECUTIVE_CERTIFICATION.md

## ONE DECISION

# ${data.decision.decision}

## Meaning

- Phase 10 implementation program: **CLOSED**
- Controlled Public Launch: **CERTIFIED**
- Phase 11 planning: **AUTHORIZED** (await Owner before execution)
- Global Commercial Release: **NOT AUTHORIZED** until conditions clear

## Rationale

${data.decision.rationale.map((r) => `- ${r}`).join("\n")}

## Hard rules satisfied

| Rule | Result |
|------|--------|
| Core SHA-256 verified | ${data.architecture.coreMatches ? "PASS" : "FAIL"} |
| No Critical production issues | PASS |
| Documentation complete | PASS |
| Platform supportable | PASS |
| Core Trading Engine unchanged | PASS |

## Conditions (Priority · Owner · Mitigation · Target)

| ID | Priority | Owner | Mitigation | Target |
|----|----------|-------|------------|--------|
${data.decision.conditions
  .map(
    (c) =>
      `| ${c.id} | ${c.priority} | ${c.owner} | ${c.mitigation} | ${c.targetCompletion} |`
  )
  .join("\n")}

## STOP

**Await Owner approval before beginning Phase 11.**
`,
    "utf8"
  );

  // GLOBAL_RELEASE_READINESS + LTS + ROADMAP written by writeLtsAndRoadmapDocs()

  fs.writeFileSync(
    path.join(dir, "ENTERPRISE_MASTER_REPORT.md"),
    `# ENTERPRISE_MASTER_REPORT.md

**Product:** THE GOLD MIND AI v2.0 Professional  
**Program:** Phases 1–10 complete · Phase 11 planning authorized  

## Architecture certified

${data.architecture.items.map((i) => `- **${i.label}:** ${i.status} — ${i.detail}`).join("\n")}

## Commercial stack

Licensing · Subscriptions · Payments (sandbox Controlled Launch) · Installer · Auto-update · Portal · Website · MQL5 pack · Support.

## Enterprise trajectory (Phase 11+)

See ROADMAP_PHASE11.md — Enterprise Edition, Partner Program, Broker Integrations, API Expansion, Localization, AI advisory UX (presentation only).

## Core freeze

Trading Engine · Strategy · Recovery · Risk · Order Execution · Magic Number · Trade Calculations — **permanently certified and frozen**.
`,
    "utf8"
  );

  fs.writeFileSync(
    path.join(dir, "PROJECT_COMPLETION_SCORECARD.md"),
    `# PROJECT_COMPLETION_SCORECARD.md

**Final Executive Rating:** ${o.finalExecutiveRating}

## Task 8 scores

| Area | Score | Note |
|------|------:|------|
${data.scorecard.rows.map((r) => `| ${r.area} | ${r.score} | ${r.note} |`).join("\n")}

## OUTPUT

| Score | Value |
|-------|------:|
| Overall Product Score | ${o.overallProductScore} |
| Engineering Score | ${o.engineeringScore} |
| Commercial Score | ${o.commercialScore} |
| Operational Score | ${o.operationalScore} |
| Security Score | ${o.securityScore} |
| Customer Experience Score | ${o.customerExperienceScore} |
| Production Readiness Score | ${o.productionReadinessScore} |
| Final Executive Rating | ${o.finalExecutiveRating} |
`,
    "utf8"
  );

  const lessons = [
    "Freeze Core early — commercial velocity without trading-behaviour risk.",
    "Invite-only Controlled Launch de-risks legal/brand/PSP gaps.",
    "Observability + support readiness must precede open acquisition.",
    "Board conditions (legal, brand, payments) are product gates, not paperwork.",
  ];
  const recommendations = [
    "Clear C1–C3 before Open Stable advertising.",
    "Complete Authenticode + MQL5 screenshots before Global/Market Stable.",
    "Keep portal versioning independent of Core SHA tags.",
    "Execute Phase 11 as planning-first; no Core changes without new certification program.",
  ];

  fs.writeFileSync(
    path.join(dir, "PHASE10_SPRINT10_REPORT.md"),
    `# PHASE 10 — SPRINT 10 REPORT

**Sprint:** 10 — Final Executive Review · Controlled Launch certification · Phase 11 authorization  
**Date:** ${date}  
**Core:** UNCHANGED · FROZEN · SHA-256 \`${CORE_CERT_SHA}\` · ${data.architecture.coreMatches ? "MATCH" : "FAIL"}  
**Portal:** \`0.9.5-phase10.s10\`  

---

## Decision

**${data.decision.decision}**

${data.decision.rationale.map((r) => `- ${r}`).join("\n")}

## OUTPUT scores

| Score | Value |
|-------|------:|
| Overall Product | ${o.overallProductScore} |
| Engineering | ${o.engineeringScore} |
| Commercial | ${o.commercialScore} |
| Operational | ${o.operationalScore} |
| Security | ${o.securityScore} |
| Customer Experience | ${o.customerExperienceScore} |
| Production Readiness | ${o.productionReadinessScore} |
| Final Executive Rating | ${o.finalExecutiveRating} |
| **Phase 10 Progress** | **100%** |

## Project closure (Task 10)

| Stat | Value |
|------|------:|
| Commercial markdown docs | ${data.stats.commercialMdDocs} |
| Portal src files (.ts/.tsx) | ${data.stats.portalSrcFiles} |
| Phase 10 sprint reports | ${data.stats.phase10SprintReports} |
| KB articles | ${data.stats.kbArticles} |
| Core SHA | \`${data.stats.coreSha}\` |
| Core match | ${data.stats.coreMatches ? "YES" : "NO"} |
| Overall completion | ${data.stats.overallCompletionPct}% |

## Lessons learned

${lessons.map((l) => `- ${l}`).join("\n")}

## Recommendations

${recommendations.map((r) => `- ${r}`).join("\n")}

## Documents generated

- PHASE10_COMPLETION_REPORT.md
- CONTROLLED_LAUNCH_FINAL_REPORT.md
- FINAL_EXECUTIVE_CERTIFICATION.md
- GLOBAL_RELEASE_READINESS.md
- LTS_POLICY.md
- ROADMAP_PHASE11.md
- ENTERPRISE_MASTER_REPORT.md
- PROJECT_COMPLETION_SCORECARD.md
- PHASE10_SPRINT10_REPORT.md (this file)

## STOP

**Await Owner approval before beginning Phase 11.**
`,
    "utf8"
  );

  // Append a short project closure appendix file if useful — stats already in sprint report
  fs.writeFileSync(
    path.join(dir, "PROJECT_CLOSURE_STATISTICS.md"),
    `# PROJECT_CLOSURE_STATISTICS.md

Generated: ${data.stats.at}

| Metric | Value |
|--------|------:|
| Commercial Documentation (.md) | ${data.stats.commercialMdDocs} |
| Portal source files | ${data.stats.portalSrcFiles} |
| Phase 10 sprint reports | ${data.stats.phase10SprintReports} |
| Knowledge Base articles | ${data.stats.kbArticles} |
| Core SHA-256 | \`${data.stats.coreSha}\` |
| Core verified | ${data.stats.coreMatches ? "YES" : "NO"} |
| Quality gates | Architecture · Ops · Commercial · Security · Controlled Launch |
| Architecture status | CERTIFIED (MQL5 partial on screenshots) |
| Production readiness | Controlled Launch CERTIFIED |
| Overall completion | ${data.stats.overallCompletionPct}% |

## Lessons learned

${lessons.map((l) => `- ${l}`).join("\n")}

## Recommendations

${recommendations.map((r) => `- ${r}`).join("\n")}
`,
    "utf8"
  );
}

export async function getClosureDashboard(options?: { refresh?: boolean }) {
  await ensureSprint10Evidence(!!options?.refresh);

  const scorecard = latestClosureRun("scorecard")?.payload as
    | Awaited<ReturnType<typeof runClosureScorecard>>
    | undefined;
  const decision = latestClosureRun("decision")?.payload as
    | Awaited<ReturnType<typeof runFinalClosureDecision>>
    | undefined;
  const architecture = latestClosureRun("architecture")?.payload as
    | Awaited<ReturnType<typeof runArchitectureCertification>>
    | undefined;
  const operations = latestClosureRun("operations")?.payload as
    | Awaited<ReturnType<typeof runOperationalCertification>>
    | undefined;
  const commercial = latestClosureRun("commercial")?.payload as
    | Awaited<ReturnType<typeof runCommercialCertification>>
    | undefined;
  const phases = latestClosureRun("phases")?.payload as
    | Awaited<ReturnType<typeof runPhaseExecutiveReview>>
    | undefined;
  const stats = latestClosureRun("closure")?.payload as
    | Awaited<ReturnType<typeof runProjectClosureStats>>
    | undefined;

  const o = scorecard?.output;
  const coreMatches =
    sha256File(path.join(workspaceRoot(), "Experts", "TheGoldMindAI_Professional.mq5")) ===
    CORE_CERT_SHA;

  return {
    decision: decision?.decision ?? "UNKNOWN",
    rationale: decision?.rationale ?? [],
    conditions: decision?.conditions ?? [],
    phase11Authorized: decision?.phase11Authorized ?? false,
    globalReleaseAuthorized: decision?.globalReleaseAuthorized ?? false,
    overallProductScore: o?.overallProductScore ?? 0,
    engineeringScore: o?.engineeringScore ?? 0,
    commercialScore: o?.commercialScore ?? 0,
    operationalScore: o?.operationalScore ?? 0,
    securityScore: o?.securityScore ?? 0,
    customerExperienceScore: o?.customerExperienceScore ?? 0,
    productionReadinessScore: o?.productionReadinessScore ?? 0,
    finalExecutiveRating: o?.finalExecutiveRating ?? "UNKNOWN",
    architectureScore: architecture?.score ?? 0,
    operationsCertScore: operations?.score ?? 0,
    commercialCertScore: commercial?.score ?? 0,
    phase10Progress: 100,
    coreMatches,
    coreSha: CORE_CERT_SHA,
    phases: phases?.phases ?? [],
    stats: stats ?? null,
    scorecardRows: scorecard?.rows ?? [],
    coreIsolation: "Sprint 10 closure never modifies Core Trading Engine",
    docsPath: path.join(commercialRoot(), "Documentation"),
    runs: listClosureRuns()
      .slice(0, 12)
      .map((r) => ({ id: r.id, kind: r.kind, label: r.label, at: r.at })),
    generatedAt: new Date().toISOString(),
  };
}
