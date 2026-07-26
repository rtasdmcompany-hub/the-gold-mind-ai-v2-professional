/**
 * Phase 11 Sprint 10 — Global enterprise certification suite + executive docs.
 */
import fs from "fs";
import path from "path";
import {
  CORE_CERT_SHA,
  commercialRoot,
  docsRoot,
  latestPhase11Run,
  savePhase11Run,
} from "@/server/phase11/store";
import {
  buildProjectStatistics,
  runCommercialCertification,
  runEnterpriseCertification,
  runGateChecks,
  runLtsCertification,
  runTechnicalCertification,
  verifyCoreSha,
} from "./evidence";
import { buildExecutiveScores, decidePhase11Certification } from "./decision";
import { getBusinessGrowthRoadmap, getLtsPolicy } from "./policies";
import { PHASE11_CORE_ISOLATION } from "./types";
import type { OutputScores } from "./types";

export async function runFullPhase11Sprint10Suite() {
  const core = verifyCoreSha();
  const enterprise = runEnterpriseCertification(core.matches);
  const commercial = runCommercialCertification();
  const technical = runTechnicalCertification(core.matches);
  const ltsItems = runLtsCertification();
  const gates = runGateChecks(core.matches);
  const { executive, output } = buildExecutiveScores({
    enterprise,
    commercial,
    technical,
    lts: ltsItems,
    gates,
    coreMatches: core.matches,
  });
  const criticalOpen = !core.matches ? 1 : 0;
  const decisionFinal = decidePhase11Certification({
    coreMatches: core.matches,
    criticalOpen,
    securityPass: gates.find((g) => g.id === "gate_security")?.status === "pass",
    drComplete: gates.find((g) => g.id === "gate_dr")?.status === "pass",
    ltsComplete: gates.find((g) => g.id === "gate_lts")?.status === "pass",
  });

  const stats = buildProjectStatistics();
  const lts = getLtsPolicy();
  const roadmap = getBusinessGrowthRoadmap();

  const scorecard = {
    rows: [
      { area: "Engineering", score: output.engineeringScore },
      { area: "Commercial", score: output.commercialScore },
      { area: "Operations", score: output.operationsScore },
      { area: "Security", score: output.securityScore },
      { area: "Infrastructure", score: output.infrastructureScore },
      { area: "Enterprise", score: output.enterpriseScore },
      { area: "Customer Success", score: output.customerSuccessScore },
      { area: "Global Readiness", score: output.globalReadinessScore },
      { area: "Overall Product", score: output.overallProductScore },
    ],
    output,
    executive,
    at: new Date().toISOString(),
  };

  savePhase11Run("p11_closure_scorecard", "Phase 11 Sprint 10 scorecard", scorecard);
  savePhase11Run("p11_closure_decision", "Phase 11 Sprint 10 executive decision", decisionFinal);
  savePhase11Run("p11_closure_suite", "Phase 11 Sprint 10 closure suite", {
    core,
    enterpriseCount: enterprise.length,
    commercialCount: commercial.length,
    technicalCount: technical.length,
    ltsCount: ltsItems.length,
    decision: decisionFinal.decision,
    phase12Authorized: decisionFinal.phase12Authorized,
    stats,
    scores: output,
    at: new Date().toISOString(),
  });

  writeClosureDocs({
    scorecard,
    decision: decisionFinal,
    enterprise,
    commercial,
    technical,
    ltsItems,
    gates,
    stats,
    lts,
    roadmap,
    core,
    executive,
    output,
  });

  return {
    scorecard,
    decision: decisionFinal,
    enterprise,
    commercial,
    technical,
    ltsItems,
    gates,
    stats,
    lts,
    roadmap,
    core,
    dashboard: await getPhase11Sprint10Dashboard(),
  };
}

