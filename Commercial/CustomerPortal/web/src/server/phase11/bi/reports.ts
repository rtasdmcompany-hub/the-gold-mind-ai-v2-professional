/**
 * Task 6 — Executive BI reports (auto-generated from ACTUAL + optional FORECAST appendix).
 */
import fs from "fs";
import path from "path";
import { commercialRoot, docsRoot, savePhase11Run } from "../store";
import { formatUsd } from "./helpers";
import type { buildExecutiveBusinessDashboard } from "./executive";
import type { buildRevenueAnalytics } from "./revenue";
import type { buildSubscriptionAnalytics } from "./subscriptions";
import type { buildCustomerAnalytics } from "./customers";
import type { buildOperationalAnalytics } from "./operations";
import type { buildForecastingModel } from "./forecast";

export async function generateBiExecutiveReports(input: {
  executive: Awaited<ReturnType<typeof buildExecutiveBusinessDashboard>>;
  revenue: Awaited<ReturnType<typeof buildRevenueAnalytics>>;
  subscriptions: Awaited<ReturnType<typeof buildSubscriptionAnalytics>>;
  customers: Awaited<ReturnType<typeof buildCustomerAnalytics>>;
  operations: Awaited<ReturnType<typeof buildOperationalAnalytics>>;
  forecast: Awaited<ReturnType<typeof buildForecastingModel>>;
}) {
  const stamp = new Date().toISOString().slice(0, 10);
  const dir = path.join(commercialRoot(), "Documentation", "Reports", "BI");
  if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });

  const e = input.executive;
  const actualBlock = `
## ACTUAL metrics (verified production data)

| KPI | Value |
|-----|------:|
| Total Customers | ${e.totalCustomers} |
| Active Customers | ${e.activeCustomers} |
| Trial / Paid | ${e.trialCustomers} / ${e.paidCustomers} |
| Monthly Revenue | ${e.monthlyRevenue.formatted} |
| Annual Revenue | ${e.annualRevenue.formatted} |
| MRR | ${e.mrr.formatted} |
| ARR | ${e.arr.formatted} |
| ARPU | ${e.arpu.formatted} |
| Observed historical value (CLV proxy) | ${e.clv.formatted} |
| DAU / WAU / MAU | ${input.customers.dailyActiveUsers} / ${input.customers.weeklyActiveUsers} / ${input.customers.monthlyActiveUsers} |
| Renewal Success | ${input.subscriptions.renewalSuccessRate}% |
| Refund Rate | ${input.revenue.refundRate.value}% |
`;

  const forecastAppendix = `
## FORECAST appendix (not ACTUAL)

**Disclaimer:** ${input.forecast.disclaimer}

| Horizon | Revenue (forecast) | New subs (forecast) | Growth (forecast) |
|---------|-------------------:|--------------------:|------------------:|
${input.forecast.horizonMonths
  .map(
    (m, i) =>
      `| ${m} | ${input.forecast.revenue.formatted[i]} | ${input.forecast.subscriptions.values[i]} | ${input.forecast.customerGrowth.values[i]} |`
  )
  .join("\n")}

Confidence (revenue): **${input.forecast.revenue.confidence}** · method: ${input.forecast.revenue.method}
`;

  const specs = [
    {
      kind: "daily_kpi",
      file: `DAILY_KPI_REPORT_${stamp}.md`,
      mirror: "DAILY_KPI_REPORT.md",
      title: "Daily KPI Report",
      body: `# Daily KPI Report\n\n**Date:** ${stamp}\n\n${actualBlock}\n`,
    },
    {
      kind: "weekly_business",
      file: `WEEKLY_BUSINESS_REPORT_${stamp}.md`,
      mirror: "WEEKLY_BUSINESS_REPORT.md",
      title: "Weekly Business Report",
      body: `# Weekly Business Report\n\n**Week ending:** ${stamp}\n\n${actualBlock}\n\n### Subscriptions\n- New: ${input.subscriptions.newSubscriptions}\n- Renewals: ${input.subscriptions.renewals}\n- Cancelled: ${input.subscriptions.cancelledPlans}\n`,
    },
    {
      kind: "monthly_revenue",
      file: `MONTHLY_REVENUE_REPORT_${stamp}.md`,
      mirror: "MONTHLY_REVENUE_REPORT.md",
      title: "Monthly Revenue Report",
      body: `# Monthly Revenue Report\n\n**As of:** ${stamp}\n\n${actualBlock}\n\n### By plan\n${input.revenue.revenueByPlan.map((r) => `- ${r.plan}: ${r.formatted}`).join("\n")}\n\n### Trend\n${input.revenue.monthlyRevenueTrend.map((t) => `- ${t.month}: ${t.formatted} (ACTUAL)`).join("\n")}\n`,
    },
    {
      kind: "quarterly_executive",
      file: `QUARTERLY_EXECUTIVE_REVIEW_${stamp}.md`,
      mirror: "QUARTERLY_EXECUTIVE_REVIEW.md",
      title: "Quarterly Executive Review",
      body: `# Quarterly Executive Review\n\n**As of:** ${stamp}\n\n${actualBlock}\n\n### Operations\n- Portal ms: ${input.operations.portalPerformance.loadMs}\n- API ms: ${input.operations.apiPerformance.responseMs}\n- Auth success: ${input.operations.authenticationSuccess.rate}%\n- Payment success: ${input.operations.paymentSuccess.rate}%\n\n${forecastAppendix}\n`,
    },
    {
      kind: "annual_performance",
      file: `ANNUAL_BUSINESS_PERFORMANCE_${stamp.slice(0, 4)}.md`,
      mirror: "ANNUAL_BUSINESS_PERFORMANCE.md",
      title: "Annual Business Performance",
      body: `# Annual Business Performance\n\n**Year:** ${stamp.slice(0, 4)}\n\n${actualBlock}\n\nTotal succeeded revenue (ACTUAL YTD bucket in annual KPI): ${e.annualRevenue.formatted}\n\n${forecastAppendix}\n`,
    },
  ];

  const metas = [];
  for (const s of specs) {
    const p = path.join(dir, s.file);
    fs.writeFileSync(p, s.body, "utf8");
    fs.writeFileSync(path.join(docsRoot(), s.mirror), s.body, "utf8");
    metas.push({ kind: s.kind, title: s.title, path: p, generatedAt: new Date().toISOString() });
  }

  const payload = {
    reports: metas,
    totalSucceededReference: formatUsd(input.revenue.totalSucceeded.cents),
    at: new Date().toISOString(),
  };
  savePhase11Run("bi_reports", "BI executive reports", payload);
  return payload;
}
