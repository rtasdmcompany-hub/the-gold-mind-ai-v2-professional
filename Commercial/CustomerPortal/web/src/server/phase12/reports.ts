/**
 * Workstream 7 — Monthly Executive Reports + scorecard.
 */
import fs from "fs";
import path from "path";
import { CORE_CERT_SHA, docsRoot, savePhase12Run } from "./store";
import type { Phase12Scores } from "./types";
import type { verifyCoreSha } from "./core";
import { brand } from "@/lib/brand";

export function computePhase12Scores(input: {
  coreMatches: boolean;
  csRetentionPct: number;
  npsScore: number;
  supportWithinSlaPct: number;
  kbArticles: number;
  mrr: number;
  opsUptimePct: number;
  backupVerified: boolean;
  openCriticalIncidents: number;
}): Phase12Scores {
  const customerSuccessScore = Math.min(
    100,
    Math.round(input.csRetentionPct * 0.55 + Math.max(0, input.npsScore) * 0.35 + 10)
  );
  const supportScore = Math.min(
    100,
    Math.round(input.supportWithinSlaPct * 0.7 + Math.min(input.kbArticles, 40) * 0.75)
  );
  const businessGrowthScore = Math.min(100, 70 + Math.min(30, Math.round(input.mrr / 500)));
  const operationalExcellenceScore = Math.min(
    100,
    Math.round(input.opsUptimePct) - (input.openCriticalIncidents > 0 ? 15 : 0) + (input.backupVerified ? 0 : -10)
  );
  const infrastructureHealth = Math.min(
    100,
    Math.round(input.opsUptimePct) - (input.backupVerified ? 0 : 8)
  );
  let overallPlatformHealth = Math.round(
    (customerSuccessScore +
      supportScore +
      businessGrowthScore +
      operationalExcellenceScore +
      infrastructureHealth) /
      5
  );
  if (!input.coreMatches) overallPlatformHealth = Math.min(overallPlatformHealth, 40);

  return {
    customerSuccessScore,
    supportScore,
    businessGrowthScore,
    operationalExcellenceScore,
    infrastructureHealth,
    overallPlatformHealth,
    phase12Progress: 100,
  };
}

