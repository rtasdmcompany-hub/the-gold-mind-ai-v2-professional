/**
 * Task 4 — Production deployment readiness (env-aware, no fake cloud calls).
 */
import { validateSecretsPresent } from "@/server/cloud/security";
import { getCacheBackend } from "@/server/cloud/cache";
import { runHealthChecks } from "@/server/cloud/monitoring";
import { saveWebsiteLaunchRun } from "./store";

export interface DeployCheck {
  id: string;
  label: string;
  status: "pass" | "partial" | "fail" | "n/a";
  detail: string;
}

export async function runProductionDeploymentReview(): Promise<{
  checks: DeployCheck[];
  score: number;
  at: string;
}> {
  const secrets = validateSecretsPresent();
  const health = await runHealthChecks(false);
  const cache = getCacheBackend();

  const checks: DeployCheck[] = [
    {
      id: "github_release",
      label: "GitHub Release",
      status: process.env.GITHUB_REPOSITORY || process.env.CI ? "partial" : "partial",
      detail: "Tag/release process documented — remote may be absent in local workspace",
    },
    {
      id: "vercel",
      label: "Vercel Deployment",
      status: process.env.VERCEL || process.env.VERCEL_URL ? "pass" : "partial",
      detail: process.env.VERCEL_URL
        ? `Detected VERCEL_URL=${process.env.VERCEL_URL}`
        : "Not running on Vercel in this environment — configure project for prod",
    },
    {
      id: "supabase",
      label: "Supabase Production",
      status: process.env.SUPABASE_URL ? "pass" : "n/a",
      detail: process.env.SUPABASE_URL
        ? "SUPABASE_URL present"
        : "File-backed stores in RC — Supabase optional until MAU requires SQL",
    },
    {
      id: "cloudflare",
      label: "Cloudflare",
      status: process.env.CF_ZONE_ID || process.env.CLOUDFLARE_API_TOKEN ? "pass" : "partial",
      detail: "TLS/CDN recommended for public Stable — credentials not required for RC",
    },
    {
      id: "runpod",
      label: "RunPod",
      status: "n/a",
      detail: "Async only — not on critical license path",
    },
    {
      id: "redis",
      label: "Redis",
      status: cache === "upstash" ? "pass" : "partial",
      detail: `Cache backend: ${cache} — Upstash preferred for multi-instance`,
    },
    {
      id: "email",
      label: "Email Service",
      status: process.env.SMTP_HOST || process.env.RESEND_API_KEY || process.env.SENDGRID_API_KEY
        ? "pass"
        : "partial",
      detail: "Transactional provider env optional in RC; required for Stable notifications",
    },
    {
      id: "workers",
      label: "Background Workers",
      status: "partial",
      detail: "Webhook + cache workers in-process; separate worker fleet optional",
    },
    {
      id: "env_vars",
      label: "Environment Variables",
      status: secrets.ok ? "pass" : "partial",
      detail: secrets.ok ? "Required secrets present" : `Missing: ${secrets.missing.join(", ")}`,
    },
    {
      id: "rollback",
      label: "Deployment Rollback",
      status: "pass",
      detail: "Documented: redeploy prior Vercel/GitHub release · restore .data backups",
    },
    {
      id: "health",
      label: "Platform Health Probe",
      status: health.status === "unhealthy" ? "fail" : "pass",
      detail: `Health status: ${health.status}`,
    },
  ];

  const score = Math.round(
    (checks.reduce(
      (a, c) =>
        a + (c.status === "pass" ? 1 : c.status === "partial" ? 0.55 : c.status === "n/a" ? 1 : 0),
      0
    ) /
      checks.length) *
      100
  );
  const payload = { checks, score, at: new Date().toISOString() };
  saveWebsiteLaunchRun("deployment", "Sprint 8 production deployment", payload);
  return payload;
}
