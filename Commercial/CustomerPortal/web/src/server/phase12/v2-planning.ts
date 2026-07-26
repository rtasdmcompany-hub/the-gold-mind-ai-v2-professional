/**
 * Workstream 6 — Version 2.0 Planning ONLY. Do not implement.
 */
import { savePhase12Run } from "./store";
import type { V2PlanningItem, WorkstreamItem } from "./types";

export function v2PlanningCapabilities(): WorkstreamItem[] {
  return [
    { id: "collect_req", workstream: "v2_planning", label: "Customer Requests", status: "active", detail: "Collect only — no build" },
    { id: "biz_req", workstream: "v2_planning", label: "Business Requirements", status: "active", detail: "Commercial + enterprise inputs" },
    { id: "competitive", workstream: "v2_planning", label: "Competitive Analysis", status: "planned", detail: "Market scan backlog" },
    { id: "tech_opp", workstream: "v2_planning", label: "Technology Opportunities", status: "planned", detail: "Infra / platform ideas" },
    { id: "ai_roadmap", workstream: "v2_planning", label: "AI Roadmap", status: "planned", detail: "Assistant / analytics evolution" },
    { id: "arch", workstream: "v2_planning", label: "Architecture Ideas", status: "planned", detail: "Requires V2.x engineering program" },
  ];
}

export function collectV2PlanningBacklog(): V2PlanningItem[] {
  return [
    {
      id: "v2_001",
      category: "customer",
      title: "Unified multi-product commercial console",
      detail: "Single pane for licenses across future products",
      implementInPhase12: false,
    },
    {
      id: "v2_002",
      category: "business",
      title: "Usage-based enterprise billing packs",
      detail: "Seat + consumption hybrids for large orgs",
      implementInPhase12: false,
    },
    {
      id: "v2_003",
      category: "competitive",
      title: "Market feature parity scan (commercial UX)",
      detail: "Compare portal / partner / support surfaces — not trading",
      implementInPhase12: false,
    },
    {
      id: "v2_004",
      category: "technology",
      title: "Multi-region active-active data plane",
      detail: "Beyond current HA — V2 architecture program",
      implementInPhase12: false,
    },
    {
      id: "v2_005",
      category: "ai",
      title: "Proactive CS assistant (health → playbook)",
      detail: "Auto-open playbooks from health signals",
      implementInPhase12: false,
    },
    {
      id: "v2_006",
      category: "architecture",
      title: "Any Core Trading Engine evolution",
      detail: "STRICTLY Version 2.x engineering program — Owner approval required",
      implementInPhase12: false,
    },
  ];
}

export async function buildV2Planning() {
  const backlog = collectV2PlanningBacklog();
  const payload = {
    rule: "DO NOT IMPLEMENT in Phase 12. Planning backlog only. Await Owner approval before Version 2.x Engineering Program.",
    capabilities: v2PlanningCapabilities(),
    backlog,
    backlogCount: backlog.length,
    implementationBlocked: true,
    at: new Date().toISOString(),
  };

  savePhase12Run("v2_planning", "Phase 12 V2.0 Planning (no implement)", payload);
  return payload;
}
