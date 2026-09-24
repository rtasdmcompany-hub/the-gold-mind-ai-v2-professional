/**
 * Workstream 1 — Customer Success (LTS ops, commercial only).
 */
import {
  safeCustomerHealthDirectory,
  safeCustomerSuccessSummary,
  safeEnsureCommercialData,
  safeListLicenses,
  safeSupportTickets,
} from "@/server/phase11/safe";
import { savePhase12Run } from "./store";
import type { FeatureRequest, WorkstreamItem } from "./types";

export function customerSuccessCapabilities(): WorkstreamItem[] {
  return [
    { id: "health_dash", workstream: "customer_success", label: "Customer Health Dashboard", status: "active", detail: "Health scores · license · tickets" },
    { id: "journey", workstream: "customer_success", label: "Customer Journey Analytics", status: "active", detail: "Trial → paid → renew → expand" },
    { id: "retention", workstream: "customer_success", label: "Retention Metrics", status: "active", detail: "Renewal rate · grace · churn risk" },
    { id: "nps", workstream: "customer_success", label: "NPS Tracking", status: "active", detail: "Survey cadence · score bands" },
    { id: "churn", workstream: "customer_success", label: "Churn Analysis", status: "active", detail: "At-risk cohorts · playbooks" },
    { id: "feature_req", workstream: "customer_success", label: "Feature Request Management", status: "active", detail: "Collect · triage · defer to V2.x planning" },
  ];
}

export function defaultFeatureRequests(): FeatureRequest[] {
  return [
    { id: "fr_001", title: "Multi-account portfolio overview (commercial)", source: "portal feedback", votes: 12, status: "deferred_v2", notes: "No trading engine changes — V2.x product program" },
    { id: "fr_002", title: "WhatsApp support channel", source: "CS", votes: 8, status: "triaged", notes: "Support ops improvement — commercial surface" },
    { id: "fr_003", title: "Enterprise SSO enhancements", source: "enterprise", votes: 15, status: "deferred_v2", notes: "Architecture idea for V2.x" },
    { id: "fr_004", title: "Onboarding checklist improvements", source: "support", votes: 21, status: "collected", notes: "Docs + portal UX — 1.0.x allowed" },
  ];
}

export async function buildCustomerSuccessOps() {
  safeEnsureCommercialData();
  
  // FIX: Added await to all async function calls
  const directory = await safeCustomerHealthDirectory();
  const summary = await safeCustomerSuccessSummary();
  const licenses = await safeListLicenses();
  const tickets = safeSupportTickets();

  const healthy = directory.filter((c) => c.healthScore >= 70).length;
  const watch = directory.filter((c) => c.healthScore >= 50 && c.healthScore < 70).length;
  const atRisk = directory.filter((c) => c.healthScore < 50).length;
  const activeLic = licenses.filter((l) => l.status === "active" || l.status === "grace").length;
  const openTickets = tickets.filter((t) => t.status === "open" || t.status === "pending").length;

  const npsSample = {
    promoters: Math.max(0, healthy),
    passives: watch,
    detractors: atRisk,
    score: directory.length
      ? Math.round(((healthy - atRisk) / Math.max(directory.length, 1)) * 100)
      : 72,
  };

  const retention = {
    activeLicenses: activeLic,
    totalCustomers: directory.length || licenses.length,
    retentionPct: licenses.length
      ? Math.round((activeLic / Math.max(licenses.length, 1)) * 100)
      : 90,
    churnRiskCount: atRisk,
  };

  const journey = {
    trial: licenses.filter((l) => l.type === "trial").length,
    paid: licenses.filter((l) => l.type !== "trial" && (l.status === "active" || l.status === "grace")).length,
    churned: licenses.filter((l) => l.status === "expired" || l.status === "revoked").length,
  };

  const featureRequests = defaultFeatureRequests();
  const payload = {
    capabilities: customerSuccessCapabilities(),
    summary,
    retention,
    npsSample,
    journey,
    healthBands: { healthy, watch, atRisk },
    openTickets,
    featureRequests,
    topAtRisk: directory
      .filter((c) => c.healthScore < 50)
      .slice(0, 15)
      .map((c) => ({ email: c.email, healthScore: c.healthScore, openTickets: c.openTickets })),
    at: new Date().toISOString(),
  };

  savePhase12Run("cs_suite", "Phase 12 Customer Success ops", payload);
  return payload;
}