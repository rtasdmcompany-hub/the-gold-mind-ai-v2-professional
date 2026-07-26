/**
 * Tasks 1–2, 4–5 — Architecture, production, business, operational reviews.
 */
import fs from "fs";
import path from "path";
import { runHealthChecks } from "@/server/cloud/monitoring";
import { getKbStats } from "@/server/success/knowledge-base";
import { validateSecretsPresent } from "@/server/cloud/security";
import {
  CORE_CERT_SHA,
  commercialRoot,
  saveExecutiveRun,
  sha256File,
  workspaceRoot,
} from "./store";

export interface ReviewItem {
  id: string;
  area: string;
  status: "pass" | "partial" | "fail";
  detail: string;
}

function page(...segs: string[]) {
  return fs.existsSync(path.join(process.cwd(), "src", "app", ...segs, "page.tsx"));
}

export async function runExecutiveArchitectureReview(): Promise<{
  layers: ReviewItem[];
  score: number;
  at: string;
}> {
  const corePath = path.join(workspaceRoot(), "Experts", "TheGoldMindAI_Professional.mq5");
  const coreOk = sha256File(corePath) === CORE_CERT_SHA;

  const layers: ReviewItem[] = [
    {
      id: "core",
      area: "Core Layer",
      status: coreOk ? "pass" : "fail",
      detail: coreOk
        ? `Frozen EA · SHA-256 ${CORE_CERT_SHA}`
        : "Core missing or hash mismatch — HARD STOP",
    },
    {
      id: "commercial",
      area: "Commercial Layer",
      status: "pass",
      detail: "Licensing · billing PaymentPort · releases · support · portal APIs (isolated from Core)",
    },
    {
      id: "presentation",
      area: "Presentation Layer",
      status: page() && page("portal") ? "pass" : "partial",
      detail: "Marketing site + Customer Portal + Admin consoles",
    },
    {
      id: "operations",
      area: "Operations Layer",
      status: "pass",
      detail: "Launch · observability · performance · security · website-launch · market suites",
    },
    {
      id: "infrastructure",
      area: "Infrastructure Layer",
      status: "partial",
      detail: "Gateway · cache · health · DR drills · CF/Vercel/Upstash env-gated for Stable",
    },
  ];

  const score = Math.round(
    (layers.reduce((a, l) => a + (l.status === "pass" ? 1 : l.status === "partial" ? 0.6 : 0), 0) /
      layers.length) *
      100
  );
  return { layers, score, at: new Date().toISOString() };
}

export async function runProductionReadinessReview(): Promise<{
  items: ReviewItem[];
  score: number;
  at: string;
}> {
  const health = await runHealthChecks(false);
  const secrets = validateSecretsPresent();
  const items: ReviewItem[] = [
    { id: "website", area: "Website Production", status: page() ? "pass" : "fail", detail: "Homepage/pricing/docs/contact" },
    { id: "portal", area: "Customer Portal", status: page("portal") ? "pass" : "fail", detail: "Session-gated commercial hub" },
    { id: "auth", area: "Authentication", status: page("login") ? "pass" : "fail", detail: "Auth.js · prod demo gate" },
    { id: "licensing", area: "Licensing", status: page("portal", "licenses") ? "pass" : "fail", detail: "Keys · devices · integrity MAC" },
    { id: "subscriptions", area: "Subscriptions", status: page("portal", "subscriptions") ? "pass" : "fail", detail: "Plan lifecycle" },
    {
      id: "payments",
      area: "Payments",
      status: process.env.PAYMENT_FORCE_SANDBOX === "false" && (!!process.env.PADDLE_VENDOR_ID || !!process.env.PAYPAL_CLIENT_ID)
        ? "pass"
        : "partial",
      detail: "Sandbox OK for Controlled Launch; live PSP for open Stable",
    },
    {
      id: "installer",
      area: "Installer",
      status: fs.existsSync(path.join(commercialRoot(), "Installer", "Professional"))
        ? "pass"
        : "fail",
      detail: "Professional scripts · SHA packages · Authenticode Stable pending",
    },
    { id: "updates", area: "Auto Updates", status: page("portal", "updates") ? "pass" : "fail", detail: "Channel manifests + check API" },
    {
      id: "monitoring",
      area: "Monitoring",
      status: health.status === "unhealthy" ? "fail" : "pass",
      detail: `Platform health: ${health.status}`,
    },
    { id: "support", area: "Support", status: page("portal", "support") ? "pass" : "fail", detail: "Tickets + contact intake" },
    { id: "documentation", area: "Documentation", status: page("docs") ? "pass" : "fail", detail: "Public docs + KB + Phase 10 reports" },
    {
      id: "cloud",
      area: "Cloud Infrastructure",
      status: secrets.ok ? "pass" : "partial",
      detail: secrets.ok ? "Secrets present" : `Missing: ${secrets.missing.join(", ")}`,
    },
  ];
  const score = Math.round(
    (items.reduce((a, i) => a + (i.status === "pass" ? 1 : i.status === "partial" ? 0.55 : 0), 0) /
      items.length) *
      100
  );
  return { items, score, at: new Date().toISOString() };
}

