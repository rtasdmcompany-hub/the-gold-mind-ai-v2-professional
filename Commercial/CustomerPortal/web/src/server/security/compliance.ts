/**
 * Task 7 — Compliance review (commercial / legal / Market alignment).
 */
import fs from "fs";
import path from "path";
import { saveSecurityRun, type SecurityFinding } from "./store";

export interface ComplianceItem {
  id: string;
  label: string;
  status: "ready" | "draft" | "missing" | "n/a";
  detail: string;
}

function pageExists(...segments: string[]): boolean {
  const base = path.join(process.cwd(), "src", "app", ...segments);
  return fs.existsSync(path.join(base, "page.tsx")) || fs.existsSync(`${base}.tsx`);
}

export async function runComplianceReview(): Promise<{
  items: ComplianceItem[];
  findings: SecurityFinding[];
  score: number;
  at: string;
}> {
  const items: ComplianceItem[] = [
    {
      id: "privacy",
      label: "Privacy Policy implementation",
      status: pageExists("privacy") ? "draft" : "missing",
      detail: pageExists("privacy")
        ? "Public /privacy draft page present — counsel sign-off pending (BC-LEGAL)"
        : "No /privacy route",
    },
    {
      id: "terms",
      label: "Terms of Service availability",
      status: pageExists("terms") ? "draft" : "missing",
      detail: pageExists("terms")
        ? "Public /terms draft page present — counsel sign-off pending"
        : "No /terms route",
    },
    {
      id: "cookies",
      label: "Cookie consent (if applicable)",
      status: pageExists("cookies") ? "draft" : "missing",
      detail: "Policy page draft; banner/consent UX deferred until analytics cookies used",
    },
    {
      id: "license_compliance",
      label: "License compliance",
      status: "ready",
      detail: "Commercial license keys · device binding · audit trail · EULA text still counsel-owned",
    },
    {
      id: "mql5",
      label: "MQL5 policy alignment (Market edition)",
      status: "n/a",
      detail: "Portal is external commercial path; Market edition uses separate activation — BC-MQL5 still NOT STARTED",
    },
    {
      id: "website_policy",
      label: "Website commercial policy alignment",
      status: pageExists("risk") && pageExists("refund") ? "draft" : "missing",
      detail: "Risk + Refund draft pages; marketing claims checklist IN PROGRESS",
    },
  ];

  const findings: SecurityFinding[] = items.map((it) => ({
    id: `comp-${it.id}`,
    area: "Compliance",
    severity: it.status === "missing" ? "High" : it.status === "draft" ? "Medium" : "Info",
    title: it.label,
    detail: it.detail,
    status: it.status === "ready" || it.status === "n/a" ? "pass" : it.status === "draft" ? "accepted" : "open",
    mitigation: "Owner/counsel complete BC-LEGAL before open Stable",
  }));

  const weights = { ready: 1, draft: 0.55, "n/a": 1, missing: 0 } as const;
  const score = Math.round(
    (items.reduce((a, i) => a + weights[i.status], 0) / items.length) * 100
  );

  const payload = { items, findings, score, at: new Date().toISOString() };
  saveSecurityRun("compliance", "Sprint 6 compliance review", payload);
  return payload;
}
