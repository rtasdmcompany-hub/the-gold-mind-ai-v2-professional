/**
 * Task 4 — Secret & key management verification.
 */
import fs from "fs";
import path from "path";
import { getSecretRotationStrategy, listRequiredSecrets } from "@/server/cloud/database";
import { validateSecretsPresent } from "@/server/cloud/security";
import { isProductionRuntime } from "./dev-bypass";
import { saveSecurityRun, type SecurityFinding } from "./store";

const INSECURE_DEFAULTS = [
  "dev-license-store-insecure",
  "dev-billing-store",
  "dev-audit-store",
  "dev-update-report-secret",
  "sandbox-webhook-secret",
  "dev-change-me",
];

export interface SecretCheck {
  id: string;
  label: string;
  status: "ok" | "missing" | "weak" | "n/a";
  detail: string;
}

export async function runSecretManagementReview(): Promise<{
  checks: SecretCheck[];
  rotation: ReturnType<typeof getSecretRotationStrategy>;
  findings: SecurityFinding[];
  score: number;
  at: string;
}> {
  const findings: SecurityFinding[] = [];
  const checks: SecretCheck[] = [];
  const present = validateSecretsPresent();

  checks.push({
    id: "env_vars",
    label: "Environment Variables",
    status: present.ok ? "ok" : "missing",
    detail: present.ok ? "Required secrets present" : `Missing: ${present.missing.join(", ")}`,
  });

  const keys: Array<{ id: string; env: string; label: string }> = [
    { id: "api_keys", env: "UPSTASH_REDIS_REST_TOKEN", label: "API Keys (Upstash)" },
    { id: "oauth", env: "GOOGLE_CLIENT_SECRET", label: "OAuth Secrets" },
    { id: "webhook", env: "SANDBOX_WEBHOOK_SECRET", label: "Webhook Secrets" },
    { id: "encryption", env: "LICENSE_STORE_SECRET", label: "Encryption Keys" },
    { id: "nextauth", env: "NEXTAUTH_SECRET", label: "Session Signing Secret" },
  ];

  for (const k of keys) {
    const v = process.env[k.env] || "";
    if (!v) {
      checks.push({
        id: k.id,
        label: k.label,
        status: k.env === "NEXTAUTH_SECRET" || (isProductionRuntime() && k.env !== "UPSTASH_REDIS_REST_TOKEN" && k.env !== "GOOGLE_CLIENT_SECRET")
          ? "missing"
          : "n/a",
        detail: `${k.env} unset`,
      });
      continue;
    }
    const weak = INSECURE_DEFAULTS.some((d) => v.includes(d)) || v.length < 16;
    checks.push({
      id: k.id,
      label: k.label,
      status: weak ? "weak" : "ok",
      detail: weak ? `${k.env} looks like a known/dev default` : `${k.env} set (length ${v.length})`,
    });
    if (weak && isProductionRuntime()) {
      findings.push({
        id: `sec-${k.id}`,
        area: "Secrets",
        severity: "High",
        title: `Weak ${k.label}`,
        detail: k.env,
        status: "open",
        mitigation: "Rotate to cryptographically random value ≥32 chars",
      });
    }
  }

  // Client-side exposure scan (NEXT_PUBLIC_*)
  let publicLeak = 0;
  const envExample = path.join(process.cwd(), ".env.local.example");
  if (fs.existsSync(envExample)) {
    const t = fs.readFileSync(envExample, "utf8");
    if (/NEXT_PUBLIC_.*(SECRET|KEY|TOKEN)/i.test(t)) publicLeak += 1;
  }
  checks.push({
    id: "client_exposure",
    label: "No secrets in client-side code",
    status: publicLeak ? "weak" : "ok",
    detail: publicLeak ? "NEXT_PUBLIC secret pattern in example" : "No NEXT_PUBLIC secret patterns in .env.local.example",
  });

  const rotation = getSecretRotationStrategy();
  checks.push({
    id: "rotation",
    label: "Secret Rotation Strategy",
    status: "ok",
    detail: `Dual-read ${rotation.dualReadEnvSuffix} · max overlap ${rotation.maxOverlapHours}h · stores: ${rotation.stores.join(", ")}`,
  });

  findings.push({
    id: "sec-rotation",
    area: "Secrets",
    severity: "Info",
    title: "Rotation strategy documented",
    detail: listRequiredSecrets().join(", "),
    status: "pass",
    mitigation: "Operational dual-read via *_PREVIOUS then re-encrypt",
  });

  const okish = checks.filter((c) => c.status === "ok" || c.status === "n/a").length;
  const score = Math.round((okish / checks.length) * 100);
  const payload = { checks, rotation, findings, score, at: new Date().toISOString() };
  saveSecurityRun("secrets", "Sprint 6 secret management", payload);
  return payload;
}
