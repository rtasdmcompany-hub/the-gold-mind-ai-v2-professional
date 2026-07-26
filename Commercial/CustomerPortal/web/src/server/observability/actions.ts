"use server";

import { revalidatePath } from "next/cache";
import { requirePermission } from "@/server/licensing/session";
import { recordTelemetry, type TelemetryKind } from "./telemetry-store";
import { recordUsageEvent } from "./usage-analytics";
import { updateAlert, setRuleEnabled, type AlertRuleId, type AlertStatus } from "./alert-store";
import { evaluateAlerts } from "./alert-engine";
import { updateIncident } from "@/server/launch/incident-store";

function revalidateObs() {
  revalidatePath("/portal/admin/observability");
  revalidatePath("/portal/admin/telemetry");
  revalidatePath("/portal/admin/usage");
  revalidatePath("/portal/admin/alerts");
  revalidatePath("/portal/admin/ops-intelligence");
  revalidatePath("/portal/admin/incident-timeline");
}

export async function actionRecordTelemetry(formData: FormData): Promise<void> {
  await requirePermission("admin.observability.write");
  const kind = String(formData.get("kind") || "") as TelemetryKind;
  const valueMs = Number(formData.get("valueMs") || 0) || undefined;
  const detail = String(formData.get("detail") || "").trim() || undefined;
  if (!kind) return;
  recordTelemetry({ kind, valueMs, detail });
  revalidateObs();
}

export async function actionRecordUsage(formData: FormData): Promise<void> {
  await requirePermission("admin.observability.write");
  const type = String(formData.get("type") || "page_view") as
    | "session_start"
    | "session_end"
    | "page_view"
    | "feature_use"
    | "download"
    | "activation";
  const page = String(formData.get("page") || "").trim() || undefined;
  const feature = String(formData.get("feature") || "").trim() || undefined;
  const durationMin = Number(formData.get("durationMin") || 0) || undefined;
  const email = String(formData.get("email") || "").trim() || undefined;
  recordUsageEvent({ type, page, feature, durationMin, email });
  revalidateObs();
}

export async function actionUpdateAlert(formData: FormData): Promise<void> {
  const s = await requirePermission("admin.observability.write");
  const id = String(formData.get("id") || "");
  const status = String(formData.get("status") || "") as AlertStatus | "";
  const owner = String(formData.get("owner") || "") || undefined;
  updateAlert(id, { status: status || undefined, owner }, s.email);
  revalidateObs();
}

export async function actionToggleAlertRule(formData: FormData): Promise<void> {
  const s = await requirePermission("admin.observability.write");
  const ruleId = String(formData.get("ruleId") || "") as AlertRuleId;
  const enabled = formData.get("enabled") === "1";
  if (!ruleId) return;
  setRuleEnabled(ruleId, enabled, s.email);
  revalidateObs();
}

export async function actionEvaluateAlerts(): Promise<void> {
  await requirePermission("admin.observability.write");
  await evaluateAlerts();
  revalidateObs();
}

export async function actionUpdateIncidentTimeline(formData: FormData): Promise<void> {
  const s = await requirePermission("admin.observability.write");
  const id = String(formData.get("id") || "");
  const rootCause = String(formData.get("rootCause") || "");
  const resolution = String(formData.get("resolution") || "");
  const environment = String(formData.get("environment") || "");
  const owner = String(formData.get("owner") || "");
  const status = String(formData.get("status") || "") as
    | "open"
    | "investigating"
    | "mitigated"
    | "resolved"
    | "closed"
    | "";
  updateIncident(
    id,
    {
      rootCause: rootCause || undefined,
      resolution: resolution || undefined,
      environment: environment || undefined,
      owner: owner || undefined,
      status: status || undefined,
    },
    s.email,
    "Timeline fields updated"
  );
  revalidatePath("/portal/admin/incident-timeline");
  revalidatePath("/portal/admin/incidents");
}
