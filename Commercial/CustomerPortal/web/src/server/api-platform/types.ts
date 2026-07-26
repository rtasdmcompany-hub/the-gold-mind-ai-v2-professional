/**
 * Enterprise API Platform types — commercial integrations only.
 * Core Trading Engine is NEVER exposed.
 */
export type ApiScope =
  | "profile:read"
  | "licenses:read"
  | "licenses:write"
  | "subscriptions:read"
  | "invoices:read"
  | "downloads:read"
  | "notifications:read"
  | "support:read"
  | "support:write"
  | "partners:read"
  | "organizations:read"
  | "webhooks:manage";

export type WebhookEventType =
  | "license.activated"
  | "license.expired"
  | "subscription.renewed"
  | "payment.received"
  | "refund.processed"
  | "support.ticket.updated"
  | "customer.created"
  | "partner.registered";

export interface ApiKeyRecord {
  id: string;
  name: string;
  ownerEmail: string;
  /** SHA-256 of secret — secret shown once at creation */
  keyHash: string;
  keyPrefix: string;
  scopes: ApiScope[];
  createdAt: string;
  lastUsedAt?: string;
  revokedAt?: string;
  rotatedFromId?: string;
  ipAllowlist: string[];
  rateLimitPerMin: number;
}

export interface OAuthTokenRecord {
  id: string;
  apiKeyId: string;
  ownerEmail: string;
  accessTokenHash: string;
  refreshTokenHash: string;
  scopes: ApiScope[];
  expiresAt: string;
  refreshExpiresAt: string;
  createdAt: string;
  revokedAt?: string;
}

export interface WebhookEndpoint {
  id: string;
  ownerEmail: string;
  url: string;
  secret: string;
  events: WebhookEventType[];
  active: boolean;
  createdAt: string;
  failureCount: number;
}

export interface WebhookDelivery {
  id: string;
  endpointId: string;
  event: WebhookEventType;
  payloadHash: string;
  status: "pending" | "delivered" | "failed" | "retrying";
  attempts: number;
  nextRetryAt?: string;
  lastError?: string;
  createdAt: string;
  deliveredAt?: string;
  signature: string;
}

export interface ApiUsageEvent {
  id: string;
  at: string;
  apiKeyId?: string;
  ownerEmail?: string;
  method: string;
  path: string;
  status: number;
  requestId: string;
  ip: string;
  latencyMs: number;
  errorCode?: string;
}

export interface ApiErrorEvent {
  id: string;
  at: string;
  code: string;
  path: string;
  requestId: string;
  detail: string;
}

export const ALL_COMMERCIAL_SCOPES: ApiScope[] = [
  "profile:read",
  "licenses:read",
  "licenses:write",
  "subscriptions:read",
  "invoices:read",
  "downloads:read",
  "notifications:read",
  "support:read",
  "support:write",
  "partners:read",
  "organizations:read",
  "webhooks:manage",
];

/** Paths / topics that must never be served by the Public API */
export const FORBIDDEN_API_TOPICS = [
  "trading",
  "orders",
  "signals",
  "strategy",
  "risk-engine",
  "magic-number",
  "recovery",
  "core-engine",
  "execute-trade",
] as const;

export const API_CORE_ISOLATION =
  "Public API never exposes trading execution, strategy, risk engine, order management, trading calculations, or internal Core services.";

export const API_PLATFORM_VERSION = "v1";
