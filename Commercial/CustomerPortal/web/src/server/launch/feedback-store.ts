/**
 * Structured beta feedback — scores + bugs vs features separated.
 */
import fs from "fs";
import path from "path";
import { writeAudit } from "@/server/cloud/audit";
import { isProductionRuntime } from "@/server/security/dev-bypass";
import { decryptJson, encryptJson, launchDataDir, newId } from "./store-crypto";

export type FeedbackCategory =
  | "bug"
  | "feature"
  | "ui"
  | "performance"
  | "installation"
  | "support"
  | "documentation"
  | "license"
  | "satisfaction"
  | "structured";

export type FeedbackStatus = "new" | "triaged" | "in_progress" | "resolved" | "wont_fix";
export type FeedbackPriority = "P0" | "P1" | "P2" | "P3";

export interface StructuredScores {
  installation?: number;
  uiux?: number;
  performance?: number;
  documentation?: number;
  supportQuality?: number;
  licenseExperience?: number;
  overallSatisfaction?: number;
}

export interface FeedbackItem {
  id: string;
  customerEmail: string;
  category: FeedbackCategory;
  title: string;
  detail: string;
  satisfactionScore?: number;
  scores?: StructuredScores;
  status: FeedbackStatus;
  priority?: FeedbackPriority;
  owner?: string;
  verification?: string;
  releaseTarget?: string;
  createdAt: string;
  updatedAt: string;
  adminNote?: string;
}

interface FeedbackStore {
  version: 1;
  items: FeedbackItem[];
}

const EMPTY: FeedbackStore = { version: 1, items: [] };
let cache: FeedbackStore | null = null;

function storePath(): string {
  return path.join(launchDataDir("feedback"), "feedback.enc");
}

function read(): FeedbackStore {
  if (cache) return cache;
  const p = storePath();
  if (!fs.existsSync(p)) {
    cache = structuredClone(EMPTY);
    return cache;
  }
  cache = decryptJson<FeedbackStore>(fs.readFileSync(p, "utf8"));
  if (!Array.isArray(cache.items)) cache.items = [];
  return cache;
}

function write(data: FeedbackStore): void {
  cache = data;
  fs.writeFileSync(storePath(), encryptJson(data), "utf8");
}

function clampScore(n?: number): number | undefined {
  if (typeof n !== "number" || Number.isNaN(n)) return undefined;
  return Math.max(1, Math.min(5, Math.round(n)));
}

export const FEEDBACK_CATEGORY_LABELS: Record<FeedbackCategory, string> = {
  bug: "Bug Report",
  feature: "Feature Request",
  ui: "UI Feedback",
  performance: "Performance",
  installation: "Installation Experience",
  support: "Support Experience",
  documentation: "Documentation",
  license: "License Experience",
  satisfaction: "Overall Satisfaction",
  structured: "Structured Beta Survey",
};

export function listFeedback(filter?: { category?: FeedbackCategory; status?: FeedbackStatus; q?: string }) {
  let rows = [...read().items];
  if (filter?.category) rows = rows.filter((f) => f.category === filter.category);
  if (filter?.status) rows = rows.filter((f) => f.status === filter.status);
  if (filter?.q) {
    const q = filter.q.toLowerCase();
    rows = rows.filter(
      (f) => f.customerEmail.includes(q) || f.title.toLowerCase().includes(q) || f.detail.toLowerCase().includes(q)
    );
  }
  return rows.sort((a, b) => b.createdAt.localeCompare(a.createdAt));
}

function avgOf(nums: number[]): number | null {
  if (!nums.length) return null;
  return Math.round((nums.reduce((a, b) => a + b, 0) / nums.length) * 10) / 10;
}

export function getFeedbackSummary() {
  const items = read().items;
  const scores = items
    .map((i) => i.satisfactionScore ?? i.scores?.overallSatisfaction)
    .filter((n): n is number => typeof n === "number" && n >= 1 && n <= 5);
  const avg = avgOf(scores);

  const scoreBuckets: Record<keyof StructuredScores, number[]> = {
    installation: [],
    uiux: [],
    performance: [],
    documentation: [],
    supportQuality: [],
    licenseExperience: [],
    overallSatisfaction: [],
  };
  for (const i of items) {
    if (!i.scores) continue;
    for (const k of Object.keys(scoreBuckets) as (keyof StructuredScores)[]) {
      const v = i.scores[k];
      if (typeof v === "number") scoreBuckets[k].push(v);
    }
  }

  const byCategory = {} as Record<FeedbackCategory, number>;
  for (const c of Object.keys(FEEDBACK_CATEGORY_LABELS) as FeedbackCategory[]) byCategory[c] = 0;
  for (const i of items) byCategory[i.category] = (byCategory[i.category] || 0) + 1;

  return {
    total: items.length,
    newCount: items.filter((i) => i.status === "new").length,
    avgSatisfaction: avg,
    scoreCount: scores.length,
    byCategory,
    bugCount: items.filter((i) => i.category === "bug").length,
    featureCount: items.filter((i) => i.category === "feature").length,
    dimensionAverages: {
      installation: avgOf(scoreBuckets.installation),
      uiux: avgOf(scoreBuckets.uiux),
      performance: avgOf(scoreBuckets.performance),
      documentation: avgOf(scoreBuckets.documentation),
      supportQuality: avgOf(scoreBuckets.supportQuality),
      licenseExperience: avgOf(scoreBuckets.licenseExperience),
      overallSatisfaction: avgOf(scoreBuckets.overallSatisfaction),
    },
  };
}