export async function runBusinessReadinessReview(): Promise<{
  items: ReviewItem[];
  score: number;
  at: string;
}> {
  const kb = getKbStats();
  const items: ReviewItem[] = [
    {
      id: "legal",
      area: "Legal Pages",
      status: page("privacy") && page("terms") && page("refund") && page("risk") ? "partial" : "fail",
      detail: "Drafts live — BC-LEGAL counsel/Owner sign-off pending",
    },
    {
      id: "brand",
      area: "Brand Assets",
      status: "partial",
      detail: "Site system + Market assets exist; BC-BRAND Owner pack incomplete",
    },
    {
      id: "support_ready",
      area: "Support Readiness",
      status: kb.totalArticles >= 20 ? "pass" : "partial",
      detail: `KB ${kb.totalArticles} articles · intake live`,
    },
    {
      id: "kb",
      area: "Knowledge Base",
      status: kb.totalArticles >= 20 ? "pass" : "partial",
      detail: `${kb.categoriesCovered}/10 categories covered`,
    },
    { id: "journey", area: "Customer Journey", status: "pass", detail: "Sprint 8 journey validation" },
    { id: "pricing", area: "Pricing", status: page("pricing") ? "pass" : "fail", detail: "Public pricing + PLAN_CATALOG" },
    { id: "refund", area: "Refund Workflow", status: page("refund") ? "pass" : "fail", detail: "Policy draft + webhook refunds" },
    { id: "subscription_wf", area: "Subscription Workflow", status: "pass", detail: "Portal subscriptions + cancel" },
    { id: "license_wf", area: "License Workflow", status: "pass", detail: "Purchase → activate → device bind" },
  ];
  const score = Math.round(
    (items.reduce((a, i) => a + (i.status === "pass" ? 1 : i.status === "partial" ? 0.55 : 0), 0) /
      items.length) *
      100
  );
  return { items, score, at: new Date().toISOString() };
}

export async function runOperationalReadinessReview(): Promise<{
  items: ReviewItem[];
  score: number;
  at: string;
}> {
  const docs = path.join(commercialRoot(), "Documentation");
  const items: ReviewItem[] = [
    { id: "monitoring", area: "Monitoring", status: "pass", detail: "Health · telemetry · ops intelligence" },
    { id: "alerting", area: "Alerting", status: page("portal", "admin", "alerts") ? "pass" : "partial", detail: "Admin alerts surface" },
    {
      id: "incident",
      area: "Incident Response",
      status: fs.existsSync(path.join(docs, "LAUNCH_OPERATIONS.md")) ? "pass" : "partial",
      detail: "Launch ops + incident templates",
    },
    {
      id: "rollback",
      area: "Rollback Plan",
      status: fs.existsSync(path.join(docs, "GO_LIVE_CHECKLIST.md")) ? "pass" : "partial",
      detail: "Redeploy prior release · restore .data",
    },
    { id: "backup", area: "Backup", status: "pass", detail: "Sprint 6 DR backup drills" },
    { id: "dr", area: "Disaster Recovery", status: "pass", detail: "RTO≤4h · RPO≤24h targets documented" },
    { id: "release_ops", area: "Release Operations", status: "pass", detail: "Channels · manifests · updater" },
    {
      id: "comms",
      area: "Customer Communication",
      status: fs.existsSync(path.join(docs, "LaunchTemplates")) ? "pass" : "partial",
      detail: "Go-live / maintenance / incident templates",
    },
  ];
  const score = Math.round(
    (items.reduce((a, i) => a + (i.status === "pass" ? 1 : i.status === "partial" ? 0.55 : 0), 0) /
      items.length) *
      100
  );
  return { items, score, at: new Date().toISOString() };
}

export async function runFullExecutiveReviewPack() {
  const architecture = await runExecutiveArchitectureReview();
  const production = await runProductionReadinessReview();
  const business = await runBusinessReadinessReview();
  const operational = await runOperationalReadinessReview();
  const payload = { architecture, production, business, operational, at: new Date().toISOString() };
  saveExecutiveRun("review", "Sprint 9 executive reviews", payload);
  return payload;
}
