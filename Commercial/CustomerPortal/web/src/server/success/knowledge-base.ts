/**
 * Knowledge Base articles — commercial support content only.
 * Never documents Core strategy internals.
 */
export type KbCategory =
  | "installation"
  | "activation"
  | "license_transfer"
  | "subscription"
  | "portal_usage"
  | "troubleshooting"
  | "auto_update"
  | "faq"
  | "mt5_integration"
  | "broker_setup";

export interface KbArticle {
  id: string;
  slug: string;
  category: KbCategory;
  title: string;
  summary: string;
  body: string;
  tags: string[];
  views: number;
  helpful: number;
  updatedAt: string;
}

export const KB_CATEGORY_LABELS: Record<KbCategory, string> = {
  installation: "Installation",
  activation: "Activation",
  license_transfer: "License Transfer",
  subscription: "Subscription",
  portal_usage: "Portal Usage",
  troubleshooting: "Troubleshooting",
  auto_update: "Auto Update",
  faq: "FAQ",
  mt5_integration: "MT5 Integration",
  broker_setup: "Broker Setup",
};

const UPDATED = "2026-07-26T12:00:00.000Z";

/** Static curated articles (≥1 per category). Views tracked in-memory/session via markKbView. */
export const KB_ARTICLES: KbArticle[] = [
  {
    id: "kb_install_01",
    slug: "install-professional-windows",
    category: "installation",
    title: "Install THE GOLD MIND Professional (Windows)",
    summary: "Run the Professional installer and verify SHA-256 before first launch.",
    body: "Download the signed/RC package from Portal → Downloads. Verify checksum. Run Install-TheGoldMindProfessional.ps1 (or MSI when published). Confirm MT5 data folder path. Restart MetaTrader 5. The Core EA file is certified frozen — do not replace with unofficial builds.",
    tags: ["installer", "windows", "sha256"],
    views: 42,
    helpful: 18,
    updatedAt: UPDATED,
  },
  {
    id: "kb_act_01",
    slug: "activate-license",
    category: "activation",
    title: "Activate your license key",
    summary: "Bind a license to your account and device from the Customer Portal.",
    body: "Sign in → My Licenses → Activate. Enter the key from your purchase email. Confirm device limit. Activation is commercial-only and does not alter trading logic.",
    tags: ["license", "activate"],
    views: 55,
    helpful: 22,
    updatedAt: UPDATED,
  },
  {
    id: "kb_xfer_01",
    slug: "license-transfer-device",
    category: "license_transfer",
    title: "Transfer a license to a new device",
    summary: "Deactivate an old device then activate on the new workstation.",
    body: "Portal → Devices → Deactivate old machine. On the new PC, install Professional, then Activate. Contact Support if device slots are exhausted. Transfers are audited.",
    tags: ["devices", "transfer"],
    views: 21,
    helpful: 9,
    updatedAt: UPDATED,
  },
  {
    id: "kb_sub_01",
    slug: "manage-subscription",
    category: "subscription",
    title: "Manage subscription and renewals",
    summary: "View plan, renew, or cancel from Billing Center.",
    body: "Portal → Billing / Subscriptions. Renewals are handled by PaymentPort (sandbox or live). Cancellations stop future charges; access continues until period end.",
    tags: ["billing", "renew"],
    views: 33,
    helpful: 14,
    updatedAt: UPDATED,
  },
  {
    id: "kb_portal_01",
    slug: "portal-navigation",
    category: "portal_usage",
    title: "Customer Portal navigation guide",
    summary: "Licenses, downloads, updates, support, and feedback.",
    body: "Use the left nav for Licenses, Downloads, Updates, Billing, Devices, Support, Feedback, and Knowledge Base. Admin sections appear only for authorized roles.",
    tags: ["portal", "ui"],
    views: 28,
    helpful: 11,
    updatedAt: UPDATED,
  },
  {
    id: "kb_ts_01",
    slug: "troubleshoot-activation-fail",
    category: "troubleshooting",
    title: "Troubleshooting activation failures",
    summary: "Common causes: wrong email, device limit, expired trial.",
    body: "Confirm the license email matches your portal login. Check device count. Verify subscription status is active. Collect portal error ID and open Support with diagnostics — never share Core source.",
    tags: ["errors", "activation"],
    views: 37,
    helpful: 15,
    updatedAt: UPDATED,
  },
  {
    id: "kb_upd_01",
    slug: "auto-update-channels",
    category: "auto_update",
    title: "Auto-update channels explained",
    summary: "stable, rc, and dev channels with checksum verification.",
    body: "Portal → Updates shows available packages. Installer Update script verifies SHA-256 before apply. Rollback uses prior channel package. Authenticode Stable may still be pending for public Stable.",
    tags: ["updates", "checksum"],
    views: 19,
    helpful: 8,
    updatedAt: UPDATED,
  },
  {
    id: "kb_faq_01",
    slug: "faq-core-frozen",
    category: "faq",
    title: "FAQ: Is the trading engine updated in beta?",
    summary: "No. The Core Trading Engine is certified and frozen.",
    body: "Beta improvements cover portal, licensing, installer UX, docs, and support only. Strategy, risk, recovery, and execution logic are not changed during Phase 10.",
    tags: ["faq", "core"],
    views: 64,
    helpful: 31,
    updatedAt: UPDATED,
  },
  {
    id: "kb_mt5_01",
    slug: "attach-ea-mt5",
    category: "mt5_integration",
    title: "Attach the Professional EA in MetaTrader 5",
    summary: "Load the certified Expert on XAUUSD chart after install.",
    body: "Open MT5 → Navigator → Experts → THE GOLD MIND Professional. Drag to chart. Enable Algo Trading. Inputs are commercial edition flags only — do not modify frozen core parameters unless documented for edition shells.",
    tags: ["mt5", "ea"],
    views: 48,
    helpful: 20,
    updatedAt: UPDATED,
  },
  {
    id: "kb_broker_01",
    slug: "broker-account-setup",
    category: "broker_setup",
    title: "Broker account setup checklist",
    summary: "Hedging account, symbol mapping, and VPS tips.",
    body: "Use a hedging MT5 account where required by your broker. Confirm XAUUSD (or mapped gold symbol) is tradable. Prefer low-latency VPS near the broker. Commercial portal does not configure broker credentials.",
    tags: ["broker", "xauusd"],
    views: 26,
    helpful: 10,
    updatedAt: UPDATED,
  },
  {
    id: "kb_faq_02",
    slug: "faq-support-hours",
    category: "faq",
    title: "FAQ: How do I contact support?",
    summary: "Use Portal → Support and attach diagnostics.",
    body: "Open a ticket with subject, steps to reproduce, and license email. Check Knowledge Base first. Critical production issues escalate via Incident Timeline.",
    tags: ["support", "faq"],
    views: 30,
    helpful: 12,
    updatedAt: UPDATED,
  },
  {
    id: "kb_ts_02",
    slug: "troubleshoot-update-fail",
    category: "troubleshooting",
    title: "Troubleshooting update failures",
    summary: "Checksum mismatch or locked files.",
    body: "Close MT5 before updating. Re-download if SHA-256 fails. Confirm channel (rc vs stable). Report via Feedback as a bug with package version — commercial packaging only.",
    tags: ["updates", "errors"],
    views: 14,
    helpful: 6,
    updatedAt: UPDATED,
  },
  {
    id: "kb_install_02",
    slug: "verify-package-checksum",
    category: "installation",
    title: "Verify installer SHA-256 checksum",
    summary: "Confirm the downloaded ZIP matches the portal checksum before install.",
    body: "Portal → Downloads shows SHA-256. Compare with your local hash tool. Never install packages that fail verification. Core remains certified and frozen.",
    tags: ["sha256", "download"],
    views: 18,
    helpful: 7,
    updatedAt: UPDATED,
  },
  {
    id: "kb_act_02",
    slug: "trial-license-limits",
    category: "activation",
    title: "Trial license limits and expiry",
    summary: "Trials are time-bound and device-limited.",
    body: "Trial keys expire per plan interval. Upgrade via Billing before expiry to keep access. Activation is commercial metadata only.",
    tags: ["trial", "license"],
    views: 22,
    helpful: 9,
    updatedAt: UPDATED,
  },
  {
    id: "kb_sub_02",
    slug: "cancel-subscription",
    category: "subscription",
    title: "Cancel a subscription",
    summary: "Stop renewal while retaining access until period end.",
    body: "Portal → Subscriptions → Cancel. Confirm provider webhook processed. Refunds follow Refund Policy and PSP rules.",
    tags: ["cancel", "billing"],
    views: 16,
    helpful: 6,
    updatedAt: UPDATED,
  },
  {
    id: "kb_sub_03",
    slug: "upgrade-plan",
    category: "subscription",
    title: "Upgrade monthly to yearly or lifetime",
    summary: "Change plans from Billing Center.",
    body: "Choose a higher plan in Pricing/Billing. Proration depends on PaymentPort provider. License entitlements update after successful payment event.",
    tags: ["upgrade", "plans"],
    views: 12,
    helpful: 5,
    updatedAt: UPDATED,
  },
  {
    id: "kb_portal_02",
    slug: "download-center",
    category: "portal_usage",
    title: "Using the Download Center",
    summary: "Select channel packages and verify signatures.",
    body: "Portal → Downloads lists published Professional packages. Prefer Stable for production machines; RC for Controlled Launch testers.",
    tags: ["downloads"],
    views: 20,
    helpful: 8,
    updatedAt: UPDATED,
  },
  {
    id: "kb_upd_02",
    slug: "rollback-update",
    category: "auto_update",
    title: "Roll back to a previous package",
    summary: "Reinstall the prior channel build if an update misbehaves.",
    body: "Download the previous version from Updates history when available. Close MT5, replace package, re-verify checksum. Report the issue via Support.",
    tags: ["rollback", "updates"],
    views: 11,
    helpful: 4,
    updatedAt: UPDATED,
  },
  {
    id: "kb_mt5_02",
    slug: "algo-trading-permission",
    category: "mt5_integration",
    title: "Enable Algo Trading in MT5",
    summary: "Allow the EA to manage its Magic Number trades.",
    body: "Toolbar AutoTrading must be on. Check Tools → Options → Expert Advisors. The EA only manages its own Magic Number.",
    tags: ["mt5", "autotrading"],
    views: 35,
    helpful: 14,
    updatedAt: UPDATED,
  },
  {
    id: "kb_broker_02",
    slug: "symbol-mapping-gold",
    category: "broker_setup",
    title: "Gold symbol mapping differences",
    summary: "Brokers may use XAUUSD, GOLD, or suffixes.",
    body: "Set symbol override in inputs if your broker uses a non-standard name. Confirm contract size and stops level with the broker — commercial portal does not set broker symbols.",
    tags: ["symbol", "gold"],
    views: 17,
    helpful: 7,
    updatedAt: UPDATED,
  },
  {
    id: "kb_xfer_02",
    slug: "license-seat-exhausted",
    category: "license_transfer",
    title: "Device seats exhausted",
    summary: "Free a seat or upgrade plan limits.",
    body: "Deactivate unused devices first. If seats remain full, contact Support with license email. Do not share keys publicly.",
    tags: ["devices", "seats"],
    views: 13,
    helpful: 5,
    updatedAt: UPDATED,
  },
  {
    id: "kb_faq_03",
    slug: "faq-website-vs-market",
    category: "faq",
    title: "FAQ: Website Professional vs MQL5 Market",
    summary: "Same certified Core; different licensing and packaging.",
    body: "Website Edition uses Portal licensing and PaymentPort. Market Edition uses MQL5 Market licensing only. Trading Core SHA is shared and frozen.",
    tags: ["editions", "faq"],
    views: 40,
    helpful: 18,
    updatedAt: UPDATED,
  },
];

