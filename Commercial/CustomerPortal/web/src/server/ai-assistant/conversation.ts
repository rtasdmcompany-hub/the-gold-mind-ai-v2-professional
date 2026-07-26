/**
 * Conversation engine — context, history, grounded answers, capability routing.
 */
import { newAiId, readAiStore, writeAiStore, appendAiAudit } from "./store";
import { semanticRetrieve } from "./retrieval";
import { ensureKnowledgeIndexed } from "./knowledge";
import {
  checkRateLimit,
  detectPromptInjection,
  detectTradingProbe,
  injectionRefusalMessage,
  logPromptPolicy,
  redactPii,
  roleMayUseSurface,
  tradingRefusalMessage,
} from "./security";
import { escalateConversation } from "./escalation";
import type { AiRole, AiSurface, Conversation, ConversationMessage } from "./types";
import { AI_CORE_ISOLATION } from "./types";

const LOW_CONFIDENCE = 0.18;

export function startConversation(input: {
  surface: AiSurface;
  role: AiRole;
  customerEmail?: string;
  locale?: string;
}): Conversation {
  if (!roleMayUseSurface(input.role, input.surface)) throw new Error("FORBIDDEN_SURFACE");
  ensureKnowledgeIndexed();
  const store = readAiStore();
  const now = new Date().toISOString();
  const conv: Conversation = {
    id: newAiId("conv"),
    surface: input.surface,
    role: input.role,
    customerEmail: input.customerEmail?.toLowerCase(),
    locale: input.locale || "en",
    createdAt: now,
    updatedAt: now,
    status: "open",
    messages: [
      {
        id: newAiId("msg"),
        role: "assistant",
        content:
          "Hi — I’m the THE GOLD MIND Customer Assistant. I can help with installation, licensing, billing, portal navigation, updates, and troubleshooting. I cannot provide trading advice or access the Core Trading Engine.",
        at: now,
        confidence: 1,
      },
    ],
  };
  store.conversations.unshift(conv);
  writeAiStore(store);
  appendAiAudit({
    action: "conversation_start",
    actor: conv.customerEmail || "anonymous",
    conversationId: conv.id,
    detail: `${input.surface}/${input.role}`,
    piiRedacted: true,
  });
  return conv;
}

function capabilityHint(query: string): string | null {
  const q = query.toLowerCase();
  if (/install|setup|mt5|expert/.test(q)) return "installation";
  if (/license|activat|transfer|seat|device/.test(q)) return "licensing";
  if (/subscri|renew|invoice|bill|payment|pay/.test(q)) return "billing";
  if (/portal|navigat|dashboard|download/.test(q)) return "portal";
  if (/password|recover|locked|2fa|account/.test(q)) return "account_recovery";
  if (/update|version|release|updater/.test(q)) return "updates";
  if (/error|fail|troubleshoot|not work|issue/.test(q)) return "troubleshooting";
  if (/partner|affiliate|commission/.test(q)) return "partner";
  if (/doc|guide|faq|policy|privacy/.test(q)) return "documentation";
  return null;
}

function composeAnswer(query: string, hits: ReturnType<typeof semanticRetrieve>): {
  content: string;
  confidence: number;
} {
  if (hits.length === 0) {
    return {
      content:
        "I don’t have a confident answer in the knowledge base yet. I can escalate this to a human agent or you can browse the Support Center. Reminder: I only handle commercial support — not trading decisions.",
      confidence: 0.05,
    };
  }
  const top = hits[0];
  const capability = capabilityHint(query);
  const lead = capability
    ? `Here’s help with ${capability.replace("_", " ")}:\n\n`
    : "Based on our product docs:\n\n";
  const cites = hits.map((h, i) => `${i + 1}. ${h.title}`).join("\n");
  const content = `${lead}${top.snippet}\n\nSources:\n${cites}\n\n${AI_CORE_ISOLATION}`;
  const confidence = Math.min(0.98, Math.max(top.score, hits.reduce((a, h) => a + h.score, 0) / hits.length));
  return { content, confidence };
}

