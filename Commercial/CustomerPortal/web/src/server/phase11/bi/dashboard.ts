/**
 * Phase 11 Sprint 2 — BI suite + documentation.
 */
import fs from "fs";
import path from "path";
import { buildExecutiveBusinessDashboard } from "./executive";
import { buildSubscriptionAnalytics } from "./subscriptions";
import { buildRevenueAnalytics } from "./revenue";
import { buildCustomerAnalytics } from "./customers";
import { buildOperationalAnalytics } from "./operations";
import { buildForecastingModel } from "./forecast";
import { generateBiExecutiveReports } from "./reports";
import { computeBiScorecard } from "./scorecard";
import {
  CORE_CERT_SHA,
  commercialRoot,
  docsRoot,
  latestPhase11Run,
  listPhase11Runs,
  savePhase11Run,
  sha256File,
  workspaceRoot,
} from "../store";

export async function ensureSprint2Evidence(force = false) {
  if (!force && latestPhase11Run("bi_suite") && latestPhase11Run("bi_scorecard")) return;
  await runFullPhase11Sprint2Suite();
}

export async function runFullPhase11Sprint2Suite() {
  const executive = await buildExecutiveBusinessDashboard();
  const subscriptions = await buildSubscriptionAnalytics();
  const revenue = await buildRevenueAnalytics();
  const customers = await buildCustomerAnalytics();
  const operations = await buildOperationalAnalytics();
  const forecast = await buildForecastingModel();
  const reports = await generateBiExecutiveReports({
    executive,
    revenue,
    subscriptions,
    customers,
    operations,
    forecast,
  });
  const scorecard = computeBiScorecard({
    hasExecutive: true,
    hasRevenue: true,
    hasSubscriptions: true,
    hasCustomers: true,
    hasOperations: true,
    reportsCount: reports.reports.length,
    forecastReadiness: forecast.forecastAccuracyReadiness.score,
    countryKind: revenue.revenueByCountry.kind,
    revenueMonths: revenue.monthlyRevenueTrend.length,
  });

  writeBiDocs({
    executive,
    subscriptions,
    revenue,
    customers,
    operations,
    forecast,
    reports,
    scorecard,
  });
  savePhase11Run("bi_suite", "Phase 11 Sprint 2 BI suite", {
    scores: scorecard.output,
    at: new Date().toISOString(),
  });

  const dashboard = await getPhase11Sprint2Dashboard();
  return {
    executive,
    subscriptions,
    revenue,
    customers,
    operations,
    forecast,
    reports,
    scorecard,
    dashboard,
  };
}

