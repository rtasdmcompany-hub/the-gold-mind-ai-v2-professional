/**
 * Phase 12 — Continuous Innovation, Customer Success & Product Evolution.
 * Operational excellence only. Core Trading Engine permanently frozen.
 */

export const PHASE12_CORE_ISOLATION =
  "Core Trading Engine permanently frozen. No trading / risk / recovery / money / entry / exit / execution / magic / calculation changes. V2.x requires separate engineering program.";

export const PHASE12_SCOPE =
  "LTS operations: customer success, support, BI, ops excellence, 1.0.x release hygiene, V2 planning (no implement).";

export type WorkstreamId =
  | "customer_success"
  | "support"
  | "business_intelligence"
  | "operational_excellence"
  | "release_management"
  | "v2_planning"
  | "monthly_reports";

export interface WorkstreamItem {
  id: string;
  workstream: WorkstreamId;
  label: string;
  status: "active" | "planned" | "complete";
  detail: string;
}

export interface FeatureRequest {
  id: string;
  title: string;
  source: string;
  votes: number;
  status: "collected" | "triaged" | "deferred_v2";
  notes: string;
}

export interface V2PlanningItem {
  id: string;
  category: "customer" | "business" | "competitive" | "technology" | "ai" | "architecture";
  title: string;
  detail: string;
  /** Never implement in Phase 12 */
  implementInPhase12: false;
}

export interface Phase12Scores {
  customerSuccessScore: number;
  supportScore: number;
  businessGrowthScore: number;
  operationalExcellenceScore: number;
  infrastructureHealth: number;
  overallPlatformHealth: number;
  phase12Progress: number;
}

export interface Phase12Condition {
  id: string;
  severity: "Critical" | "High" | "Medium" | "Low";
  title: string;
  owner: string;
  mitigation: string;
  targetCompletion: string;
}
