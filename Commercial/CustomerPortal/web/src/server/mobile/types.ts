/**
 * Mobile Companion types — commercial customer management only.
 * NEVER includes trading logic or Core Trading Engine hooks.
 */
export type MobilePlatform = "android" | "ios" | "web";

export type PushCategory =
  | "license_expiry"
  | "subscription_renewal"
  | "payment_confirmation"
  | "software_update"
  | "maintenance"
  | "security_alert"
  | "support_reply"
  | "marketing";

export interface MobileDevice {
  id: string;
  customerEmail: string;
  platform: MobilePlatform;
  deviceName: string;
  model: string;
  osVersion: string;
  appVersion: string;
  pushToken?: string;
  fingerprintHash: string;
  trusted: boolean;
  integrityOk: boolean;
  biometricEnabled: boolean;
  registeredAt: string;
  lastSeenAt: string;
  revokedAt?: string;
}

export interface MobileSession {
  id: string;
  customerEmail: string;
  deviceId: string;
  accessTokenHash: string;
  refreshTokenHash: string;
  expiresAt: string;
  refreshExpiresAt: string;
  createdAt: string;
  revokedAt?: string;
  twoFactorVerified: boolean;
  authMethods: ("email" | "google" | "2fa" | "biometric")[];
}

export interface TrustedDevice {
  deviceId: string;
  customerEmail: string;
  labeledAt: string;
  label: string;
}

export interface PushPreference {
  customerEmail: string;
  categories: Record<PushCategory, boolean>;
  updatedAt: string;
}

export interface PushMessage {
  id: string;
  customerEmail: string;
  category: PushCategory;
  title: string;
  body: string;
  deepLink?: string;
  createdAt: string;
  deliveredAt?: string;
  readAt?: string;
}

export interface SupportTicketMobile {
  id: string;
  customerEmail: string;
  subject: string;
  status: "open" | "pending" | "closed";
  channel: "ticket" | "chat_placeholder" | "ai_entry";
  createdAt: string;
  updatedAt: string;
}

export interface DiagnosticReport {
  id: string;
  customerEmail: string;
  deviceId: string;
  appVersion: string;
  platform: MobilePlatform;
  payloadSummary: string;
  submittedAt: string;
}

export interface OfflineCacheManifest {
  customerEmail: string;
  cachedAt: string;
  ttlSec: number;
  keys: string[];
}

export interface MobileAppVersion {
  platform: MobilePlatform;
  latest: string;
  minimum: string;
  forceUpdate: boolean;
  releaseNotes: string;
}

export const DEFAULT_PUSH_PREFS: Record<PushCategory, boolean> = {
  license_expiry: true,
  subscription_renewal: true,
  payment_confirmation: true,
  software_update: true,
  maintenance: true,
  security_alert: true,
  support_reply: true,
  marketing: false, // opt-in only
};

/** Hard rule — companion never executes trades */
export const MOBILE_TRADING_PROHIBITED = true;
export const MOBILE_CORE_ISOLATION =
  "Mobile Companion communicates only with commercial APIs. Trading remains exclusively in certified MT5 Professional.";