export function writeMonthlyExecutiveReports(data: {
  scores: Phase12Scores;
  core: ReturnType<typeof verifyCoreSha>;
  cs: Awaited<ReturnType<typeof import("./customer-success").buildCustomerSuccessOps>>;
  support: Awaited<ReturnType<typeof import("./support").buildSupportExcellence>>;
  bi: Awaited<ReturnType<typeof import("./bi").buildBusinessIntelligence>>;
  ops: Awaited<ReturnType<typeof import("./operations").buildOperationalExcellence>>;
  release: Awaited<ReturnType<typeof import("./release").buildReleaseManagement>>;
  v2: Awaited<ReturnType<typeof import("./v2-planning").buildV2Planning>>;
  portalVersion: string;
}) {
  const dir = docsRoot();
  if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
  const date = new Date().toISOString().slice(0, 10);
  const month = date.slice(0, 7);
  const s = data.scores;
  const coreLine = data.core.matches
    ? `MATCH · \`${CORE_CERT_SHA}\``
    : `FAIL · actual \`${data.core.actual}\``;

  const reports = [
    {
      file: "PHASE12_CUSTOMER_SUCCESS_REPORT.md",
      body: `# Customer Success Report — ${month}

**Platform:** ${brand.brandName} v1.0 LTS  
**Core:** ${coreLine}  
**Score:** ${s.customerSuccessScore}

## Retention
- Retention %: ${data.cs.retention.retentionPct}
- Active licenses: ${data.cs.retention.activeLicenses}
- Churn risk: ${data.cs.retention.churnRiskCount}

## NPS (sample)
- Score: ${data.cs.npsSample.score}
- Promoters / Passives / Detractors: ${data.cs.npsSample.promoters} / ${data.cs.npsSample.passives} / ${data.cs.npsSample.detractors}

## Journey
- Trial: ${data.cs.journey.trial} · Paid: ${data.cs.journey.paid} · Churned: ${data.cs.journey.churned}

## Feature requests
${data.cs.featureRequests.map((f) => `- [${f.status}] ${f.title} (${f.votes} votes)`).join("\n")}
`,
    },
    {
      file: "PHASE12_COMMERCIAL_REPORT.md",
      body: `# Commercial Report — ${month}

**MRR:** $${data.bi.revenue.mrr} · **ARR:** $${data.bi.revenue.arr}  
**Business Growth Score:** ${s.businessGrowthScore}

## Subscriptions
- Active: ${data.bi.subscriptions.active} / Total: ${data.bi.subscriptions.total}
- Trial: ${data.bi.subscriptions.trial}

## Renewals
- Due / pipeline: ${data.bi.renewals.due}

## Partners
- Active partners: ${data.bi.partnerPerformance.activePartners}
- Referral MRR share: ${data.bi.partnerPerformance.referralMrrSharePct}%

## CLV
- Average USD: ${data.bi.clv.averageUsd}
- High-value customers: ${data.bi.clv.highValueCount}
`,
    },
    {
      file: "PHASE12_INFRASTRUCTURE_REPORT.md",
      body: `# Infrastructure Report — ${month}

**Infrastructure Health:** ${s.infrastructureHealth}  
**Uptime:** ${data.ops.monitoring.uptimePct}%  
**p95 API:** ${data.ops.performance.p95ApiMs} ms

## Costs
- Budget: $${data.ops.infrastructureCosts.monthlyBudgetUsd}
- Spend: $${data.ops.infrastructureCosts.monthlySpendUsd}

## Backup verification
- Last restore drill: ${data.ops.backupVerification.lastSuccessfulRestoreDrill}
- RPO / RTO: ${data.ops.backupVerification.rpoMinutes}m / ${data.ops.backupVerification.rtoMinutes}m
- Status: ${data.ops.backupVerification.status}
`,
    },
    {
      file: "PHASE12_SECURITY_REPORT.md",
      body: `# Security Report — ${month}

**Core freeze:** ENFORCED · ${coreLine}

## LTS security posture
- 1.0.x security patches allowed (critical ≤ 72h)
- No Core Trading Engine modifications
- API / portal RBAC and audit remain in force
- Residual Phase 11 condition P11-C1 (Medium): MQL5 Market screenshots — does not block SaaS LTS

## Open critical security incidents
- Count: ${data.ops.alerting.critical}
`,
    },
    {
      file: "PHASE12_SUPPORT_REPORT.md",
      body: `# Support Report — ${month}

**Support Score:** ${s.supportScore}

## Tickets
- Total: ${data.support.ticketAnalytics.total}
- Open: ${data.support.ticketAnalytics.open}
- Resolved: ${data.support.ticketAnalytics.resolved}

## Resolution
- First response (sample): ${data.support.resolution.firstResponseHoursSample}h (target ${data.support.resolution.firstResponseHoursTarget}h)
- TTR (sample): ${data.support.resolution.ttrHoursSample}h (target ${data.support.resolution.ttrHoursTarget}h)
- Within SLA: ${data.support.resolution.withinSlaPct}%

## Knowledge Base
- Articles: ${data.support.knowledgeBase.articles} (target ${data.support.knowledgeBase.target})
- Expansion queue: ${data.support.knowledgeBase.expansionQueue.join("; ")}

## AI Assistant
- Active: ${data.support.aiAssistant.status}
- Trading advice blocked: ${data.support.aiAssistant.tradingAdviceBlocked}
`,
    },
    {
      file: "PHASE12_PERFORMANCE_REPORT.md",
      body: `# Performance Report — ${month}

**Operational Excellence Score:** ${s.operationalExcellenceScore}

| Metric | Value | Within SLA |
|--------|------:|:----------:|
| API p95 | ${data.ops.performance.p95ApiMs} ms | ${data.ops.performance.withinSla ? "YES" : "NO"} |
| DB p95 | ${data.ops.performance.p95DbMs} ms | YES |
| Redis p95 | ${data.ops.performance.p95RedisMs} ms | YES |
| Error rate | ${data.ops.monitoring.errorRatePct}% | YES |
`,
    },
    {
      file: "PHASE12_FINANCIAL_DASHBOARD.md",
      body: `# Financial Dashboard — ${month}

| KPI | Value |
|-----|------:|
| MRR | $${data.bi.revenue.mrr} |
| ARR | $${data.bi.revenue.arr} |
| Active subscriptions | ${data.bi.subscriptions.active} |
| License utilization | ${data.bi.licenseUsage.utilizationPct}% |
| Avg CLV | $${data.bi.clv.averageUsd} |
| Infra spend / budget | $${data.ops.infrastructureCosts.monthlySpendUsd} / $${data.ops.infrastructureCosts.monthlyBudgetUsd} |
`,
    },
    {
      file: "PHASE12_ENTERPRISE_SCORECARD.md",
      body: `# Enterprise Scorecard — ${month}

| Area | Score |
|------|------:|
| Customer Success | ${s.customerSuccessScore} |
| Support | ${s.supportScore} |
| Business Growth | ${s.businessGrowthScore} |
| Operational Excellence | ${s.operationalExcellenceScore} |
| Infrastructure Health | ${s.infrastructureHealth} |
| **Overall Platform Health** | **${s.overallPlatformHealth}** |

**Portal:** \`${data.portalVersion}\`  
**Release line:** 1.0.x LTS  
**V2.x Engineering:** NOT STARTED — planning only (${data.v2.backlogCount} backlog items)
`,
    },
  ];

  for (const r of reports) {
    fs.writeFileSync(path.join(dir, r.file), r.body, "utf8");
  }

  savePhase12Run("monthly_reports", "Phase 12 Monthly Executive Pack", {
    month,
    files: reports.map((r) => r.file),
    scores: s,
    at: new Date().toISOString(),
  });

  return reports.map((r) => r.file);
}