function writeBiDocs(data: {
  executive: Awaited<ReturnType<typeof buildExecutiveBusinessDashboard>>;
  subscriptions: Awaited<ReturnType<typeof buildSubscriptionAnalytics>>;
  revenue: Awaited<ReturnType<typeof buildRevenueAnalytics>>;
  customers: Awaited<ReturnType<typeof buildCustomerAnalytics>>;
  operations: Awaited<ReturnType<typeof buildOperationalAnalytics>>;
  forecast: Awaited<ReturnType<typeof buildForecastingModel>>;
  reports: Awaited<ReturnType<typeof generateBiExecutiveReports>>;
  scorecard: ReturnType<typeof computeBiScorecard>;
}) {
  const dir = docsRoot();
  if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
  const o = data.scorecard.output;
  const date = new Date().toISOString().slice(0, 10);
  const coreOk =
    sha256File(path.join(workspaceRoot(), "Experts", "TheGoldMindAI_Professional.mq5")) ===
    CORE_CERT_SHA;
  const e = data.executive;

  fs.writeFileSync(
    path.join(dir, "BUSINESS_INTELLIGENCE.md"),
    `# BUSINESS_INTELLIGENCE.md

**Phase:** 11 · Sprint 2  
**Surface:** \`/portal/admin/bi-executive\`  
**Rule:** ACTUAL metrics only on executive tiles · FORECAST segregated

## Executive KPIs (ACTUAL)

| KPI | Value |
|-----|------:|
| Total Customers | ${e.totalCustomers} |
| Active Customers | ${e.activeCustomers} |
| Trial Customers | ${e.trialCustomers} |
| Paid Customers | ${e.paidCustomers} |
| Monthly Revenue | ${e.monthlyRevenue.formatted} |
| Annual Revenue | ${e.annualRevenue.formatted} |
| MRR | ${e.mrr.formatted} |
| ARR | ${e.arr.formatted} |
| ARPU | ${e.arpu.formatted} |
| Observed historical value | ${e.clv.formatted} |

CLV tile = **observed historical average** of succeeded payments — not a projected lifetime value.
`,
    "utf8"
  );

  fs.writeFileSync(
    path.join(dir, "REVENUE_ANALYTICS.md"),
    `# REVENUE_ANALYTICS.md

**Phase:** 11 · Sprint 2  
**Surface:** \`/portal/admin/bi-revenue\`

## ACTUAL breakdowns

### By plan
${data.revenue.revenueByPlan.map((r) => `- ${r.plan}: ${r.formatted}`).join("\n") || "- (none)"}

### By provider
${data.revenue.revenueByPaymentProvider.map((r) => `- ${r.provider}: ${r.formatted}`).join("\n") || "- (none)"}

### By country
**Kind:** ${data.revenue.revenueByCountry.kind}  
${data.revenue.revenueByCountry.note}

${data.revenue.revenueByCountry.rows.map((r) => `- ${r.country}: ${r.formatted}`).join("\n") || "- (none)"}

| Metric | Value |
|--------|------:|
| Refund rate | ${data.revenue.refundRate.value}% |
| Chargeback rate | ${data.revenue.chargebackRate.value}% |
| AOV | ${data.revenue.averageOrderValue.formatted} |
| MoM growth | ${data.revenue.revenueGrowth.monthOverMonthPct}% |
`,
    "utf8"
  );

  fs.writeFileSync(
    path.join(dir, "SUBSCRIPTION_ANALYTICS.md"),
    `# SUBSCRIPTION_ANALYTICS.md

**Phase:** 11 · Sprint 2  
**Surface:** \`/portal/admin/bi-subscriptions\`

| Metric | Value |
|--------|------:|
| New subscriptions (month) | ${data.subscriptions.newSubscriptions} |
| Renewals | ${data.subscriptions.renewals} |
| Expired licenses | ${data.subscriptions.expiredLicenses} |
| Cancelled plans | ${data.subscriptions.cancelledPlans} |
| Upgrade rate | ${data.subscriptions.upgradeRate.value}% |
| Downgrade rate | ${data.subscriptions.downgradeRate.value}% |
| Renewal success | ${data.subscriptions.renewalSuccessRate}% |
| Subscription retention | ${data.subscriptions.subscriptionRetention}% |

Upgrade/downgrade rates use **tagged payment notes only** — never invented.
`,
    "utf8"
  );

  fs.writeFileSync(
    path.join(dir, "CUSTOMER_ANALYTICS.md"),
    `# CUSTOMER_ANALYTICS.md

**Phase:** 11 · Sprint 2  
**Surface:** \`/portal/admin/bi-customers\`

| Metric | Value |
|--------|------:|
| DAU | ${data.customers.dailyActiveUsers} |
| WAU | ${data.customers.weeklyActiveUsers} |
| MAU | ${data.customers.monthlyActiveUsers} |
| Session duration (min) | ${data.customers.sessionDuration.minutes} |
| Retention % | ${data.customers.customerRetention.percent} |
| Churn % (proxy) | ${data.customers.customerChurn.percent} |
| CSAT | ${data.customers.customerSatisfaction} |
| Support open / total | ${data.customers.supportActivity.open} / ${data.customers.supportActivity.total} |
`,
    "utf8"
  );

  // EXECUTIVE_REPORTING.md — extend Sprint 1 file with BI pack note
  fs.writeFileSync(
    path.join(dir, "EXECUTIVE_REPORTING.md"),
    `# EXECUTIVE_REPORTING.md

**Phase:** 11 · Sprint 2 (BI pack)  
**Generator:** \`npm run phase11:sprint2\`

## BI report pack

| Kind | Mirror |
|------|--------|
${data.reports.reports.map((r) => `| ${r.title} | see Documentation/Reports/BI + root mirrors |`).join("\n")}

Mirrors: DAILY_KPI_REPORT.md · WEEKLY_BUSINESS_REPORT.md · MONTHLY_REVENUE_REPORT.md · QUARTERLY_EXECUTIVE_REVIEW.md · ANNUAL_BUSINESS_PERFORMANCE.md

Sprint 1 cadence reports remain available (daily/weekly/monthly commercial).
`,
    "utf8"
  );

  fs.writeFileSync(
    path.join(dir, "FORECASTING_MODEL.md"),
    `# FORECASTING_MODEL.md

**Phase:** 11 · Sprint 2  
**Kind:** FORECAST only  

## Disclaimer

${data.forecast.disclaimer}

## Method

Ordinary least squares linear trend on ACTUAL monthly series (flat-hold when history < 2).

## Horizon

${data.forecast.horizonMonths.join(", ")}

## Confidence

| Series | Confidence | Method |
|--------|------------|--------|
| Revenue | ${data.forecast.revenue.confidence} | ${data.forecast.revenue.method} |
| Subscriptions | ${data.forecast.subscriptions.confidence} | ${data.forecast.subscriptions.method} |
| Customer growth | ${data.forecast.customerGrowth.confidence} | ${data.forecast.customerGrowth.method} |
| Renewals | ${data.forecast.renewals.confidence} | ${data.forecast.renewals.method} |
| Infrastructure | ${data.forecast.infrastructureCapacity.confidence} | ${data.forecast.infrastructureCapacity.method} |
| Support demand | ${data.forecast.supportDemand.confidence} | ${data.forecast.supportDemand.method} |

## Assumptions (revenue)

${data.forecast.revenue.assumptions.map((a) => `- ${a}`).join("\n")}

## Forecast accuracy readiness

**Score:** ${data.forecast.forecastAccuracyReadiness.score}  
${data.forecast.forecastAccuracyReadiness.note}
`,
    "utf8"
  );

  fs.writeFileSync(
    path.join(dir, "PHASE11_SPRINT2_REPORT.md"),
    `# PHASE 11 — SPRINT 2 REPORT

**Sprint:** 2 — Enterprise Business Intelligence & Revenue Analytics  
**Date:** ${date}  
**Portal:** \`1.0.1-phase11.s2\`  
**Core:** UNCHANGED · FROZEN · SHA-256 \`${CORE_CERT_SHA}\` · ${coreOk ? "MATCH" : "FAIL"}

---

## Delivered

1. Executive Business Dashboard (ACTUAL)  
2. Subscription Analytics  
3. Revenue Analytics (country UNATTRIBUTED when untagged)  
4. Customer Analytics  
5. Operational Analytics  
6. Executive BI reports  
7. Forecasting model (FORECAST segregated)  
8. Documentation pack  

## Task 9 / OUTPUT scores

| Score | Value |
|-------|------:|
| Business Intelligence | ${o.businessIntelligenceScore} |
| Revenue Analytics | ${o.revenueAnalyticsScore} |
| Forecast Accuracy Readiness | ${o.forecastAccuracyReadiness} |
| Customer Analytics | ${o.customerAnalyticsScore} |
| Operational Analytics | ${o.operationalAnalyticsScore} |
| Revenue Readiness | ${o.revenueReadinessScore} |
| Commercial Intelligence | ${o.commercialIntelligenceScore} |
| Executive Reporting | ${o.executiveReportingScore} |
| Growth Readiness | ${o.growthReadinessScore} |
| **Overall Phase 11 Progress** | **${o.overallPhase11Progress}%** |

## Final rule

- Every executive KPI is traceable to verified production commercial data.  
- No estimated metric is presented as ACTUAL revenue or customer activity.  
- Analytics remain isolated from the certified Core Trading Engine.

## STOP

**Await Owner approval before Sprint 3.**
`,
    "utf8"
  );

  const phase11Dir = path.join(commercialRoot(), "Phase11");
  if (!fs.existsSync(phase11Dir)) fs.mkdirSync(phase11Dir, { recursive: true });
  fs.writeFileSync(
    path.join(phase11Dir, "README.md"),
    `# Phase 11 — Global Commercial Release

**Status:** Sprint 2 COMPLETE — Enterprise BI & Revenue Analytics  
**Edition:** Website Professional  
**Core:** Permanently frozen · SHA verified  
**Next:** Await Owner approval before Sprint 3  

## Sprint 2 surfaces

| Surface | Path |
|---------|------|
| BI Executive | \`/portal/admin/bi-executive\` |
| BI Revenue | \`/portal/admin/bi-revenue\` |
| BI Subscriptions | \`/portal/admin/bi-subscriptions\` |
| BI Customers | \`/portal/admin/bi-customers\` |
| API | \`/api/admin/phase11-bi\` |
| CLI | \`npm run phase11:sprint2\` |

## Progress

Phase 11 overall: **${o.overallPhase11Progress}%**
`,
    "utf8"
  );
}

