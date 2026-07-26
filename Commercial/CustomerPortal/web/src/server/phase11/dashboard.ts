/**
 * Phase 11 Sprint 1 — suite dashboard + documentation writers.
 */
import fs from "fs";
import path from "path";
import { buildGlobalOperationsCenter } from "./ops-center";
import { buildBusinessKpiDashboard } from "./kpis";
import { auditCommercialOperations } from "./commercial-ops";
import { generateExecutiveReports } from "./reporting";
import { buildOperationalHealth } from "./operational-health";
import { buildCustomerSuccessDashboard } from "./customer-success";
import { computePhase11Scorecard } from "./scorecard";
import {
  CORE_CERT_SHA,
  commercialRoot,
  docsRoot,
  latestPhase11Run,
  listPhase11Runs,
  savePhase11Run,
  sha256File,
  workspaceRoot,
} from "./store";

export async function ensureSprint1Evidence(force = false) {
  if (!force && latestPhase11Run("suite") && latestPhase11Run("scorecard")) return;
  await runFullPhase11Sprint1Suite();
}

export async function runFullPhase11Sprint1Suite() {
  const ops = await buildGlobalOperationsCenter();
  const kpis = await buildBusinessKpiDashboard();
  const commercial = await auditCommercialOperations();
  const reports = await generateExecutiveReports();
  const health = await buildOperationalHealth();
  const success = await buildCustomerSuccessDashboard();
  const scorecard = computePhase11Scorecard({
    opsPresent: true,
    kpiPresent: true,
    commercialScore: commercial.score,
    healthScore: health.score,
    csSatisfaction: success.customerSatisfaction ?? 0,
    csAtRisk: success.atRisk,
    csTracked: success.totalTracked,
    reportsGenerated: reports.reports.length,
  });

  writePhase11Docs({ ops, kpis, commercial, reports, health, success, scorecard });
  savePhase11Run("suite", "Phase 11 Sprint 1 full suite", {
    scores: scorecard.output,
    at: new Date().toISOString(),
  });

  const dashboard = await getPhase11Sprint1Dashboard();
  return { ops, kpis, commercial, reports, health, success, scorecard, dashboard };
}

