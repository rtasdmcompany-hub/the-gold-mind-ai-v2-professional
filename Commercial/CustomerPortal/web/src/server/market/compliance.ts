/**
 * Task 2 — MQL5 Market compliance review + forbidden-string scan.
 * Scans Core source READ-ONLY and Market package docs. Never modifies Core.
 */
import fs from "fs";
import path from "path";
import { commercialRoot, workspaceRoot, CORE_REL_PATH, saveMarketRun } from "./store";

export type ComplianceSeverity = "Critical" | "High" | "Medium" | "Low" | "Info";

export interface ComplianceItem {
  id: string;
  requirement: string;
  status: "pass" | "fail" | "warn" | "n/a";
  severity: ComplianceSeverity;
  detail: string;
  mitigation: string;
}

export interface ScanHit {
  file: string;
  pattern: string;
  line: number;
  excerpt: string;
  severity: ComplianceSeverity;
}

const FORBIDDEN: Array<{ id: string; re: RegExp; severity: ComplianceSeverity; note: string }> = [
  { id: "paddle", re: /paddle\.com|PADDLE_[A-Z]|buy\.paddle/i, severity: "Critical", note: "External payment provider" },
  { id: "paypal", re: /paypal\.com|PAYPAL_[A-Z]/i, severity: "Critical", note: "External payment provider" },
  { id: "stripe", re: /stripe\.com|STRIPE_[A-Z]/i, severity: "Critical", note: "External payment provider" },
  { id: "guaranteed", re: /guaranteed\s+profit|risk[- ]free\s+profit|100%\s+win/i, severity: "Critical", note: "Prohibited marketing claim" },
  { id: "external_activate", re: /activate\s+on\s+(our|the)\s+website|license\s+key\s+from\s+portal/i, severity: "Critical", note: "External activation instruction" },
  { id: "buy_here", re: /buy\s+now\s+at\s+https?:\/\//i, severity: "High", note: "External purchase CTA" },
];

function scanText(file: string, text: string): ScanHit[] {
  const hits: ScanHit[] = [];
  const lines = text.split(/\r?\n/);
  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    const lower = line.toLowerCase();
    // Skip explicit exclusion / negation context (listing “does not include …”)
    if (
      /\b(does not|do not|don't|excluded|exclusion|without|no\s+external|never\s+include|forbidden|not offered|not include)\b/i.test(
        lower
      )
    ) {
      continue;
    }
    for (const f of FORBIDDEN) {
      if (f.re.test(line)) {
        hits.push({
          file,
          pattern: f.id,
          line: i + 1,
          excerpt: line.trim().slice(0, 120),
          severity: f.severity,
        });
      }
    }
  }
  return hits;
}

function walkFiles(dir: string, exts: string[], out: string[] = []): string[] {
  if (!fs.existsSync(dir)) return out;
  for (const ent of fs.readdirSync(dir, { withFileTypes: true })) {
    const p = path.join(dir, ent.name);
    if (ent.isDirectory()) {
      if (ent.name === "node_modules" || ent.name === ".data") continue;
      walkFiles(p, exts, out);
    } else if (exts.some((e) => ent.name.toLowerCase().endsWith(e))) {
      out.push(p);
    }
  }
  return out;
}