export function askAssistant(input: {
  conversationId: string;
  message: string;
  escalateIfLow?: boolean;
  actor?: string;
}): {
  conversation: Conversation;
  reply: ConversationMessage;
  escalated?: boolean;
} {
  const store = readAiStore();
  const conv = store.conversations.find((c) => c.id === input.conversationId);
  if (!conv) throw new Error("CONVERSATION_NOT_FOUND");
  if (conv.status === "closed") throw new Error("CONVERSATION_CLOSED");

  const bucket = `${conv.customerEmail || "anon"}:${conv.surface}`;
  const rl = checkRateLimit(bucket);
  if (!rl.ok) throw new Error("RATE_LIMITED");

  const { text: safeUser, redacted } = redactPii(input.message);
  const now = new Date().toISOString();

  const userMsg: ConversationMessage = {
    id: newAiId("msg"),
    role: "user",
    content: safeUser,
    at: now,
    redacted,
  };
  conv.messages.push(userMsg);

  // Guardrails
  if (detectPromptInjection(safeUser)) {
    logPromptPolicy(input.actor || conv.customerEmail || "anonymous", conv.id, "injection_blocked");
    const reply: ConversationMessage = {
      id: newAiId("msg"),
      role: "assistant",
      content: injectionRefusalMessage(),
      at: new Date().toISOString(),
      confidence: 1,
      blocked: true,
      blockReason: "prompt_injection",
    };
    conv.messages.push(reply);
    conv.updatedAt = reply.at;
    writeAiStore(store);
    return { conversation: conv, reply };
  }

  if (detectTradingProbe(safeUser)) {
    logPromptPolicy(input.actor || conv.customerEmail || "anonymous", conv.id, "trading_probe_blocked");
    const reply: ConversationMessage = {
      id: newAiId("msg"),
      role: "assistant",
      content: tradingRefusalMessage(),
      at: new Date().toISOString(),
      confidence: 1,
      blocked: true,
      blockReason: "trading_prohibited",
    };
    conv.messages.push(reply);
    conv.updatedAt = reply.at;
    writeAiStore(store);
    // Auto-escalate trading probes as policy events (optional human review)
    escalateConversation({ conversation: conv, reason: "trading_probe", userText: safeUser });
    const refreshed = readAiStore().conversations.find((c) => c.id === conv.id)!;
    return { conversation: refreshed, reply, escalated: true };
  }

  const hits = semanticRetrieve(safeUser, 4);
  const { content, confidence } = composeAnswer(safeUser, hits);
  const reply: ConversationMessage = {
    id: newAiId("msg"),
    role: "assistant",
    content,
    at: new Date().toISOString(),
    citations: hits,
    confidence,
  };
  conv.messages.push(reply);
  conv.updatedAt = reply.at;

  let escalated = false;
  if (confidence < LOW_CONFIDENCE) {
    store.unanswered.unshift({
      id: newAiId("uq"),
      question: safeUser.slice(0, 500),
      conversationId: conv.id,
      at: now,
      surface: conv.surface,
    });
    if (input.escalateIfLow !== false) {
      writeAiStore(store);
      escalateConversation({ conversation: conv, reason: "low_confidence", userText: safeUser });
      escalated = true;
      const refreshed = readAiStore().conversations.find((c) => c.id === conv.id)!;
      return { conversation: refreshed, reply, escalated };
    }
  }

  writeAiStore(store);
  appendAiAudit({
    action: "assistant_reply",
    actor: input.actor || conv.customerEmail || "anonymous",
    conversationId: conv.id,
    detail: `confidence=${confidence.toFixed(3)} cites=${hits.length}`,
    piiRedacted: true,
  });
  return { conversation: conv, reply, escalated };
}

export function getConversation(id: string): Conversation | null {
  return readAiStore().conversations.find((c) => c.id === id) || null;
}

export function listConversations(filter?: { email?: string; surface?: AiSurface }) {
  let rows = readAiStore().conversations;
  const email = filter?.email;
  if (email) rows = rows.filter((c) => c.customerEmail === email.toLowerCase());
  if (filter?.surface) rows = rows.filter((c) => c.surface === filter.surface);
  return rows.slice(0, 100);
}

export function requestHumanHandover(conversationId: string, note?: string) {
  const conv = getConversation(conversationId);
  if (!conv) throw new Error("CONVERSATION_NOT_FOUND");
  return escalateConversation({
    conversation: conv,
    reason: "user_request",
    userText: note || "Customer requested human agent",
  });
}