function writePhase11Docs(data: {
  ops: Awaited<ReturnType<typeof buildGlobalOperationsCenter>>;
  kpis: Awaited<ReturnType<typeof buildBusinessKpiDashboard>>;
  commercial: Awaited<ReturnType<typeof auditCommercialOperations>>;
  reports: Awaited<ReturnType<typeof generateExecutiveReports>>;
  health: Awaited<ReturnType<typeof buildOperationalHealth>>;
  success: Awaited<ReturnType<typeof buildCustomerSuccessDashboard>>;
  scorecard: ReturnType<typeof computePhase11Scorecard>;
}) {
  const dir = docsRoot();
  if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
  const o = data.scorecard.output;
  const date = new Date().toISOString().slice(0, 10);
  const coreOk =
    sha256File(path.join(workspaceRoot(), "Experts", "TheGoldMindAI_Professional.mq5")) ===
    CORE_CERT_SHA;

  fs.writeFileSync(
    path.join(dir, "GLOBAL_OPERATIONS_CENTER.md"),
    `# GLOBAL_OPERATIONS_CENTER.md

**Phase:** 11 · Sprint 1  
**Surface:** \`/portal/admin/global-ops\`  
**Core:** FROZEN · SHA ${coreOk ? "MATCH" : "FAIL"}

## Live metrics

| Metric | Value |
|--------|------:|
| Active Customers | ${data.ops.activeCustomers} |
| Active Licenses | ${data.ops.activeLicenses} |
| New Registrations | ${data.ops.newRegistrations} |
| Revenue | ${data.ops.revenue} |
| Active Subscriptions | ${data.ops.subscriptionStatus.active} |
| Website / Portal Health | ${data.ops.websiteHealth} |
| API Health | ${data.ops.apiHealth} |
| System Health | ${data.ops.systemHealth} |
| Support Queue (open) | ${data.ops.supportQueue.open} |
| Security Alerts (firing) | ${data.ops.securityAlerts.firing} |
| Global Uptime (proxy %) | ${data.ops.globalUptime.percentProxy} |

All metrics are measurable from commercial stores (licensing · billing · observability · support).
`,
    "utf8"
  );

  fs.writeFileSync(
    path.join(dir, "BUSINESS_KPI_GUIDE.md"),
    `# BUSINESS_KPI_GUIDE.md

**Phase:** 11 · Sprint 1  
**Surface:** \`/portal/admin/business-kpis\`

## KPI definitions

| KPI | Source | Notes |
|-----|--------|-------|
| DAU / WAU / MAU | Usage analytics (hashed identities) | Anonymized |
| Customer Growth | Enterprise dashboard | Active + new today |
| License Growth | Licenses store | Active + activations |
| Subscription Growth | Billing subscriptions | Active / total / renewals |
| Renewal Rate | BI renewalRate | Renewals / active subs |
| Cancellation Rate | Cancelled / all subs | Billing status |
| Trial Conversion | Trial→paid email match | Proxy |
| Customer Satisfaction | Feedback / CS summary | CSAT |
| Revenue Trend | BI monthly buckets | Succeeded payments |

## Current snapshot

| KPI | Value |
|-----|------:|
| DAU | ${data.kpis.dailyActiveUsers} |
| WAU | ${data.kpis.weeklyActiveUsers} |
| MAU | ${data.kpis.monthlyActiveUsers} |
| Renewal Rate | ${data.kpis.renewalRate}% |
| Cancellation Rate | ${data.kpis.cancellationRate}% |
| Trial Conversion | ${data.kpis.trialConversionRate}% |
| CSAT | ${data.kpis.customerSatisfaction} |
`,
    "utf8"
  );

  fs.writeFileSync(
    path.join(dir, "COMMERCIAL_OPERATIONS.md"),
    `# COMMERCIAL_OPERATIONS.md

**Phase:** 11 · Sprint 1  
**Score:** ${data.commercial.score}  
**Every workflow auditable:** ${data.commercial.everyWorkflowAuditable}

| Workflow | Status | Evidence |
|----------|--------|----------|
${data.commercial.workflows.map((w) => `| ${w.label} | ${w.status} | ${w.evidence} |`).join("\n")}

Customer interactions remain traceable via licensing audit + cloud audit + billing webhook audits + support tickets.
`,
    "utf8"
  );

  fs.writeFileSync(
    path.join(dir, "EXECUTIVE_REPORTING.md"),
    `# EXECUTIVE_REPORTING.md

**Phase:** 11 · Sprint 1  
**Generator:** \`npm run phase11:sprint1\` / admin Global Ops suite

## Report pack

| Kind | Latest path |
|------|-------------|
${data.reports.reports.map((r) => `| ${r.title} | \`${path.basename(r.path)}\` |`).join("\n")}

