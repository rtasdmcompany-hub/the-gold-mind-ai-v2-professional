/**
 * Escalation — low confidence, human handover, tickets, CSAT.
 */
import { newAiId, readAiStore, writeAiStore, appendAiAudit } from "./store";
import type { Conversation, EscalationPriority, EscalationRecord } from "./types";

export function classifyPriority(reason: EscalationRecord["reason"], text: string): EscalationPriority {
  if (reason === "trading_probe") return "high";
  if (/urgent|asap|cannot access|locked out|payment failed/i.test(text)) return "high";
  if (reason === "low_confidence" || reason === "unanswered") return "normal";
  return "low";
}

export function escalateConversation(input: {
  conversation: Conversation;
  reason: EscalationRecord["reason"];
  userText: string;
}): EscalationRecord {
  const store = readAiStore();
  const conv = store.conversations.find((c) => c.id === input.conversation.id);
  if (!conv) throw new Error("CONVERSATION_NOT_FOUND");

  const priority = classifyPriority(input.reason, input.userText);
  const ticketId = `tkt_${Date.now().toString(36)}`;
  const escalation: EscalationRecord = {
    id: newAiId("esc"),
    conversationId: conv.id,
    reason: input.reason,
    priority,
    ticketId,
    handedOverAt: new Date().toISOString(),
    agentNote: "Queued for human agent — AI context attached",
  };
  conv.status = "escalated";
  conv.escalation = escalation;
  conv.updatedAt = new Date().toISOString();
  conv.messages.push({
    id: newAiId("msg"),
    role: "system",
    content: `Escalated to human support (ticket ${ticketId}, priority ${priority}).`,
    at: new Date().toISOString(),
  });
  writeAiStore(store);
  appendAiAudit({
    action: "escalation",
    actor: conv.customerEmail || "anonymous",
    conversationId: conv.id,
    detail: `${input.reason} → ${ticketId} (${priority})`,
    piiRedacted: true,
  });
  return escalation;
}

export function collectSatisfaction(conversationId: string, rating: 1 | 2 | 3 | 4 | 5, note?: string) {
  const store = readAiStore();
  const conv = store.conversations.find((c) => c.id === conversationId);
  if (!conv) throw new Error("CONVERSATION_NOT_FOUND");
  conv.satisfaction = rating;
  conv.feedbackNote = note;
  if (conv.status === "open" || conv.status === "escalated") conv.status = "resolved";
  conv.updatedAt = new Date().toISOString();
  store.feedback.unshift({
    id: newAiId("fb"),
    conversationId,
    rating,
    comment: note,
    at: new Date().toISOString(),
    customerEmail: conv.customerEmail,
  });
  writeAiStore(store);
  return { conversationId, rating };
}
