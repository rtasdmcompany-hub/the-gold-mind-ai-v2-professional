/**
 * Task 4 — Executive reporting generators (automatic, measurable).
 */
import fs from "fs";
import path from "path";
import {
  safeBusinessIntelligence,
  safeCustomerSuccessSummary,
  safeEnsureCommercialData,
  safeEnterpriseDashboard,
  safeUsageAnalytics,
} from "./safe";
import { commercialRoot, docsRoot, savePhase11Run } from "./store";

export type ReportKind = "daily" | "weekly" | "monthly" | "quarterly" | "annual";

export interface ExecutiveReportMeta {
  kind: ReportKind;
  title: string;
  path: string;
  generatedAt: string;
}

function ensureReportsDir(): string {
  const dir = path.join(commercialRoot(), "Documentation", "Reports");
  if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
  return dir;
}

export async function generateExecutiveReports() {
  safeEnsureCommercialData();
  
  const enterprise = await safeEnterpriseDashboard();
  const bi = await safeBusinessIntelligence();
  
  // FIX: Added await here because safeCustomerSuccessSummary is now async
  const cs = await safeCustomerSuccessSummary();
  
  const usage = safeUsageAnalytics();
  const stamp = new Date().toISOString().slice(0, 10);
  const dir = ensureReportsDir();

  const common = `
| Metric | Value |
|--------|------:|
| Active Customers | ${enterprise.activeCustomers} |
| Active Licenses | ${enterprise.activeLicenses} |
| Subscriptions | ${enterprise.subscriptions} |
| Revenue | ${enterprise.revenueOverview} |
| New Registrations (today) | ${enterprise.newRegistrations} |
| DAU / WAU / MAU | ${usage.dailyActiveUsers} / ${usage.weeklyActiveUsers} / ${usage.monthlyActiveUsers} |
| Renewal Rate | ${bi.renewalRate}% |
| Retention | ${bi.customerRetention}% |
| CSAT | ${cs.avgSatisfaction} |
| Open Support | ${enterprise.supportTicketsOpen} |
`;

  const specs: { kind: ReportKind; file: string; title: string; body: string }[] = [
    {
      kind: "daily",
      file: `DAILY_BUSINESS_REPORT_${stamp}.md`,
      title: "Daily Business Report",
      body: `# Daily Business Report\n\n**Date:** ${stamp}\n\n${common}\n\n## Focus\n- Registrations, activations, failed payments, open tickets.\n`,
    },
    {
      kind: "weekly",
      file: `WEEKLY_EXECUTIVE_REPORT_${stamp}.md`,
      title: "Weekly Executive Report",
      body: `# Weekly Executive Report\n\n**Week ending:** ${stamp}\n\n${common}\n\n## Revenue trend (recent)\n${bi.revenueTrends
        .slice(-4)
        .map((r) => `- ${r.month}: ${r.formatted}`)
        .join("\n")}\n`,
    },
    {
      kind: "monthly",
      file: `MONTHLY_COMMERCIAL_REPORT_${stamp}.md`,
      title: "Monthly Commercial Report",
      body: `# Monthly Commercial Report\n\n**Month reference:** ${stamp.slice(0, 7)}\n\n${common}\n\n## Product adoption\n\`\`\`json\n${JSON.stringify(bi.productAdoption, null, 2)}\n\`\`\`\n`,
    },
    {
      kind: "quarterly",
      file: `QUARTERLY_BUSINESS_REVIEW_${stamp}.md`,
      title: "Quarterly Business Review",
      body: `# Quarterly Business Review\n\n**As of:** ${stamp}\n\n${common}\n\n## Executive narrative\nWebsite Professional Global Commercial Release is active. Core Trading Engine remains frozen and SHA-256 verified. Focus: growth quality, renewal health, support load, Market screenshot gate (C5).\n`,
    },
    {
      kind: "annual",
      file: `ANNUAL_EXECUTIVE_SUMMARY_${stamp.slice(0, 4)}.md`,
      title: "Annual Executive Summary",
      body: `# Annual Executive Summary\n\n**Year:** ${stamp.slice(0, 4)}\n\n${common}\n\n## Strategic posture\n- Commercial SaaS operations live for Website Professional.\n- Core permanently isolated.\n- LTS policy and Phase 11 roadmap govern commercial evolution.\n`,
    },
  ];

  const metas: ExecutiveReportMeta[] = [];
  for (const s of specs) {
    const p = path.join(dir, s.file);
    fs.writeFileSync(p, s.body, "utf8");
    const mirror: Record<ReportKind, string> = {
      daily: "DAILY_BUSINESS_REPORT.md",
      weekly: "WEEKLY_EXECUTIVE_REPORT.md",
      monthly: "MONTHLY_COMMERCIAL_REPORT.md",
      quarterly: "QUARTERLY_BUSINESS_REVIEW.md",
      annual: "ANNUAL_EXECUTIVE_SUMMARY.md",
    };
    fs.writeFileSync(path.join(docsRoot(), mirror[s.kind]), s.body, "utf8");
    metas.push({ kind: s.kind, title: s.title, path: p, generatedAt: new Date().toISOString() });
  }

  const payload = { reports: metas, at: new Date().toISOString() };
  savePhase11Run("reports", "Executive reports generated", payload);
  return payload;
}