export function submitFeedback(input: {
  customerEmail: string;
  category: FeedbackCategory;
  title: string;
  detail: string;
  satisfactionScore?: number;
  scores?: StructuredScores;
  priority?: FeedbackPriority;
}): FeedbackItem {
  const store = read();
  const now = new Date().toISOString();
  const scores = input.scores
    ? {
        installation: clampScore(input.scores.installation),
        uiux: clampScore(input.scores.uiux),
        performance: clampScore(input.scores.performance),
        documentation: clampScore(input.scores.documentation),
        supportQuality: clampScore(input.scores.supportQuality),
        licenseExperience: clampScore(input.scores.licenseExperience),
        overallSatisfaction: clampScore(input.scores.overallSatisfaction),
      }
    : undefined;
  const score =
    clampScore(input.satisfactionScore) ||
    scores?.overallSatisfaction ||
    undefined;

  const defaultPriority: FeedbackPriority =
    input.priority ||
    (input.category === "bug" ? "P1" : input.category === "feature" ? "P3" : "P2");

  const row: FeedbackItem = {
    id: newId("fb"),
    customerEmail: input.customerEmail.trim().toLowerCase(),
    category: input.category,
    title: input.title.trim(),
    detail: input.detail.trim(),
    satisfactionScore: score,
    scores,
    status: "new",
    priority: defaultPriority,
    createdAt: now,
    updatedAt: now,
  };
  store.items.unshift(row);
  write(store);
  writeAudit({
    user: row.customerEmail,
    action: "feedback_submit",
    ip: "portal",
    result: "success",
    detail: `${row.category} · ${row.id}`,
  });
  return row;
}

export function updateFeedback(
  id: string,
  patch: Partial<
    Pick<FeedbackItem, "status" | "adminNote" | "priority" | "owner" | "verification" | "releaseTarget">
  >,
  actor: string
): FeedbackItem | null {
  const store = read();
  const row = store.items.find((i) => i.id === id);
  if (!row) return null;
  if (patch.status) row.status = patch.status;
  if (patch.adminNote !== undefined) row.adminNote = patch.adminNote;
  if (patch.priority) row.priority = patch.priority;
  if (patch.owner !== undefined) row.owner = patch.owner;
  if (patch.verification !== undefined) row.verification = patch.verification;
  if (patch.releaseTarget !== undefined) row.releaseTarget = patch.releaseTarget;
  row.updatedAt = new Date().toISOString();
  write(store);
  writeAudit({
    user: actor,
    action: "feedback_triage",
    ip: "admin",
    result: "success",
    detail: `${id} · ${row.status} · ${row.priority || "P?"}`,
  });
  return row;
}

export function ensureDemoFeedback(): void {
  if (isProductionRuntime() && process.env.PORTAL_ALLOW_DEMO_SEED !== "true") return;
  const store = read();
  if (store.items.some((i) => i.category === "structured")) return;
  submitFeedback({
    customerEmail: "pro.trader@goldmind.local",
    category: "structured",
    title: "Sprint 2 structured survey",
    detail: "Overall beta experience positive; installer clear; docs adequate.",
    scores: {
      installation: 4,
      uiux: 4,
      performance: 5,
      documentation: 4,
      supportQuality: 5,
      licenseExperience: 5,
      overallSatisfaction: 4,
    },
  });
  submitFeedback({
    customerEmail: "creator@example.com",
    category: "bug",
    title: "Download page slow on first load",
    detail: "Took ~8s on first portal downloads view.",
  });
  submitFeedback({
    customerEmail: "creator@example.com",
    category: "feature",
    title: "Dark mode",
    detail: "Would like dark mode — logged as feature, not sprint work.",
  });
}
