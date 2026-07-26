"use server";

import { revalidatePath } from "next/cache";
import { requirePermission, requireSession } from "@/server/licensing/session";
import {
  addBetaParticipant,
  updateBetaParticipant,
  setBetaCohortCap,
  completeEnrollmentStep,
  acceptInviteByCode,
  touchBetaActivity,
  getParticipantByEmail,
  type BetaGroup,
  type BetaStatus,
  type EnrollmentStep,
} from "./beta-store";
import {
  createIncident,
  updateIncident,
  type IncidentSeverity,
  type IncidentStatus,
} from "./incident-store";
import { submitFeedback, updateFeedback, type FeedbackCategory, type FeedbackStatus } from "./feedback-store";
import { createIssue, updateIssue, type IssuePriority, type IssueStatus, type IssueKind } from "./issue-store";
import { recordMetricEvent, type MetricEventType } from "./metrics-store";

function revalidateBeta() {
  revalidatePath("/portal/admin/beta");
  revalidatePath("/portal/admin/launch");
  revalidatePath("/portal/admin/beta-dashboard");
  revalidatePath("/portal/beta");
}

export async function actionInviteBeta(formData: FormData): Promise<void> {
  const s = await requirePermission("admin.launch.write");
  const email = String(formData.get("email") || "").trim();
  const name = String(formData.get("name") || "").trim();
  const group = String(formData.get("group") || "content_creators") as BetaGroup;
  const notes = String(formData.get("notes") || "").trim();
  addBetaParticipant({ email, name, group, notes, createdBy: s.email });
  revalidateBeta();
}

export async function actionUpdateBeta(formData: FormData): Promise<void> {
  const s = await requirePermission("admin.launch.write");
  const id = String(formData.get("id") || "");
  const status = String(formData.get("status") || "") as BetaStatus | "";
  const notes = String(formData.get("notes") || "");
  updateBetaParticipant(
    id,
    {
      status: status || undefined,
      notes: notes || undefined,
    },
    s.email
  );
  revalidateBeta();
}

export async function actionSetBetaCap(formData: FormData): Promise<void> {
  const s = await requirePermission("admin.launch.write");
  const cap = Number(formData.get("cap") || 50);
  setBetaCohortCap(cap, s.email);
  revalidatePath("/portal/admin/beta");
}

export async function actionCompleteEnrollmentStep(formData: FormData): Promise<void> {
  const s = await requirePermission("admin.launch.write");
  const id = String(formData.get("id") || "");
  const step = String(formData.get("step") || "") as EnrollmentStep;
  if (!id || !step) return;
  completeEnrollmentStep(id, step, s.email);
  revalidateBeta();
}

export async function actionAcceptBetaInvite(formData: FormData): Promise<void> {
  const s = await requireSession();
  const code = String(formData.get("inviteCode") || "").trim();
  acceptInviteByCode(code, s.email);
  touchBetaActivity(s.email);
  recordMetricEvent({ type: "login_success", email: s.email, detail: "beta accept" });
  revalidateBeta();
}

export async function actionSelfEnrollmentStep(formData: FormData): Promise<void> {
  const s = await requireSession();
  const step = String(formData.get("step") || "") as EnrollmentStep;
  const p = getParticipantByEmail(s.email);
  if (!p || !step) return;
  completeEnrollmentStep(p.id, step, s.email);
  if (step === "installer_download") recordMetricEvent({ type: "install_attempt", email: s.email });
  if (step === "installation") recordMetricEvent({ type: "install_success", email: s.email });
  if (step === "activation") recordMetricEvent({ type: "activation_success", email: s.email });
  if (step === "first_successful_login") recordMetricEvent({ type: "login_success", email: s.email });
  touchBetaActivity(s.email);
  revalidateBeta();
}

export async function actionCreateIncident(formData: FormData): Promise<void> {
  const s = await requirePermission("admin.launch.write");
  const title = String(formData.get("title") || "").trim();
  const severity = String(formData.get("severity") || "medium") as IncidentSeverity;
  const summary = String(formData.get("summary") || "").trim();
  const impact = String(formData.get("impact") || "").trim();
  const services = String(formData.get("services") || "")
    .split(",")
    .map((x) => x.trim())
    .filter(Boolean);
  if (!title || !summary) return;
  createIncident({
    title,
    severity,
    summary,
    impact: impact || summary,
    affectedServices: services.length ? services : ["portal"],
    commander: s.email,
    hotfixRequired: formData.get("hotfix") === "1",
    rollbackRequired: formData.get("rollback") === "1",
  });
  revalidatePath("/portal/admin/incidents");
  revalidatePath("/portal/admin/launch");
}

export async function actionUpdateIncident(formData: FormData): Promise<void> {
  const s = await requirePermission("admin.launch.write");
  const id = String(formData.get("id") || "");
  const status = String(formData.get("status") || "") as IncidentStatus | "";
  const note = String(formData.get("note") || "").trim();
  const customerNotified = formData.get("customerNotified") === "1";
  updateIncident(
    id,
    {
      status: status || undefined,
      customerNotified: formData.has("customerNotified") ? customerNotified : undefined,
    },
    s.email,
    note || undefined
  );
  revalidatePath("/portal/admin/incidents");
  revalidatePath("/portal/admin/launch");
}

