/**
 * Workstream 5 — Release Management (1.0.x LTS only).
 */
import { savePhase12Run } from "./store";
import type { WorkstreamItem } from "./types";

export const RELEASE_1_0_X_ALLOWED = [
  "Bug Fixes",
  "Security Updates",
  "Performance Optimizations",
  "Compatibility Updates",
  "Documentation Improvements",
] as const;

export const RELEASE_1_0_X_FORBIDDEN = [
  "Feature additions",
  "Trading engine changes",
  "Risk / recovery / money management changes",
  "Magic number / calculation changes",
  "Any Core Trading Engine modification",
] as const;

export function releaseCapabilities(): WorkstreamItem[] {
  return RELEASE_1_0_X_ALLOWED.map((label, i) => ({
    id: `rel_${i}`,
    workstream: "release_management" as const,
    label,
    status: "active" as const,
    detail: "Allowed on Version 1.0.x LTS train",
  }));
}

export async function buildReleaseManagement(portalVersion: string) {
  const payload = {
    line: "1.0.x",
    currentPortalVersion: portalVersion,
    policy: "Long-Term Support — patch train only",
    allowed: [...RELEASE_1_0_X_ALLOWED],
    forbidden: [...RELEASE_1_0_X_FORBIDDEN],
    capabilities: releaseCapabilities(),
    cadence: {
      securityPatches: "as needed (critical ≤ 72h)",
      maintenanceWindows: "Sun 02:00–04:00 UTC (optional)",
      minorDocs: "continuous",
    },
    coreRule: "SHA-256 must match certified value on every release",
    at: new Date().toISOString(),
  };

  savePhase12Run("release_suite", "Phase 12 Release Management 1.0.x", payload);
  return payload;
}