const viewBoost = new Map<string, number>();

export function listKbArticles(filter?: { category?: KbCategory; q?: string }) {
  let rows = KB_ARTICLES.map((a) => ({
    ...a,
    views: a.views + (viewBoost.get(a.id) || 0),
  }));
  if (filter?.category) rows = rows.filter((a) => a.category === filter.category);
  if (filter?.q) {
    const q = filter.q.toLowerCase();
    rows = rows.filter(
      (a) =>
        a.title.toLowerCase().includes(q) ||
        a.summary.toLowerCase().includes(q) ||
        a.tags.some((t) => t.includes(q)) ||
        a.category.includes(q)
    );
  }
  return rows.sort((a, b) => b.views - a.views);
}

export function getKbArticle(slug: string): KbArticle | null {
  const a = KB_ARTICLES.find((x) => x.slug === slug);
  if (!a) return null;
  return { ...a, views: a.views + (viewBoost.get(a.id) || 0) };
}

export function markKbView(slug: string): void {
  const a = KB_ARTICLES.find((x) => x.slug === slug);
  if (!a) return;
  viewBoost.set(a.id, (viewBoost.get(a.id) || 0) + 1);
}

export function suggestKbForTicket(subject: string, body: string): KbArticle[] {
  const text = `${subject} ${body}`.toLowerCase();
  const scored = listKbArticles().map((a) => {
    let score = 0;
    for (const t of a.tags) if (text.includes(t)) score += 2;
    if (text.includes(a.category.replace("_", " "))) score += 1;
    if (text.includes("activat")) score += a.category === "activation" ? 3 : 0;
    if (text.includes("install")) score += a.category === "installation" ? 3 : 0;
    if (text.includes("update")) score += a.category === "auto_update" ? 3 : 0;
    return { a, score };
  });
  return scored
    .filter((x) => x.score > 0)
    .sort((x, y) => y.score - x.score)
    .slice(0, 3)
    .map((x) => x.a);
}

export function getKbStats() {
  const articles = listKbArticles();
  const byCategory = {} as Record<KbCategory, number>;
  for (const c of Object.keys(KB_CATEGORY_LABELS) as KbCategory[]) byCategory[c] = 0;
  for (const a of articles) byCategory[a.category] += 1;
  return {
    totalArticles: articles.length,
    totalViews: articles.reduce((s, a) => s + a.views, 0),
    byCategory,
    categoriesCovered: Object.values(byCategory).filter((n) => n > 0).length,
  };
}
