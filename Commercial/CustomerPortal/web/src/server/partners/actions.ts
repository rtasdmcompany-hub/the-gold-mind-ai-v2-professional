"use server";

import { revalidatePath } from "next/cache";
import { auth } from "@/auth";
import { requirePermission } from "@/server/licensing/session";
import {
  approveApplication,
  processPayout,
  rejectApplication,
  requestPayout,
  setPartnerStatus,
  submitPartnerApplication,
  verifyPartner,
} from "./operations";
import { approveCommission } from "./commission";
import { getPhase11Sprint3Dashboard, runFullPhase11Sprint3Suite } from "./suite";
import { getPartnerByEmail } from "./portal";

function revalidate() {
  revalidatePath("/portal/partner");
  revalidatePath("/portal/admin/partners");
  revalidatePath("/portal/admin/partner-analytics");
  revalidatePath("/partners/apply");
}

export async function actionRunPartnerSuite(): Promise<void> {
  await requirePermission("admin.launch.write");
  await runFullPhase11Sprint3Suite();
  revalidate();
}

export async function actionSubmitPartnerApplication(formData: FormData): Promise<void> {
  submitPartnerApplication({
    email: String(formData.get("email") || ""),
    name: String(formData.get("name") || ""),
    company: String(formData.get("company") || "") || undefined,
    region: String(formData.get("region") || "") || undefined,
    country: String(formData.get("country") || "") || undefined,
    website: String(formData.get("website") || "") || undefined,
    pitch: String(formData.get("pitch") || ""),
  });
  revalidate();
}

export async function actionApproveApplication(formData: FormData): Promise<void> {
  await requirePermission("admin.billing.write");
  const session = await auth();
  approveApplication(String(formData.get("applicationId")), session?.user?.email || "admin");
  revalidate();
}

export async function actionRejectApplication(formData: FormData): Promise<void> {
  await requirePermission("admin.billing.write");
  const session = await auth();
  rejectApplication(
    String(formData.get("applicationId")),
    session?.user?.email || "admin",
    String(formData.get("notes") || "rejected")
  );
  revalidate();
}

export async function actionVerifyPartner(formData: FormData): Promise<void> {
  await requirePermission("admin.billing.write");
  const session = await auth();
  verifyPartner(String(formData.get("partnerId")), session?.user?.email || "admin");
  revalidate();
}

export async function actionSuspendPartner(formData: FormData): Promise<void> {
  await requirePermission("admin.billing.write");
  const session = await auth();
  setPartnerStatus(
    String(formData.get("partnerId")),
    "suspended",
    session?.user?.email || "admin",
    String(formData.get("reason") || "policy")
  );
  revalidate();
}

export async function actionReactivatePartner(formData: FormData): Promise<void> {
  await requirePermission("admin.billing.write");
  const session = await auth();
  setPartnerStatus(String(formData.get("partnerId")), "verified", session?.user?.email || "admin");
  revalidate();
}

export async function actionApproveCommission(formData: FormData): Promise<void> {
  await requirePermission("admin.billing.write");
  const session = await auth();
  approveCommission(String(formData.get("commissionId")), session?.user?.email || "admin");
  revalidate();
}

export async function actionRequestPayout(): Promise<void> {
  const session = await auth();
  const email = session?.user?.email;
  if (!email) throw new Error("UNAUTHORIZED");
  const partner = getPartnerByEmail(email);
  if (!partner) throw new Error("NOT_A_PARTNER");
  requestPayout(partner.id, email);
  revalidate();
}

export async function actionProcessPayout(formData: FormData): Promise<void> {
  await requirePermission("admin.billing.write");
  const session = await auth();
  processPayout(
    String(formData.get("payoutId")),
    session?.user?.email || "admin",
    String(formData.get("decision") || "approved") as "approved" | "paid" | "rejected",
    String(formData.get("detail") || "") || undefined
  );
  revalidate();
}

export async function actionRefreshPartnerDash(): Promise<void> {
  await requirePermission("admin.launch.read");
  await getPhase11Sprint3Dashboard({ refresh: false });
  revalidate();
}