function writeClosureDocs(data: {
  scorecard: { output: OutputScores; rows: { area: string; score: number }[]; executive: ReturnType<typeof buildExecutiveScores>["executive"] };
  decision: ReturnType<typeof decidePhase11Certification>;
  enterprise: ReturnType<typeof runEnterpriseCertification>;
  commercial: ReturnType<typeof runCommercialCertification>;
  technical: ReturnType<typeof runTechnicalCertification>;
  ltsItems: ReturnType<typeof runLtsCertification>;
  gates: ReturnType<typeof runGateChecks>;
  stats: ReturnType<typeof buildProjectStatistics>;
  lts: ReturnType<typeof getLtsPolicy>;
  roadmap: ReturnType<typeof getBusinessGrowthRoadmap>;
  core: ReturnType<typeof verifyCoreSha>;
  executive: ReturnType<typeof buildExecutiveScores>["executive"];
  output: OutputScores;
}) {
  const dir = docsRoot();
  if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
  const date = new Date().toISOString().slice(0, 10);
  const o = data.output;
  const d = data.decision;

  const certTable = (items: { label: string; status: string; detail: string }[]) =>
    `| Item | Status | Detail |\n|------|--------|--------|\n${items.map((i) => `| ${i.label} | ${i.status} | ${i.detail} |`).join("\n")}`;

  fs.writeFileSync(
    path.join(dir, "PHASE11_COMPLETION_REPORT.md"),
    `# PHASE11_COMPLETION_REPORT.md

**Date:** ${date}  
**Phase 11 Progress:** **${o.phase11Progress}%** COMPLETE  
**Core:** ${data.core.matches ? "MATCH" : "FAIL"} · \`${CORE_CERT_SHA}\`

## Sprints 1–10

Global Ops · BI · Partners · Enterprise CRM · Localization · Mobile · AI Assistant · API Platform · Infrastructure · **Closure**

## Decision

**${d.decision}**

${d.rationale.map((r) => `- ${r}`).join("\n")}

${PHASE11_CORE_ISOLATION}
`,
    "utf8"
  );

  fs.writeFileSync(
    path.join(dir, "GLOBAL_ENTERPRISE_CERTIFICATION.md"),
    `# GLOBAL_ENTERPRISE_CERTIFICATION.md

## Enterprise surfaces

${certTable(data.enterprise)}

## Commercial

${certTable(data.commercial)}

## Technical

${certTable(data.technical)}
`,
    "utf8"
  );

  fs.writeFileSync(
    path.join(dir, "LTS_FINAL_POLICY.md"),
    `# LTS_FINAL_POLICY.md

## Versioning

- Commercial: ${data.lts.versioning.commercial}
- Core: ${data.lts.versioning.core}

## Security patches

- Critical: ${data.lts.securityPatch.critical}
- High: ${data.lts.securityPatch.high}
- Medium: ${data.lts.securityPatch.medium}
- Low: ${data.lts.securityPatch.low}

## Release cadence

- ${data.lts.releaseCadence.commercialMonthly}
- ${data.lts.releaseCadence.ltsQuarterly}
- Hotfixes: ${data.lts.releaseCadence.hotfixes}

## Maintenance

${data.lts.maintenanceWindows.primary} · notice ${data.lts.maintenanceWindows.notice}

## End-of-Life

Support ${data.lts.endOfLife.supportWindow} · notice ${data.lts.endOfLife.noticePeriodMonths} months

## Support matrix

${data.lts.supportMatrix.map((s) => `- ${s}`).join("\n")}

## Compatibility

- API: ${data.lts.compatibility.api}
- MT5: ${data.lts.compatibility.mt5}
- Browsers: ${data.lts.compatibility.browsers}
`,
    "utf8"
  );

  fs.writeFileSync(
    path.join(dir, "GLOBAL_OPERATIONS_CERTIFICATION.md"),
    `# GLOBAL_OPERATIONS_CERTIFICATION.md

## Gate checks

${certTable(data.gates)}

## LTS checklist

${certTable(data.ltsItems)}

Operations Center, observability, HA, DR, and cost controls certified under Phase 11 Sprint 9 evidence.
`,
    "utf8"
  );

  fs.writeFileSync(
    path.join(dir, "BUSINESS_GROWTH_ROADMAP.md"),
    `# BUSINESS_GROWTH_ROADMAP.md

## 12 Months

${Object.entries(data.roadmap.months12)
  .map(([k, v]) => `- **${k}:** ${v}`)
  .join("\n")}

## 24 Months

${Object.entries(data.roadmap.months24)
  .map(([k, v]) => `- **${k}:** ${v}`)
  .join("\n")}

## 36 Months

${Object.entries(data.roadmap.months36)
  .map(([k, v]) => `- **${k}:** ${v}`)
  .join("\n")}
`,
    "utf8"
  );

  fs.writeFileSync(
    path.join(dir, "PHASE12_AUTHORIZATION.md"),
    `# PHASE12_AUTHORIZATION.md

**Authorized:** ${d.phase12Authorized ? "YES" : "NO"}  
**Decision:** ${d.decision}

## Phase 12 scope

Continuous Innovation & Product Evolution — commercial surfaces only.

## Hard constraints

- Core Trading Engine remains frozen; SHA must continue to match certified value on every release train.
- No trading logic in portal, mobile, AI, or Public API.
- LTS policies remain in force.

## Conditions carried forward

${d.conditions.map((c) => `- **${c.id}** (${c.severity}): ${c.title} — Owner: ${c.owner}`).join("\n")}
`,
    "utf8"
  );

  fs.writeFileSync(
    path.join(dir, "EXECUTIVE_BOARD_DECISION.md"),
    `# EXECUTIVE_BOARD_DECISION.md

## FINAL DECISION

# ${d.decision}

## Rationale

${d.rationale.map((r) => `1. ${r}`).join("\n")}

## Residual conditions

| ID | Severity | Title | Owner | Target |
|----|----------|-------|-------|--------|
${d.conditions
  .map((c) => `| ${c.id} | ${c.severity} | ${c.title} | ${c.owner} | ${c.targetCompletion} |`)
  .join("\n")}

## Mitigation

${d.conditions.map((c) => `- **${c.id}:** ${c.mitigation}`).join("\n")}

## Precedence

Customer trust, platform stability, and long-term maintainability take precedence over feature velocity.
`,
    "utf8"
  );

  fs.writeFileSync(
    path.join(dir, "PROJECT_MASTER_CERTIFICATION.md"),
    `# PROJECT_MASTER_CERTIFICATION.md

**Product:** THE GOLD MIND AI v2.0 Professional  
**Certification:** Phase 11 Global Commercial FinTech Platform  
**Decision:** ${d.decision}  
**Core SHA-256:** \`${CORE_CERT_SHA}\` · ${data.core.matches ? "VERIFIED MATCH" : "FAIL"}

## Project statistics

| Metric | Value |
|--------|------:|
| Architecture modules | ${data.stats.architectureModules} |
| Documentation files | ${data.stats.documentationFiles} |
| APIs | ${data.stats.apis} |
| Dashboards | ${data.stats.dashboards} |
| Customer services | ${data.stats.customerServices} |
| Integrations | ${data.stats.integrations} |
| Quality gates passed | ${data.stats.qualityGatesPassed} |
| Security reviews | ${data.stats.securityReviews} |
| Commercial reviews | ${data.stats.commercialReviews} |
| Executive reviews | ${data.stats.executiveReviews} |
| Overall project completion | ${data.stats.overallProjectCompletionPct}% |

${PHASE11_CORE_ISOLATION}
`,
    "utf8"
  );

  fs.writeFileSync(
    path.join(dir, "PHASE11_SPRINT10_REPORT.md"),
    `# PHASE 11 — SPRINT 10 REPORT

**Sprint:** 10 — Global Enterprise Certification & Phase 12 Authorization  
**Date:** ${date}  
**Portal:** \`1.0.9-phase11.s10\`  
**Core:** ${data.core.matches ? "MATCH" : "FAIL"} · \`${CORE_CERT_SHA}\`

## OUTPUT

| Score | Value |
|-------|------:|
| Engineering | ${o.engineeringScore} |
| Commercial | ${o.commercialScore} |
| Operations | ${o.operationsScore} |
| Security | ${o.securityScore} |
| Infrastructure | ${o.infrastructureScore} |
| Enterprise | ${o.enterpriseScore} |
| Customer Success | ${o.customerSuccessScore} |
| Global Readiness | ${o.globalReadinessScore} |
| Overall Product | ${o.overallProductScore} |
| **Phase 11 Progress** | **${o.phase11Progress}%** |

## FINAL DECISION

**${d.decision}**

Phase 12 authorized: **${d.phase12Authorized ? "YES" : "NO"}**

## STOP

**Await Owner approval before beginning Phase 12.**
`,
    "utf8"
  );

  const phase11Dir = path.join(commercialRoot(), "Phase11");
  if (!fs.existsSync(phase11Dir)) fs.mkdirSync(phase11Dir, { recursive: true });
  fs.writeFileSync(
    path.join(phase11Dir, "README.md"),
    `# Phase 11 — Global Commercial Release

**Status:** Sprint 10 COMPLETE — ${d.decision}  
**Core:** Permanently frozen · SHA ${data.core.matches ? "MATCH" : "FAIL"}  
**Phase 11 Progress:** **${o.phase11Progress}%**  
**Phase 12:** ${d.phase12Authorized ? "AUTHORIZED (await Owner start)" : "NOT AUTHORIZED"}  

## Sprint 10 surfaces

| Surface | Path |
|---------|------|
| Phase 11 Certification | \`/portal/admin/phase11-certification\` |
| Executive Decision | \`/portal/admin/phase11-decision\` |
| Admin API | \`/api/admin/phase11-closure\` |
| CLI | \`npm run phase11:sprint10\` |

## Residual conditions

${d.conditions.map((c) => `- ${c.id} (${c.severity}): ${c.title}`).join("\n")}
`,
    "utf8"
  );
}