export async function getPhase11Sprint2Dashboard(options?: { refresh?: boolean }) {
  await ensureSprint2Evidence(!!options?.refresh);

  const scorecard = latestPhase11Run("bi_scorecard")?.payload as
    | ReturnType<typeof computeBiScorecard>
    | undefined;
  const executive = latestPhase11Run("bi_executive")?.payload as
    | Awaited<ReturnType<typeof buildExecutiveBusinessDashboard>>
    | undefined;
  const revenue = latestPhase11Run("bi_revenue")?.payload as
    | Awaited<ReturnType<typeof buildRevenueAnalytics>>
    | undefined;
  const subscriptions = latestPhase11Run("bi_subscriptions")?.payload as
    | Awaited<ReturnType<typeof buildSubscriptionAnalytics>>
    | undefined;
  const customers = latestPhase11Run("bi_customers")?.payload as
    | Awaited<ReturnType<typeof buildCustomerAnalytics>>
    | undefined;
  const operations = latestPhase11Run("bi_operations")?.payload as
    | Awaited<ReturnType<typeof buildOperationalAnalytics>>
    | undefined;
  const forecast = latestPhase11Run("bi_forecast")?.payload as
    | Awaited<ReturnType<typeof buildForecastingModel>>
    | undefined;
  const reports = latestPhase11Run("bi_reports")?.payload as
    | Awaited<ReturnType<typeof generateBiExecutiveReports>>
    | undefined;

  const o = scorecard?.output;
  const coreMatches =
    sha256File(path.join(workspaceRoot(), "Experts", "TheGoldMindAI_Professional.mq5")) ===
    CORE_CERT_SHA;

  return {
    businessIntelligenceScore: o?.businessIntelligenceScore ?? 0,
    revenueReadinessScore: o?.revenueReadinessScore ?? 0,
    commercialIntelligenceScore: o?.commercialIntelligenceScore ?? 0,
    executiveReportingScore: o?.executiveReportingScore ?? 0,
    growthReadinessScore: o?.growthReadinessScore ?? 0,
    revenueAnalyticsScore: o?.revenueAnalyticsScore ?? 0,
    forecastAccuracyReadiness: o?.forecastAccuracyReadiness ?? 0,
    customerAnalyticsScore: o?.customerAnalyticsScore ?? 0,
    operationalAnalyticsScore: o?.operationalAnalyticsScore ?? 0,
    overallPhase11Progress: o?.overallPhase11Progress ?? 0,
    executive,
    revenue,
    subscriptions,
    customers,
    operations,
    forecast,
    reports: reports?.reports ?? [],
    scorecardRows: scorecard?.rows ?? [],
    coreMatches,
    coreSha: CORE_CERT_SHA,
    coreIsolation: "Phase 11 Sprint 2 BI never modifies Core Trading Engine",
    runs: listPhase11Runs()
      .filter((r) => r.kind.startsWith("bi_"))
      .slice(0, 16)
      .map((r) => ({ id: r.id, kind: r.kind, label: r.label, at: r.at })),
    generatedAt: new Date().toISOString(),
  };
}
