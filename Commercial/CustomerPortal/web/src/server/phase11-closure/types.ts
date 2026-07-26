/**
 * Phase 11 Sprint 10 — Global enterprise certification types.
 */
export type Phase11DecisionCode =
  | "NOT CERTIFIED"
  | "CERTIFIED WITH CONDITIONS"
  | "FULLY CERTIFIED FOR GLOBAL ENTERPRISE OPERATIONS";

export type ConditionSeverity = "Critical" | "High" | "Medium" | "Low";

export type CertStatus = "pass" | "partial" | "fail";

export interface CertItem {
  id: string;
  domain: "enterprise" | "commercial" | "technical" | "lts" | "gate";
  label: string;
  status: CertStatus;
  detail: string;
}

export interface ResidualCondition {
  id: string;
  severity: ConditionSeverity;
  title: string;
  owner: string;
  mitigation: string;
  targetCompletion: string;
}

export interface ExecutiveScores {
  engineering: number;
  commercialPlatform: number;
  operations: number;
  security: number;
  customerExperience: number;
  infrastructure: number;
  scalability: number;
  maintainability: number;
  enterpriseReadiness: number;
  businessGrowthReadiness: number;
  globalExpansionReadiness: number;
  overallProductQuality: number;
}

export interface OutputScores {
  engineeringScore: number;
  commercialScore: number;
  operationsScore: number;
  securityScore: number;
  infrastructureScore: number;
  enterpriseScore: number;
  customerSuccessScore: number;
  globalReadinessScore: number;
  overallProductScore: number;
  phase11Progress: number;
}

export interface ProjectStatistics {
  architectureModules: number;
  documentationFiles: number;
  apis: number;
  dashboards: number;
  customerServices: number;
  integrations: number;
  qualityGatesPassed: number;
  securityReviews: number;
  commercialReviews: number;
  executiveReviews: number;
  overallProjectCompletionPct: number;
}

export const PHASE11_CORE_ISOLATION =
  "Core Trading Engine remains permanently certified, frozen, and isolated from all commercial Phase 11 surfaces.";