export async function ensureSprint10Evidence(force = false) {
  if (
    !force &&
    latestPhase11Run("p11_closure_suite") &&
    latestPhase11Run("p11_closure_scorecard") &&
    latestPhase11Run("p11_closure_decision")
  ) {
    return;
  }
  await runFullPhase11Sprint10Suite();
}

export async function getPhase11Sprint10Dashboard(options?: { refresh?: boolean }) {
  await ensureSprint10Evidence(!!options?.refresh);
  const scorecard = latestPhase11Run("p11_closure_scorecard")?.payload as
    | {
        output?: OutputScores;
        rows?: { area: string; score: number }[];
        executive?: ReturnType<typeof buildExecutiveScores>["executive"];
      }
    | undefined;
  const decision = latestPhase11Run("p11_closure_decision")?.payload as
    | ReturnType<typeof decidePhase11Certification>
    | undefined;
  const suite = latestPhase11Run("p11_closure_suite")?.payload as
    | { stats?: ReturnType<typeof buildProjectStatistics>; core?: ReturnType<typeof verifyCoreSha> }
    | undefined;

  const core = suite?.core || verifyCoreSha();
  const o = scorecard?.output;

  return {
    engineeringScore: o?.engineeringScore ?? 0,
    commercialScore: o?.commercialScore ?? 0,
    operationsScore: o?.operationsScore ?? 0,
    securityScore: o?.securityScore ?? 0,
    infrastructureScore: o?.infrastructureScore ?? 0,
    enterpriseScore: o?.enterpriseScore ?? 0,
    customerSuccessScore: o?.customerSuccessScore ?? 0,
    globalReadinessScore: o?.globalReadinessScore ?? 0,
    overallProductScore: o?.overallProductScore ?? 0,
    phase11Progress: o?.phase11Progress ?? 0,
    decision: decision?.decision || "NOT CERTIFIED",
    rationale: decision?.rationale || [],
    conditions: decision?.conditions || [],
    phase12Authorized: !!decision?.phase12Authorized,
    executive: scorecard?.executive,
    scorecardRows: scorecard?.rows ?? [],
    stats: suite?.stats || buildProjectStatistics(),
    enterprise: runEnterpriseCertification(core.matches),
    commercial: runCommercialCertification(),
    technical: runTechnicalCertification(core.matches),
    ltsItems: runLtsCertification(),
    gates: runGateChecks(core.matches),
    lts: getLtsPolicy(),
    roadmap: getBusinessGrowthRoadmap(),
    coreMatches: core.matches,
    coreSha: CORE_CERT_SHA,
    coreActual: core.actual,
    coreIsolation: PHASE11_CORE_ISOLATION,
    generatedAt: new Date().toISOString(),
  };
}
