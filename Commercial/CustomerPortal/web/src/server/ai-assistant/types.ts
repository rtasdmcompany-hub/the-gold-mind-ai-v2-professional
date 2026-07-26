/**
 * Enterprise AI Customer Assistant — commercial support only.
 * NEVER generates trading signals, orders, or Core access.
 */
export type AiSurface =
  | "website"
  | "customer_portal"
  | "partner_portal"
  | "admin_portal"
  | "mobile"
  | "support_center";

export type AiRole = "anonymous" | "customer" | "partner" | "admin" | "support";

export type KnowledgeCategory =
  | "documentation"
  | "faq"
  | "installation"
  | "licensing"
  | "billing"
  | "support"
  | "release_notes"
  | "troubleshooting"
  | "known_issues"
  | "policy";

export type EscalationPriority = "low" | "normal" | "high" | "urgent";

export type MessageRole = "user" | "assistant" | "system" | "agent";

export interface KnowledgeDocument {
  id: string;
  title: string;
  category: KnowledgeCategory;
  tags: string[];
  body: string;
  updatedAt: string;
  /** Precomputed bag-of-words for semantic-lite retrieval */
  tokens: string[];
}

export interface RetrievalHit {
  documentId: string;
  title: string;
  category: KnowledgeCategory;
  score: number;
  snippet: string;
}

export interface ConversationMessage {
  id: string;
  role: MessageRole;
  content: string;
  at: string;
  citations?: RetrievalHit[];
  confidence?: number;
  redacted?: boolean;
  blocked?: boolean;
  blockReason?: string;
}

export interface Conversation {
  id: string;
  surface: AiSurface;
  role: AiRole;
  customerEmail?: string;
  locale: string;
  createdAt: string;
  updatedAt: string;
  status: "open" | "escalated" | "resolved" | "closed";
  messages: ConversationMessage[];
  escalation?: EscalationRecord;
  satisfaction?: number;
  feedbackNote?: string;
}

export interface EscalationRecord {
  id: string;
  conversationId: string;
  reason: "low_confidence" | "user_request" | "policy" | "trading_probe" | "unanswered";
  priority: EscalationPriority;
  ticketId?: string;
  handedOverAt: string;
  agentNote?: string;
}

export interface AiFeedback {
  id: string;
  conversationId: string;
  messageId?: string;
  rating: 1 | 2 | 3 | 4 | 5;
  comment?: string;
  at: string;
  customerEmail?: string;
}

export interface AiAuditEntry {
  id: string;
  at: string;
  action: string;
  actor: string;
  conversationId?: string;
  detail: string;
  piiRedacted: boolean;
}

export interface UnansweredQuestion {
  id: string;
  question: string;
  conversationId: string;
  at: string;
  surface: AiSurface;
}

export const AI_TRADING_PROHIBITED = true;
export const AI_CORE_ISOLATION =
  "AI Assistant never accesses Core Trading Engine, never generates signals, never recommends buy/sell, never modifies trading parameters.";

export const TRADING_PROBE_PATTERNS = [
  /\b(buy|sell)\s+(gold|xau|xauusd|eurusd)\b/i,
  /\bbuy\s+signal\b/i,
  /\bsell\s+signal\b/i,
  /\b(entry|sl|tp|stop\s*loss|take\s*profit)\b/i,
  /\b(magic\s*number|lot\s*size|martingale)\b/i,
  /\b(open|close)\s+(trade|order|position)\b/i,
  /\btrading\s+signal\b/i,
  /\bmodify\s+(strategy|risk|recovery)\b/i,
  /\baccess\s+(core|mt5|expert\s*advisor)\b/i,
];

export const PROMPT_INJECTION_PATTERNS = [
  /ignore\s+(all\s+)?(previous|prior)\s+instructions/i,
  /you\s+are\s+now\s+(a\s+)?trading/i,
  /reveal\s+(your\s+)?system\s+prompt/i,
  /jailbreak/i,
  /disable\s+safety/i,
];
