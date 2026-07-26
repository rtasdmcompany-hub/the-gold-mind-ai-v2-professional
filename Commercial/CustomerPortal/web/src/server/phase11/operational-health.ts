/**
 * Task 5 — Operational health across commercial services.
 */
import { getProductionHealthDashboard } from "@/server/observability/health-dashboard";
import { runHealthChecks } from "@/server/cloud/monitoring";
import { savePhase11Run } from "./store";

export async function buildOperationalHealth() {
  const [dash, health] = await Promise.all([
    getProductionHealthDashboard(),
    runHealthChecks(false),
  ]);

  const pick = (id: string, label: string) => {
    const card = dash.cards.find((c) => c.id === id);
    return {
      id,
      label,
      status: card?.status || "degraded",
      latencyMs: card?.latencyMs ?? 0,
      detail: card?.detail || "",
    };
  };

  const services = [
    pick("portal", "Portal"),
    pick("api", "API"),
    pick("auth", "Authentication"),
    pick("payments", "Payments"),
    pick("license", "Licensing"),
    pick("update", "Updates"),
    pick("email", "Email"),
    pick("database", "Database"),
    pick("redis", "Redis"),
    {
      id: "cloud",
      label: "Cloud Services",
      status: health.status,
      latencyMs: 0,
      detail: health.services.map((s) => `${s.id}:${s.status}`).join(", ").slice(0, 160),
    },
    pick("workers", "Background Workers"),
  ];

  const healthy = services.filter((s) => s.status === "healthy").length;
  const score = Math.round((healthy / services.length) * 100);

  const payload = {
    overall: dash.overall,
    services,
    score,
    isolation: dash.isolation,
    at: new Date().toISOString(),
  };
  savePhase11Run("health", "Operational health snapshot", payload);
  return payload;
}
