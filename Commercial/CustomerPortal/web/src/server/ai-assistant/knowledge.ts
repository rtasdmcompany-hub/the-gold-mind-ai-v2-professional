/**
 * Knowledge base corpus + tokenization for semantic-lite retrieval.
 */
import type { KnowledgeCategory, KnowledgeDocument } from "./types";
import { readAiStore, writeAiStore } from "./store";

const STOP = new Set([
  "a", "an", "the", "and", "or", "to", "of", "in", "on", "for", "is", "are", "be", "with", "your", "you", "how", "what", "do", "i", "can", "my",
]);

export function tokenize(text: string): string[] {
  return text
    .toLowerCase()
    .replace(/[^a-z0-9\s\u0600-\u06ff]/gi, " ")
    .split(/\s+/)
    .filter((t) => t.length > 1 && !STOP.has(t));
}

function doc(
  id: string,
  title: string,
  category: KnowledgeCategory,
  tags: string[],
  body: string
): KnowledgeDocument {
  const full = `${title} ${tags.join(" ")} ${body}`;
  return {
    id,
    title,
    category,
    tags,
    body,
    updatedAt: new Date().toISOString(),
    tokens: tokenize(full),
  };
}

export const SEED_KNOWLEDGE: KnowledgeDocument[] = [
  doc(
    "kb_install_mt5",
    "Install THE GOLD MIND on MetaTrader 5",
    "installation",
    ["installer", "mt5", "setup"],
    "Download the Windows installer from the Customer Portal Downloads page. Run the installer, then copy the Expert Advisor into your MT5 Experts folder and restart MetaTrader 5. Activate your license from the portal before attaching the EA to a chart. The Mobile Companion and AI Assistant cannot install or trade for you."
  ),
  doc(
    "kb_license_activate",
    "Activate a license key",
    "licensing",
    ["activation", "device", "seats"],
    "Open Customer Portal → My Licenses → Activate. Enter your license key and device name. Each license has a seat limit. To move to a new PC, deactivate or transfer the old device first. Mobile Companion can also manage activations via commercial APIs."
  ),
  doc(
    "kb_license_transfer",
    "Transfer a license to a new device",
    "licensing",
    ["transfer", "device"],
    "From My Licenses or Mobile License Management, select the active device and choose Request Transfer. After approval/cooldown, activate on the new machine with the same key. Do not share keys publicly."
  ),
  doc(
    "kb_billing_renew",
    "Subscription renewal and invoices",
    "billing",
    ["renewal", "invoice", "payment"],
    "Yearly and monthly plans renew automatically unless cancelled. Invoices appear under Billing in the Customer Portal. Payment confirmations are emailed and may appear as push notifications on Mobile Companion."
  ),
  doc(
    "kb_payment_methods",
    "Payment questions",
    "billing",
    ["payment", "card", "checkout"],
    "Checkout uses the commercial Payment Port (sandbox or live). Failed payments leave the subscription in grace where configured. Contact support with the invoice ID — never send full card numbers in chat."
  ),
  doc(
    "kb_portal_nav",
    "Customer Portal navigation",
    "documentation",
    ["portal", "navigation"],
    "Use Dashboard for overview, Licenses for keys and devices, Downloads for installers, Billing for invoices, and Support for tickets. Partners use the Partner Portal for referrals and commissions."
  ),
  doc(
    "kb_account_recovery",
    "Account recovery",
    "support",
    ["password", "recovery", "2fa"],
    "Use Forgot Password on the login page. If 2FA blocks access on Mobile Companion, use a trusted device or contact support with account email. Admins can assist with account recovery — they cannot reset trading passwords inside MT5."
  ),
  doc(
    "kb_updates",
    "Software updates",
    "release_notes",
    ["updater", "version"],
    "The commercial updater checks Stable/RC channels. Installer and updater strings are localized. Core Trading Engine updates follow certified release processes and are separate from portal/mobile releases."
  ),
  doc(
    "kb_troubleshoot_activation",
    "Troubleshooting license activation failures",
    "troubleshooting",
    ["error", "activation"],
    "Common causes: wrong email, seat limit reached, revoked/expired key, or offline validation. Confirm portal email matches the license, free a seat, then retry. Check Support Center Known Issues for outages."
  ),
  doc(
    "kb_known_issues",
    "Known issues",
    "known_issues",
    ["status", "outage"],
    "If commercial APIs are under maintenance, dashboards show announcements. Trading on MT5 is independent of portal downtime. Mobile Companion will not place trades during any outage."
  ),
  doc(
    "kb_policy_privacy",
    "Privacy and AI conversation policy",
    "policy",
    ["privacy", "pii", "ai"],
    "AI conversations are encrypted at rest, audited, and may redact PII. Prompts that ask for trading signals are refused. Do not paste passwords, full PANs, or government IDs into chat."
  ),
  doc(
    "kb_faq_trading",
    "Can the AI or Mobile app trade for me?",
    "faq",
    ["trading", "forbidden"],
    "No. THE GOLD MIND AI Assistant and Mobile Companion are commercial support tools only. All trading remains exclusively inside the certified MT5 Professional Core Trading Engine. The assistant never generates buy/sell advice."
  ),
  doc(
    "kb_partner",
    "Partner portal basics",
    "documentation",
    ["partner", "affiliate"],
    "Partners apply at /partners/apply, then track referrals and commissions in the Partner Portal. Commission rules are config-driven and require verified attribution."
  ),
  doc(
    "kb_support_ticket",
    "Create a support ticket",
    "support",
    ["ticket", "escalation"],
    "Open Support Center → New Ticket, or ask the AI Assistant to escalate. Low-confidence answers automatically offer human handover. Attach diagnostic reports from Mobile Companion when relevant."
  ),
  doc(
    "kb_release_notes_s7",
    "Phase 11 Sprint 7 — AI Assistant",
    "release_notes",
    ["phase11", "ai"],
    "Enterprise AI Customer Assistant adds knowledge retrieval, escalation, analytics, and multi-surface integration. Trading capabilities are explicitly out of scope."
  ),
];

export function ensureKnowledgeIndexed(): KnowledgeDocument[] {
  const store = readAiStore();
  if (store.knowledge.length >= SEED_KNOWLEDGE.length) return store.knowledge;
  const byId = new Map(store.knowledge.map((k) => [k.id, k]));
  for (const d of SEED_KNOWLEDGE) {
    if (!byId.has(d.id)) store.knowledge.push(d);
  }
  writeAiStore(store);
  return store.knowledge;
}

export function listKnowledge(category?: KnowledgeCategory): KnowledgeDocument[] {
  const docs = ensureKnowledgeIndexed();
  return category ? docs.filter((d) => d.category === category) : docs;
}

export function knowledgeCoverageReport() {
  const docs = ensureKnowledgeIndexed();
  const byCat: Record<string, number> = {};
  for (const d of docs) byCat[d.category] = (byCat[d.category] || 0) + 1;
  const required: KnowledgeCategory[] = [
    "documentation",
    "faq",
    "installation",
    "licensing",
    "billing",
    "support",
    "release_notes",
    "troubleshooting",
    "known_issues",
    "policy",
  ];
  const missing = required.filter((c) => !byCat[c]);
  return {
    total: docs.length,
    byCategory: byCat,
    requiredCovered: required.length - missing.length,
    requiredTotal: required.length,
    missingCategories: missing,
    score:
      missing.length === 0
        ? 96
        : Math.round(((required.length - missing.length) / required.length) * 100),
  };
}
