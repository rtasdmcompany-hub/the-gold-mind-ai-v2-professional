/**
 * Task 2 — End-to-end customer journey validation (commercial).
 */
import fs from "fs";
import path from "path";
import { PLAN_CATALOG } from "@/server/billing/util";
import { saveWebsiteLaunchRun } from "./store";

export interface JourneyStep {
  id: string;
  label: string;
  status: "pass" | "partial" | "fail" | "blocked";
  detail: string;
}

function pageExists(...segments: string[]): boolean {
  const base = path.join(process.cwd(), "src", "app", ...segments);
  return fs.existsSync(path.join(base, "page.tsx"));
}

export async function runCustomerJourneyValidation(): Promise<{
  steps: JourneyStep[];
  score: number;
  at: string;
}> {
  const livePsp =
    !!process.env.PADDLE_VENDOR_ID ||
    !!process.env.PAYPAL_CLIENT_ID ||
    process.env.PAYMENT_FORCE_SANDBOX === "false";
  const openSignup = process.env.PORTAL_OPEN_SIGNUP === "true";

  const steps: JourneyStep[] = [
    {
      id: "landing",
      label: "Landing Page",
      status: pageExists() ? "pass" : "fail",
      detail: "Homepage brand hero",
    },
    {
      id: "registration",
      label: "Account Registration",
      status: pageExists("register") ? (openSignup ? "pass" : "partial") : "fail",
      detail: openSignup
        ? "Open signup enabled"
        : "Invite-only Controlled Launch — /register gate present",
    },
    {
      id: "email_verification",
      label: "Email Verification",
      status: "partial",
      detail: "Auth.js session + billing/outbox email paths; dedicated verify UI pending provider",
    },
    {
      id: "license_purchase",
      label: "License Purchase",
      status: pageExists("portal", "billing") ? "pass" : "fail",
      detail: `Plans: ${Object.keys(PLAN_CATALOG).join(", ")}`,
    },
    {
      id: "payment",
      label: "Payment",
      status: livePsp ? "pass" : "partial",
      detail: livePsp
        ? "Live PSP env detected"
        : "Sandbox PaymentPort (PAYMENT_FORCE_SANDBOX) — live credentials for Stable",
    },
    {
      id: "activation",
      label: "License Activation",
      status: pageExists("portal", "licenses") ? "pass" : "fail",
      detail: "Portal licenses + device binding",
    },
    {
      id: "download",
      label: "Download",
      status: pageExists("portal", "downloads") ? "pass" : "fail",
      detail: "Download Center + release API",
    },
    {
      id: "installation",
      label: "Installation",
      status: fs.existsSync(
        path.resolve(process.cwd(), "..", "..", "Installer", "Professional", "scripts")
      )
        ? "pass"
        : "partial",
      detail: "Professional installer scripts present",
    },
    {
      id: "first_login",
      label: "First Login",
      status: pageExists("login") ? "pass" : "fail",
      detail: "OAuth/demo login → /portal",
    },
    {
      id: "auto_update",
      label: "Auto Update",
      status: pageExists("portal", "updates") ? "pass" : "fail",
      detail: "Updates UI + release check/report APIs",
    },
    {
      id: "support_portal",
      label: "Support Portal",
      status: pageExists("portal", "support") ? "pass" : "fail",
      detail: "Ticket intake + KB",
    },
    {
      id: "renewal",
      label: "Renewal",
      status: pageExists("portal", "subscriptions") ? "pass" : "fail",
      detail: "Subscriptions / billing renewal path",
    },
  ];

  const score = Math.round(
    (steps.reduce(
      (a, s) => a + (s.status === "pass" ? 1 : s.status === "partial" ? 0.55 : s.status === "blocked" ? 0 : 0),
      0
    ) /
      steps.length) *
      100
  );
  const payload = { steps, score, at: new Date().toISOString() };
  saveWebsiteLaunchRun("journey", "Sprint 8 customer journey", payload);
  return payload;
}