export async function actionSubmitFeedback(formData: FormData): Promise<void> {
  const s = await requireSession();
  const category = String(formData.get("category") || "satisfaction") as FeedbackCategory;
  const title = String(formData.get("title") || "").trim();
  const detail = String(formData.get("detail") || "").trim();
  const satisfactionScore = Number(formData.get("satisfactionScore") || 0) || undefined;
  if (!title || !detail) return;
  submitFeedback({
    customerEmail: s.email,
    category,
    title,
    detail,
    satisfactionScore,
  });
  if (category === "bug") recordMetricEvent({ type: "support_request", email: s.email, detail: "bug feedback" });
  revalidatePath("/portal/feedback");
  revalidatePath("/portal/admin/feedback");
  revalidatePath("/portal/admin/beta-dashboard");
}

export async function actionSubmitStructuredFeedback(formData: FormData): Promise<void> {
  const s = await requireSession();
  const detail = String(formData.get("detail") || "").trim() || "Structured beta survey";
  submitFeedback({
    customerEmail: s.email,
    category: "structured",
    title: "Structured beta survey",
    detail,
    scores: {
      installation: Number(formData.get("installation") || 0) || undefined,
      uiux: Number(formData.get("uiux") || 0) || undefined,
      performance: Number(formData.get("performance") || 0) || undefined,
      documentation: Number(formData.get("documentation") || 0) || undefined,
      supportQuality: Number(formData.get("supportQuality") || 0) || undefined,
      licenseExperience: Number(formData.get("licenseExperience") || 0) || undefined,
      overallSatisfaction: Number(formData.get("overallSatisfaction") || 0) || undefined,
    },
  });
  revalidatePath("/portal/feedback");
  revalidatePath("/portal/admin/feedback");
  revalidatePath("/portal/admin/beta-dashboard");
}

export async function actionTriageFeedback(formData: FormData): Promise<void> {
  const s = await requirePermission("admin.launch.write");
  const id = String(formData.get("id") || "");
  const status = String(formData.get("status") || "") as FeedbackStatus | "";
  const adminNote = String(formData.get("adminNote") || "");
  const priority = String(formData.get("priority") || "") as import("./feedback-store").FeedbackPriority | "";
  const owner = String(formData.get("owner") || "");
  const verification = String(formData.get("verification") || "");
  const releaseTarget = String(formData.get("releaseTarget") || "");
  updateFeedback(
    id,
    {
      status: status || undefined,
      adminNote: adminNote || undefined,
      priority: priority || undefined,
      owner: owner || undefined,
      verification: verification || undefined,
      releaseTarget: releaseTarget || undefined,
    },
    s.email
  );
  revalidatePath("/portal/admin/feedback");
  revalidatePath("/portal/admin/success");
}

export async function actionCreateIssue(formData: FormData): Promise<void> {
  const s = await requirePermission("admin.launch.write");
  const title = String(formData.get("title") || "").trim();
  const description = String(formData.get("description") || "").trim();
  const priority = String(formData.get("priority") || "P2") as IssuePriority;
  const kind = String(formData.get("kind") || "bug") as IssueKind;
  const owner = String(formData.get("owner") || s.email).trim();
  const targetFix = String(formData.get("targetFix") || "").trim();
  const releaseTarget = String(formData.get("releaseTarget") || targetFix).trim();
  if (!title || !description) return;
  createIssue({
    title,
    description,
    priority,
    kind,
    owner,
    reporter: s.email,
    targetFix: targetFix || undefined,
    releaseTarget: releaseTarget || undefined,
  });
  revalidatePath("/portal/admin/issues");
  revalidatePath("/portal/admin/beta-dashboard");
  revalidatePath("/portal/admin/success");
}

export async function actionUpdateIssue(formData: FormData): Promise<void> {
  const s = await requirePermission("admin.launch.write");
  const id = String(formData.get("id") || "");
  const status = String(formData.get("status") || "") as IssueStatus | "";
  const owner = String(formData.get("owner") || "");
  const targetFix = String(formData.get("targetFix") || "");
  const verification = String(formData.get("verification") || "");
  const priority = String(formData.get("priority") || "") as IssuePriority | "";
  const releaseTarget = String(formData.get("releaseTarget") || "");
  updateIssue(
    id,
    {
      status: status || undefined,
      owner: owner || undefined,
      targetFix: targetFix || undefined,
      releaseTarget: releaseTarget || undefined,
      verification: verification || undefined,
      priority: priority || undefined,
    },
    s.email
  );
  revalidatePath("/portal/admin/issues");
  revalidatePath("/portal/admin/beta-dashboard");
  revalidatePath("/portal/admin/success");
}

export async function actionRecordMetric(formData: FormData): Promise<void> {
  const s = await requirePermission("admin.launch.write");
  const type = String(formData.get("type") || "") as MetricEventType;
  const email = String(formData.get("email") || "").trim() || undefined;
  const sessionMinutes = Number(formData.get("sessionMinutes") || 0) || undefined;
  const detail = String(formData.get("detail") || "").trim() || undefined;
  if (!type) return;
  recordMetricEvent({ type, email, sessionMinutes, detail });
  revalidatePath("/portal/admin/metrics");
  revalidatePath("/portal/admin/beta-dashboard");
}
