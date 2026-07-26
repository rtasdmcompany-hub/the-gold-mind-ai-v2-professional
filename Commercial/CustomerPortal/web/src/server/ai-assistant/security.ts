/**
 * AI security — authz, rate limits, PII redaction, prompt injection, trading refusal.
 */
import {
  AI_CORE_ISOLATION,
  AI_TRADING_PROHIBITED,
  PROMPT_INJECTION_PATTERNS,
  TRADING_PROBE_PATTERNS,
  type AiRole,
} from "./types";
import { appendAiAudit, readAiStore, writeAiStore } from "./store";

const RATE_LIMIT = 40;
const RATE_WINDOW_MS = 60_000;

export function redactPii(text: string): { text: string; redacted: boolean } {
  let out = text;
  let redacted = false;
  const patterns = [
    /\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b/gi,
    /\b(?:\d[ -]*?){13,19}\b/g,
    /\b(?:password|passwd|pwd)\s*[:=]\s*\S+/gi,
    /\bTGM-[A-Z0-9-]{8,}\b/gi,
  ];
  for (const p of patterns) {
    if (p.test(out)) {
      redacted = true;
      out = out.replace(p, "[REDACTED]");
    }
  }
  return { text: out, redacted };
}

export function detectTradingProbe(text: string): boolean {
  return TRADING_PROBE_PATTERNS.some((p) => p.test(text));
}

export function detectPromptInjection(text: string): boolean {
  return PROMPT_INJECTION_PATTERNS.some((p) => p.test(text));
}

export function checkRateLimit(bucketKey: string): { ok: boolean; remaining: number } {
  const store = readAiStore();
  const now = Date.now();
  let b = store.rateBuckets[bucketKey];
  if (!b || now - b.windowStart > RATE_WINDOW_MS) {
    b = { count: 0, windowStart: now };
  }
  b.count += 1;
  store.rateBuckets[bucketKey] = b;
  writeAiStore(store);
  return { ok: b.count <= RATE_LIMIT, remaining: Math.max(0, RATE_LIMIT - b.count) };
}

export function roleMayUseSurface(role: AiRole, surface: string): boolean {
  if (surface === "admin_portal") return role === "admin" || role === "support";
  if (surface === "partner_portal") return role === "partner" || role === "admin";
  return true;
}

export function tradingRefusalMessage(): string {
  return (
    "I can’t help with trading signals, buy/sell decisions, strategy changes, or Core Trading Engine access. " +
    "I only assist with licensing, billing, installation, portal navigation, and product support. " +
    AI_CORE_ISOLATION
  );
}

export function injectionRefusalMessage(): string {
  return "That request looks like an attempt to override assistant safety rules. Please ask a product support question instead.";
}

export function logPromptPolicy(actor: string, conversationId: string, detail: string) {
  appendAiAudit({
    action: "prompt_policy",
    actor,
    conversationId,
    detail: redactPii(detail).text.slice(0, 500),
    piiRedacted: true,
  });
}

export function securityPolicySummary() {
  return {
    tradingProhibited: AI_TRADING_PROHIBITED,
    coreIsolation: AI_CORE_ISOLATION,
    authenticatedAccess: true,
    roleBasedPermissions: true,
    conversationEncryption: "AES-256-GCM at rest",
    auditLogs: true,
    piiProtection: true,
    rateLimiting: `${RATE_LIMIT}/min per bucket`,
    promptInjectionMitigation: true,
    promptLoggingPolicy: "Store redacted audit excerpts only — never raw secrets",
  };
}