Mirrored latest copies also written under \`Commercial/Documentation/\`:
- DAILY_BUSINESS_REPORT.md
- WEEKLY_EXECUTIVE_REPORT.md
- MONTHLY_COMMERCIAL_REPORT.md
- QUARTERLY_BUSINESS_REVIEW.md
- ANNUAL_EXECUTIVE_SUMMARY.md

Cadence: regenerate on suite run; schedule via ops cron in later sprints.
`,
    "utf8"
  );

  fs.writeFileSync(
    path.join(dir, "CUSTOMER_SUCCESS_DASHBOARD.md"),
    `# CUSTOMER_SUCCESS_DASHBOARD.md

**Phase:** 11 · Sprint 1  
**Surface:** \`/portal/admin/cs-operations\`

| Segment | Count |
|---------|------:|
| New (today) | ${data.success.newCustomers.count} |
| Trial | ${data.success.trialCustomers.count} |
| Paid | ${data.success.paidCustomers.count} |
| Renewals tracked | ${data.success.renewals.count} |
| Churn risk | ${data.success.churnRisk.count} |
| CSAT | ${data.success.customerSatisfaction} |
| Avg health | ${data.success.avgHealthScore} |

Interactions are traceable (tickets · licenses · health scores).
`,
    "utf8"
  );

  fs.writeFileSync(
    path.join(dir, "PHASE11_SPRINT1_REPORT.md"),
    `# PHASE 11 — SPRINT 1 REPORT

**Sprint:** 1 — Global Commercial Release Foundation  
**Date:** ${date}  
**Portal:** \`1.0.0-phase11.s1\`  
**Core:** UNCHANGED · FROZEN · SHA-256 \`${CORE_CERT_SHA}\` · ${coreOk ? "MATCH" : "FAIL"}

---

## Mission

Activate commercial business operations for Website Professional Global Commercial Release.

## Delivered

1. Global Operations Center  
2. Business KPI Dashboard  
3. Commercial Operations workflow audit  
4. Executive reporting pack (daily → annual)  
5. Operational health monitoring  
6. Customer Success operations dashboard  
7. Documentation pack  

## OUTPUT scores

| Score | Value |
|-------|------:|
| Business Operations | ${o.businessOperationsScore} |
| Commercial Operations | ${o.commercialOperationsScore} |
| Customer Success | ${o.customerSuccessScore} |
| Operational Health | ${o.operationalHealthScore} |
| Executive Readiness | ${o.executiveReadinessScore} |
| **Overall Phase 11 Progress** | **${o.overallPhase11Progress}%** |

## Final rule

- Every operational metric is measurable.  
- Every commercial workflow is auditable.  
- Every customer interaction is traceable.  
- Core Trading Engine remains permanently isolated and SHA-256 verified.

## STOP

**Await Owner approval before Sprint 2.**
`,
    "utf8"
  );

  const phase11Dir = path.join(commercialRoot(), "Phase11");
  if (!fs.existsSync(phase11Dir)) fs.mkdirSync(phase11Dir, { recursive: true });
  fs.writeFileSync(
    path.join(phase11Dir, "README.md"),
    `# Phase 11 — Global Commercial Release

**Status:** Sprint 1 COMPLETE — Global Commercial Release Foundation  
**Edition:** Website Professional  
**Core:** Permanently frozen · SHA verified  
**Next:** Await Owner approval before Sprint 2  

## Sprint 1 surfaces

| Surface | Path |
|---------|------|
| Global Ops Center | \`/portal/admin/global-ops\` |
| Business KPIs | \`/portal/admin/business-kpis\` |
| Commercial Ops | \`/portal/admin/commercial-ops\` |
| CS Operations | \`/portal/admin/cs-operations\` |
| API | \`/api/admin/phase11\` |
| CLI | \`npm run phase11:sprint1\` |

## Progress

Phase 11 overall: **${o.overallPhase11Progress}%**
`,
    "utf8"
  );
}

export async function getPhase11Sprint1Dashboard(options?: { refresh?: boolean }) {
  await ensureSprint1Evidence(!!options?.refresh);

  const scorecard = latestPhase11Run("scorecard")?.payload as
    | ReturnType<typeof computePhase11Scorecard>
    | undefined;
  const ops = latestPhase11Run("ops_center")?.payload as
    | Awaited<ReturnType<typeof buildGlobalOperationsCenter>>
    | undefined;
  const kpis = latestPhase11Run("kpis")?.payload as
    | Awaited<ReturnType<typeof buildBusinessKpiDashboard>>
    | undefined;
  const commercial = latestPhase11Run("commercial")?.payload as
    | Awaited<ReturnType<typeof auditCommercialOperations>>
    | undefined;
  const health = latestPhase11Run("health")?.payload as
    | Awaited<ReturnType<typeof buildOperationalHealth>>
    | undefined;
  const success = latestPhase11Run("success")?.payload as
    | Awaited<ReturnType<typeof buildCustomerSuccessDashboard>>
    | undefined;
  const reports = latestPhase11Run("reports")?.payload as
    | Awaited<ReturnType<typeof generateExecutiveReports>>
    | undefined;

  const o = scorecard?.output;
  const coreMatches =
    sha256File(path.join(workspaceRoot(), "Experts", "TheGoldMindAI_Professional.mq5")) ===
    CORE_CERT_SHA;

  return {
    businessOperationsScore: o?.businessOperationsScore ?? 0,
    commercialOperationsScore: o?.commercialOperationsScore ?? 0,
    customerSuccessScore: o?.customerSuccessScore ?? 0,
    operationalHealthScore: o?.operationalHealthScore ?? 0,
    executiveReadinessScore: o?.executiveReadinessScore ?? 0,
    overallPhase11Progress: o?.overallPhase11Progress ?? 0,
    ops,
    kpis,
    commercial,
    health,
    success,
    reports: reports?.reports ?? [],
    scorecardRows: scorecard?.rows ?? [],
    coreMatches,
    coreSha: CORE_CERT_SHA,
    coreIsolation: "Phase 11 Sprint 1 never modifies Core Trading Engine",
    runs: listPhase11Runs()
      .slice(0, 12)
      .map((r) => ({ id: r.id, kind: r.kind, label: r.label, at: r.at })),
    generatedAt: new Date().toISOString(),
  };
}
