"use server";

import { revalidatePath } from "next/cache";
import { requirePermission, requireSession } from "@/server/licensing/session";
import { updateSupportTicket } from "@/server/admin/support-store";
import { issueSensitiveConfirmToken, consumeSensitiveConfirmToken, logAdminSecurityEvent } from "@/server/admin/security";
import { writeAudit } from "@/server/cloud/audit";

export async function actionCreateAdminSupportTicket(formData: FormData): Promise<void> {
  await requirePermission("admin.support.write");
  const { ensureSupportStoreLoaded, flushSupportStore, createSupportTicket, ensureDemoTickets } = await import(
    "@/server/admin/support-store"
  );
  await ensureSupportStoreLoaded();
  ensureDemoTickets();
  const email = String(formData.get("customerEmail") || "").trim().toLowerCase();
  const subject = String(formData.get("subject") || "").trim();
  const body = String(formData.get("body") || "").trim();
  const priority = (String(formData.get("priority") || "normal") as "low" | "normal" | "high" | "urgent");
  if (!email || !subject || !body) return;
  createSupportTicket({ customerEmail: email, subject, body, priority });
  await flushSupportStore();
  revalidatePath("/portal/admin/support");
}

export async function actionUpdateSupportTicket(formData: FormData): Promise<void> {
  const s = await requirePermission("admin.support.write");
  const id = String(formData.get("ticketId") || "");
  const status = String(formData.get("status") || "") as "open" | "pending" | "resolved" | "closed" | "";
  const assignee = String(formData.get("assignee") || s.email);
  const priority = String(formData.get("priority") || "") as "low" | "normal" | "high" | "urgent" | "";
  const note = String(formData.get("note") || "").trim();
  const resolution = String(formData.get("resolution") || "").trim();
  updateSupportTicket(
    id,
    {
      status: status || undefined,
      assignee,
      priority: priority || undefined,
      resolution: resolution || undefined,
    },
    s.email,
    note || undefined
  );
  revalidatePath("/portal/admin/support");
}

export async function actionIssueConfirmToken(formData: FormData): Promise<void> {
  const s = await requirePermission("admin.security.manage");
  const action = String(formData.get("action") || "sensitive");
  await issueSensitiveConfirmToken(s.email, action);
  revalidatePath("/portal/admin/security");
}

export async function actionConfirmSensitive(formData: FormData): Promise<void> {
  const s = await requirePermission("admin.security.manage");
  const token = String(formData.get("token") || "");
  const action = String(formData.get("action") || "sensitive");
  const ok = await consumeSensitiveConfirmToken(token, s.email, action);
  await logAdminSecurityEvent({
    user: s.email,
    ip: "admin",
    event: ok ? `confirmed ${action}` : `confirm failed ${action}`,
    result: ok ? "success" : "failure",
  });
  revalidatePath("/portal/admin/security");
}

/** Customer-facing ticket create also lands in support store */
export async function actionSubmitSupportTicket(formData: FormData): Promise<void> {
  const s = await requireSession();
  const { ensureSupportStoreLoaded, flushSupportStore, createSupportTicket } = await import(
    "@/server/admin/support-store"
  );
  await ensureSupportStoreLoaded();
  const subject = String(formData.get("subject") || "").trim();
  const body = String(formData.get("body") || "").trim();
  if (subject.length < 3 || body.length < 10) return;
  createSupportTicket({ customerEmail: s.email, subject, body, priority: "normal" });
  await flushSupportStore();
  writeAudit({
    user: s.email,
    action: "support_action",
    ip: "portal",
    result: "success",
    detail: subject,
  });
  revalidatePath("/portal/support");
  revalidatePath("/portal/admin/support");
}
