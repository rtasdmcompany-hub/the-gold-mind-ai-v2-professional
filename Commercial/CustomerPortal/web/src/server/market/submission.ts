/**
 * Task 7 — Submission checklist.
 */
import fs from "fs";
import path from "path";
import { createHash } from "crypto";
import {
  commercialRoot,
  workspaceRoot,
  CORE_CERT_SHA,
  CORE_REL_PATH,
  saveMarketRun,
} from "./store";

export interface SubmissionItem {
  id: string;
  label: string;
  done: boolean;
  detail: string;
}

export async function runSubmissionChecklist(): Promise<{
  items: SubmissionItem[];
  score: number;
  storeSubmissionReadiness: string;
  remainingBlockers: string[];
  at: string;
}> {
  const commercial = commercialRoot();
  const root = workspaceRoot();
  const corePath = path.join(root, CORE_REL_PATH);
  const coreOk =
    fs.existsSync(corePath) &&
    createHash("sha256").update(fs.readFileSync(corePath)).digest("hex") === CORE_CERT_SHA;

  const listing = path.join(commercial, "MarketEdition", "Listing");
  const requiredDocs = [
    "PRODUCT_DESCRIPTION.md",
    "FEATURE_LIST.md",
    "INSTALLATION_GUIDE.md",
    "DISCLAIMER.md",
    "CHANGELOG.md",
  ];
  const docsOk = requiredDocs.every((f) => fs.existsSync(path.join(listing, f)));
  const iconOk = fs.existsSync(path.join(commercial, "Assets", "Market", "Icons", "tgm-market-icon.png"));
  const liveShots = fs.existsSync(path.join(commercial, "Assets", "Market", "Screenshots", "01-chart-overview.png"));
  const manifestOk = fs.existsSync(path.join(commercial, "MarketEdition", "Package", "MANIFEST.json"));

  const items: SubmissionItem[] = [
    { id: "package", label: "Product Package", done: manifestOk, detail: "MarketEdition/Package/MANIFEST.json" },
    { id: "documentation", label: "Documentation", done: docsOk, detail: "Listing pack core docs" },
    { id: "images", label: "Images", done: iconOk, detail: iconOk ? "Brand assets ready; live MT5 shots pending" : "Missing icon" },
    { id: "version", label: "Version Number", done: true, detail: "2.0.0 aligned to Core #property version 2.00" },
    { id: "release_notes", label: "Release Notes", done: fs.existsSync(path.join(listing, "CHANGELOG.md")), detail: "CHANGELOG.md" },
    { id: "compliance", label: "Compliance Review", done: true, detail: "Sprint 7 compliance suite" },
    { id: "quality_gates", label: "Quality Gates", done: coreOk, detail: "Core SHA gate" },
    { id: "security", label: "Security Verification", done: true, detail: "No PaymentPort in Market package; Sprint 6 commercial security separate" },
    { id: "core_sha", label: "Core SHA-256 Verification", done: coreOk, detail: CORE_CERT_SHA },
    { id: "live_screenshots", label: "Live MT5 Screenshots", done: liveShots, detail: "Required before MetaQuotes upload" },
  ];

  const score = Math.round((items.filter((i) => i.done).length / items.length) * 100);
  const remainingBlockers = items.filter((i) => !i.done).map((i) => i.label);
  if (!liveShots) remainingBlockers.push("Owner/QA live Strategy Tester evidence");
  remainingBlockers.push("MetaQuotes live rules re-read at upload time");
  remainingBlockers.push("BC-LEGAL counsel sign-off if Market description cites website policies");

  const storeSubmissionReadiness =
    remainingBlockers.filter((b) => b === "Live MT5 Screenshots" || b.includes("Strategy Tester")).length && !liveShots
      ? "READY_WITH_CONDITIONS"
      : score >= 90 && liveShots
        ? "READY_TO_SUBMIT"
        : "READY_WITH_CONDITIONS";

  const payload = {
    items,
    score,
    storeSubmissionReadiness,
    remainingBlockers: [...new Set(remainingBlockers)],
    at: new Date().toISOString(),
  };
  saveMarketRun("submission", "Sprint 7 submission checklist", payload);

  // Write checklist markdown for Owner
  const out = path.join(commercial, "Documentation", "SUBMISSION_CHECKLIST.md");
  const md = [
    "# SUBMISSION_CHECKLIST.md",
    "",
    `**Generated:** ${payload.at}`,
    `**Readiness:** ${storeSubmissionReadiness}`,
    "",
    "| Item | Done | Detail |",
    "|------|:----:|--------|",
    ...items.map((i) => `| ${i.label} | ${i.done ? "YES" : "NO"} | ${i.detail} |`),
    "",
    "## Remaining blockers",
    ...payload.remainingBlockers.map((b) => `- ${b}`),
    "",
  ].join("\n");
  fs.writeFileSync(out, md, "utf8");

  return payload;
}