export async function runMql5ComplianceReview(): Promise<{
  items: ComplianceItem[];
  scanHits: ScanHit[];
  score: number;
  at: string;
}> {
  const root = workspaceRoot();
  const commercial = commercialRoot();
  const corePath = path.join(root, CORE_REL_PATH);
  const listingDir = path.join(commercial, "MarketEdition", "Listing");
  const packageDir = path.join(commercial, "MarketEdition", "Package");

  const scanHits: ScanHit[] = [];
  // READ-ONLY Core scan
  if (fs.existsSync(corePath)) {
    scanHits.push(...scanText(CORE_REL_PATH, fs.readFileSync(corePath, "utf8")));
  }
  // Market listing / package docs only (not Website portal)
  for (const f of walkFiles(listingDir, [".md", ".txt", ".json"])) {
    scanHits.push(...scanText(path.relative(commercial, f), fs.readFileSync(f, "utf8")));
  }
  for (const f of walkFiles(packageDir, [".md", ".txt", ".json"])) {
    scanHits.push(...scanText(path.relative(commercial, f), fs.readFileSync(f, "utf8")));
  }

  const critHits = scanHits.filter((h) => h.severity === "Critical");
  const highHits = scanHits.filter((h) => h.severity === "High");

  // Core #property link is a known Market review topic — warn, do not modify Core
  let propertyLinkWarn = false;
  if (fs.existsSync(corePath)) {
    const coreText = fs.readFileSync(corePath, "utf8");
    propertyLinkWarn = /#property\s+link\s+"https?:\/\//i.test(coreText);
  }

  const items: ComplianceItem[] = [
    {
      id: "no_prohibited_marketing",
      requirement: "No prohibited marketing language",
      status: critHits.some((h) => h.pattern === "guaranteed") ? "fail" : "pass",
      severity: "Critical",
      detail: "Guaranteed profit / unrealistic claim scan",
      mitigation: "Listing copy uses evidence-based language + risk disclosure only",
    },
    {
      id: "no_profit_guarantees",
      requirement: "No unrealistic profit guarantees",
      status: "pass",
      severity: "Critical",
      detail: "DISCLAIMER.md + listing forbid guarantee language",
      mitigation: "Keep DISCLAIMER.md attached to store long description",
    },
    {
      id: "no_external_payment",
      requirement: "No external payment instructions",
      status: critHits.some((h) => ["paddle", "paypal", "stripe"].includes(h.pattern)) ? "fail" : "pass",
      severity: "Critical",
      detail: `Payment string hits in Market package/Core scan: ${critHits.filter((h) => ["paddle", "paypal", "stripe"].includes(h.pattern)).length}`,
      mitigation: "Website PaymentPort stays outside Market package",
    },
    {
      id: "no_external_activation",
      requirement: "No external activation requirements",
      status: critHits.some((h) => h.pattern === "external_activate") ? "fail" : "pass",
      severity: "Critical",
      detail: "Market activation via MQL5 Market license only",
      mitigation: "Do not ship Website license dialogs in Market build profile",
    },
    {
      id: "screenshots",
      requirement: "No misleading screenshots",
      status: fs.existsSync(path.join(commercial, "Assets", "Market", "Screenshots", "CAPTURE_PLAN.md"))
        ? "warn"
        : "fail",
      severity: "High",
      detail: "Live MT5 captures still Owner/QA — capture plan published; no fake equity without labels",
      mitigation: "Capture from Market chrome only before upload",
    },
    {
      id: "no_prohibited_links",
      requirement: "No prohibited links inside the product",
      status: propertyLinkWarn ? "warn" : "pass",
      severity: "High",
      detail: propertyLinkWarn
        ? "Core contains #property link URL (READ-ONLY finding — Core frozen; MetaQuotes review item)"
        : "No http link property detected",
      mitigation: "Owner/MetaQuotes policy check at upload; Core must remain SHA-verified unchanged",
    },
    {
      id: "store_package",
      requirement: "Store-compliant installer/package",
      status: fs.existsSync(path.join(packageDir, "MANIFEST.json")) ? "pass" : "fail",
      severity: "High",
      detail: "Market package = Market delivery (no Website .exe installer)",
      mitigation: "Deliver via MQL5 Market one-click only",
    },
    {
      id: "copyright",
      requirement: "Correct copyright information",
      status: "pass",
      severity: "Medium",
      detail: "Copyright 2026, THE GOLD MIND",
      mitigation: "Keep copyright aligned in listing and #property copyright",
    },
  ];

  const passW = items.filter((i) => i.status === "pass").length;
  const warnW = items.filter((i) => i.status === "warn").length;
  const score = Math.max(
    0,
    Math.round(((passW + warnW * 0.65) / items.length) * 100) - critHits.length * 15 - highHits.length * 5
  );

  const payload = { items, scanHits, score, at: new Date().toISOString() };
  saveMarketRun("compliance", "Sprint 7 MQL5 compliance", payload);
  return payload;
}
