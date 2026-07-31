/**
 * Task 5 — Launch operations pack (checklists + templates written to Documentation/).
 */
import fs from "fs";
import path from "path";
import { saveWebsiteLaunchRun } from "./store";

export interface OpsArtifact {
  id: string;
  label: string;
  path: string;
  status: "ready" | "missing";
}

function commercialDocs(): string {
  return path.resolve(process.cwd(), "..", "..", "Documentation");
}

function ensureOpsDocs() {
  const dir = commercialDocs();
  if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });

  const files: Record<string, string> = {
    "GO_LIVE_CHECKLIST.md": `# GO_LIVE_CHECKLIST.md

**Edition:** THE GOLD MIND PROFESSIONAL (Website)  
**Rule:** No public Stable if any Critical blocker remains.

## Pre-go-live

- [ ] BC-LEGAL counsel sign-off (Privacy/Terms/Refund/Risk)
- [ ] BC-BRAND assets approved
- [ ] Live PSP credentials configured (or written invite-only waiver)
- [ ] Authenticode Stable (or waiver)
- [ ] KB ≥ 20 articles verified
- [ ] Core SHA-256 matches certification
- [ ] Demo auth disabled in production
- [ ] HTTPS + CSRF + secrets validated
- [ ] Customer notification templates ready
- [ ] Rollback owner assigned

## Go-live

- [ ] Deploy production portal
- [ ] Smoke: register/invite → purchase → activate → download
- [ ] Monitor health + payments + support queue
- [ ] Publish release notes

## Post-go-live (T+24h)

- [ ] Review incidents / alerts
- [ ] Confirm email delivery
- [ ] Confirm updater check path
`,
    "LAUNCH_OPERATIONS.md": `# LAUNCH_OPERATIONS.md

## Emergency contacts (fill before Stable)

| Role | Contact |
|------|---------|
| Owner | TBD |
| Engineering on-call | TBD |
| Support lead | TBD |
| PSP account owner | TBD |

## Maintenance

1. Announce window via Portal announcements + email template.  
2. Enable maintenance flag if available.  
3. Deploy.  
4. Smoke test.  
5. Clear maintenance.

## Incident response

1. Detect via observability alerts.  
2. Triage P0–P3.  
3. Mitigate commercial services only — **never** modify Core EA.  
4. Communicate via templates.  
5. Postmortem within 48h.

## Rollback

1. Redeploy previous GitHub/Vercel release.  
2. Restore \`.data\` from last DR drill if stores corrupted.  
3. Verify Core SHA unchanged.
`,
  };

  const opsDir = path.join(dir);
  for (const [name, body] of Object.entries(files)) {
    const p = path.join(opsDir, name);
    if (!fs.existsSync(p)) fs.writeFileSync(p, body, "utf8");
  }

  const templatesDir = path.join(dir, "LaunchTemplates");
  if (!fs.existsSync(templatesDir)) fs.mkdirSync(templatesDir, { recursive: true });
  const templates: Record<string, string> = {
    "NOTIFY_GO_LIVE.txt": `Subject: THE GOLD MIND PROFESSIONAL is available

Hello,

THE GOLD MIND PROFESSIONAL Website Edition is now available through the Customer Portal.

Sign in, activate your license, and download the installer from Downloads.

Trading involves risk of loss. Read the Risk disclosure before live use.

— THE GOLD MIND PROFESSIONAL
`,
    "NOTIFY_MAINTENANCE.txt": `Subject: Scheduled maintenance — Customer Portal

We will perform maintenance on {{window}}. Portal features may be briefly unavailable. Core EA on your MT5 terminal continues independently.

— THE GOLD MIND
`,
    "NOTIFY_INCIDENT.txt": `Subject: Service update — {{summary}}

We are investigating an issue affecting {{scope}}. Trading Core on MT5 is not modified by this commercial incident.

Status: {{status}}
Next update: {{eta}}

— THE GOLD MIND
`,
  };
  for (const [name, body] of Object.entries(templates)) {
    const p = path.join(templatesDir, name);
    if (!fs.existsSync(p)) fs.writeFileSync(p, body, "utf8");
  }
}

export async function runLaunchOperationsPrep(): Promise<{
  artifacts: OpsArtifact[];
  score: number;
  at: string;
}> {
  ensureOpsDocs();
  const dir = commercialDocs();
  const list = [
    "GO_LIVE_CHECKLIST.md",
    "LAUNCH_OPERATIONS.md",
    "LaunchTemplates/NOTIFY_GO_LIVE.txt",
    "LaunchTemplates/NOTIFY_MAINTENANCE.txt",
    "LaunchTemplates/NOTIFY_INCIDENT.txt",
  ];
  const artifacts: OpsArtifact[] = list.map((rel) => ({
    id: rel,
    label: rel,
    path: `Documentation/${rel}`,
    status: fs.existsSync(path.join(dir, rel.replace(/\//g, path.sep))) ? "ready" : "missing",
  }));

  // Also ensure WEBSITE release notes stub
  const rn = path.join(dir, "WEBSITE_RELEASE_NOTES_2.0.0.md");
  if (!fs.existsSync(rn)) {
    fs.writeFileSync(
      rn,
      `# THE GOLD MIND PROFESSIONAL 2.0.0 — Website Release Notes\n\n- Customer Portal production readiness pack (Phase 10 Sprint 8)\n- Marketing homepage, pricing, docs, contact\n- KB expanded for support gate\n- Core Trading Engine unchanged\n`,
      "utf8"
    );
  }

  const score = Math.round((artifacts.filter((a) => a.status === "ready").length / artifacts.length) * 100);
  const payload = { artifacts, score, at: new Date().toISOString() };
  saveWebsiteLaunchRun("operations", "Sprint 8 launch operations", payload);
  return payload;
}
