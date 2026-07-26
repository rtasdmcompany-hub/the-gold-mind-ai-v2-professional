/**
 * Phase 11 Sprint 9 — Global infrastructure & ops types.
 * Commercial cloud only — Core Trading Engine never modified or bypassed.
 */
export type InfraProvider =
  | "cloudflare"
  | "vercel"
  | "supabase"
  | "runpod"
  | "upstash_redis"
  | "object_storage"
  | "dns"
  | "ssl"
  | "cdn"
  | "regional_routing";

export type RegionCode = "us-east" | "eu-west" | "ap-south" | "me-central";

export type ScaleTier =
  | "users_10k"
  | "users_50k"
  | "users_100k"
  | "users_250k"
  | "users_1m_planning";

export type IncidentSeverity = "sev1" | "sev2" | "sev3" | "sev4";

export interface InfraComponent {
  id: InfraProvider;
  name: string;
  role: string;
  regions: RegionCode[];
  status: "healthy" | "degraded" | "down" | "planned";
  haEnabled: boolean;
  notes: string;
  optimization: string[];
}

export interface HaCheck {
  id: string;
  label: string;
  status: "pass" | "partial" | "fail";
  detail: string;
}

export interface ScalePlan {
  tier: ScaleTier;
  users: number;
  assumptions: string[];
  upgrades: string[];
  estimatedMonthlyUsd: { low: number; high: number };
}

export interface ObservabilityMetric {
  id: string;
  category: string;
  label: string;
  value: number;
  unit: string;
  slaTarget?: number;
  slaMet?: boolean;
}

export interface ContinuityControl {
  id: string;
  label: string;
  rtoMinutes: number;
  rpoMinutes: number;
  status: "ready" | "partial" | "gap";
  detail: string;
}

export interface CostLine {
  id: string;
  category: string;
  monthlyUsd: number;
  forecastNextQuarterUsd: number;
  optimization: string;
}

export interface OpsIncident {
  id: string;
  title: string;
  severity: IncidentSeverity;
  region?: RegionCode;
  status: "open" | "mitigating" | "resolved";
  openedAt: string;
  resolvedAt?: string;
}

export const INFRA_CORE_ISOLATION =
  "Infrastructure and ops changes never modify or bypass the certified Core Trading Engine. Trading remains exclusively in MT5 Professional.";
