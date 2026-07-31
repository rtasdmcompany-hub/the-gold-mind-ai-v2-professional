/**
 * AI Gateway — single entry for surfaces with policy envelope.
 */
import { startConversation, askAssistant, getConversation, requestHumanHandover } from "./conversation";
import { collectSatisfaction } from "./escalation";
import { ensureKnowledgeIndexed, listKnowledge } from "./knowledge";
import { semanticRetrieve } from "./retrieval";
import { securityPolicySummary } from "./security";
import type { AiRole, AiSurface } from "./types";
import { AI_CORE_ISOLATION, AI_TRADING_PROHIBITED } from "./types";
import { brand } from "@/lib/brand";
import { product } from "@/lib/product";

export function aiGatewayInfo() {
  return {
    name: `${brand.brandName} Enterprise AI Gateway`,
    version: product.version,
    surfaces: [
      "website",
      "customer_portal",
      "partner_portal",
      "admin_portal",
      "mobile",
      "support_center",
    ] as AiSurface[],
    tradingProhibited: AI_TRADING_PROHIBITED,
    coreIsolation: AI_CORE_ISOLATION,
    security: securityPolicySummary(),
    endpoints: {
      chat: "/api/ai/chat",
      search: "/api/ai/search",
      admin: "/api/admin/ai",
    },
  };
}

export function gatewayStart(input: {
  surface: AiSurface;
  role: AiRole;
  customerEmail?: string;
  locale?: string;
}) {
  ensureKnowledgeIndexed();
  return startConversation(input);
}

export function gatewayAsk(input: {
  conversationId: string;
  message: string;
  escalateIfLow?: boolean;
  actor?: string;
}) {
  return askAssistant(input);
}

export function gatewaySearch(query: string, limit = 5) {
  return semanticRetrieve(query, limit);
}

export function gatewayEscalate(conversationId: string, note?: string) {
  return requestHumanHandover(conversationId, note);
}

export function gatewayFeedback(conversationId: string, rating: 1 | 2 | 3 | 4 | 5, note?: string) {
  return collectSatisfaction(conversationId, rating, note);
}

export function gatewayGet(conversationId: string) {
  return getConversation(conversationId);
}

export function gatewayKnowledgeCatalog() {
  return listKnowledge().map((d) => ({
    id: d.id,
    title: d.title,
    category: d.category,
    tags: d.tags,
  }));
}
