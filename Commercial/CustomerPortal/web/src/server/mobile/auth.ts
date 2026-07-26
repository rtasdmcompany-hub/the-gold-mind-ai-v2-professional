/**
 * Mobile authentication — email, Google OAuth placeholder, 2FA, sessions, devices.
 * No trading credentials or Core access.
 */
import { createHash } from "crypto";
import {
  hashToken,
  issueOpaqueToken,
  newMobileId,
  readMobileStore,
  writeMobileStore,
} from "./store";
import type { MobileDevice, MobilePlatform, MobileSession } from "./types";

const ACCESS_TTL_SEC = 60 * 60; // 1h
const REFRESH_TTL_SEC = 60 * 60 * 24 * 30; // 30d

export interface MobileAuthResult {
  accessToken: string;
  refreshToken: string;
  expiresAt: string;
  sessionId: string;
  deviceId: string;
  requires2fa: boolean;
  twoFactorVerified: boolean;
}

function addSec(iso: string, sec: number): string {
  return new Date(new Date(iso).getTime() + sec * 1000).toISOString();
}

export function registerOrUpdateDevice(input: {
  customerEmail: string;
  platform: MobilePlatform;
  deviceName: string;
  model: string;
  osVersion: string;
  appVersion: string;
  fingerprint: string;
  pushToken?: string;
  biometricEnabled?: boolean;
}): MobileDevice {
  const store = readMobileStore();
  const email = input.customerEmail.toLowerCase();
  const fp = createHash("sha256").update(input.fingerprint).digest("hex");
  let device = store.devices.find(
    (d) => d.customerEmail === email && d.fingerprintHash === fp && !d.revokedAt
  );
  const now = new Date().toISOString();
  if (!device) {
    device = {
      id: newMobileId("mdev"),
      customerEmail: email,
      platform: input.platform,
      deviceName: input.deviceName,
      model: input.model,
      osVersion: input.osVersion,
      appVersion: input.appVersion,
      pushToken: input.pushToken,
      fingerprintHash: fp,
      trusted: false,
      integrityOk: true,
      biometricEnabled: !!input.biometricEnabled,
      registeredAt: now,
      lastSeenAt: now,
    };
    store.devices.unshift(device);
  } else {
    device.deviceName = input.deviceName;
    device.model = input.model;
    device.osVersion = input.osVersion;
    device.appVersion = input.appVersion;
    device.lastSeenAt = now;
    if (input.pushToken) device.pushToken = input.pushToken;
    if (input.biometricEnabled !== undefined) device.biometricEnabled = input.biometricEnabled;
  }
  writeMobileStore(store);
  return device;
}

export function markTrustedDevice(deviceId: string, email: string, label: string) {
  const store = readMobileStore();
  const device = store.devices.find(
    (d) => d.id === deviceId && d.customerEmail === email.toLowerCase() && !d.revokedAt
  );
  if (!device) throw new Error("DEVICE_NOT_FOUND");
  device.trusted = true;
  store.trusted = store.trusted.filter((t) => t.deviceId !== deviceId);
  store.trusted.unshift({
    deviceId,
    customerEmail: email.toLowerCase(),
    labeledAt: new Date().toISOString(),
    label,
  });
  writeMobileStore(store);
  return device;
}

/** Demo email login — validates presence; production ties to NextAuth / identity provider. */
export function mobileEmailLogin(input: {
  email: string;
  password: string;
  device: {
    platform: MobilePlatform;
    deviceName: string;
    model: string;
    osVersion: string;
    appVersion: string;
    fingerprint: string;
    pushToken?: string;
  };
  totpCode?: string;
}): MobileAuthResult {
  const email = input.email.toLowerCase().trim();
  if (!email.includes("@") || input.password.length < 6) throw new Error("INVALID_CREDENTIALS");

  const device = registerOrUpdateDevice({
    customerEmail: email,
    ...input.device,
  });

  const trusted = readMobileStore().trusted.some((t) => t.deviceId === device.id);
  const requires2fa = !trusted && !input.totpCode;
  const twoFactorVerified = trusted || verifyDemoTotp(email, input.totpCode);

  if (requires2fa && !twoFactorVerified) {
    // Issue short-lived pending session still requires 2FA before full access
    return createSession({
      email,
      deviceId: device.id,
      methods: ["email"],
      twoFactorVerified: false,
      requires2fa: true,
    });
  }

  return createSession({
    email,
    deviceId: device.id,
    methods: twoFactorVerified ? ["email", "2fa"] : ["email"],
    twoFactorVerified,
    requires2fa: false,
  });
}

export function mobileGoogleOAuthLogin(input: {
  email: string;
  googleIdToken: string;
  device: {
    platform: MobilePlatform;
    deviceName: string;
    model: string;
    osVersion: string;
    appVersion: string;
    fingerprint: string;
    pushToken?: string;
  };
}): MobileAuthResult {
  // Production: verify googleIdToken with Google JWKS. Demo accepts non-empty token.
  if (!input.googleIdToken || input.googleIdToken.length < 8) throw new Error("INVALID_GOOGLE_TOKEN");
  const email = input.email.toLowerCase().trim();
  const device = registerOrUpdateDevice({ customerEmail: email, ...input.device });
  return createSession({
    email,
    deviceId: device.id,
    methods: ["google"],
    twoFactorVerified: true,
    requires2fa: false,
  });
}

function verifyDemoTotp(email: string, code?: string): boolean {
  if (!code) return false;
  // Deterministic demo TOTP: last 6 digits of sha of email+day
  const day = new Date().toISOString().slice(0, 10);
  const expected = createHash("sha256")
    .update(`${email}:${day}:tgm-mobile-2fa`)
    .digest("hex")
    .replace(/\D/g, "")
    .slice(0, 6)
    .padStart(6, "0");
  return code === expected || code === "000000"; // 000000 allowed in non-prod demos
}

export function complete2fa(sessionId: string, email: string, totpCode: string): MobileAuthResult {
  const store = readMobileStore();
  const session = store.sessions.find(
    (s) => s.id === sessionId && s.customerEmail === email.toLowerCase() && !s.revokedAt
  );
  if (!session) throw new Error("SESSION_NOT_FOUND");
  if (!verifyDemoTotp(email, totpCode)) throw new Error("INVALID_2FA");
  session.twoFactorVerified = true;
  if (!session.authMethods.includes("2fa")) session.authMethods.push("2fa");
  writeMobileStore(store);

  // Rotate tokens after 2FA
  return createSession({
    email: session.customerEmail,
    deviceId: session.deviceId,
    methods: session.authMethods,
    twoFactorVerified: true,
    requires2fa: false,
  });
}

function createSession(input: {
  email: string;
  deviceId: string;
  methods: MobileSession["authMethods"];
  twoFactorVerified: boolean;
  requires2fa: boolean;
}): MobileAuthResult {
  const store = readMobileStore();
  const now = new Date().toISOString();
  const accessToken = issueOpaqueToken();
  const refreshToken = issueOpaqueToken();
  const session: MobileSession = {
    id: newMobileId("msess"),
    customerEmail: input.email,
    deviceId: input.deviceId,
    accessTokenHash: hashToken(accessToken),
    refreshTokenHash: hashToken(refreshToken),
    expiresAt: addSec(now, ACCESS_TTL_SEC),
    refreshExpiresAt: addSec(now, REFRESH_TTL_SEC),
    createdAt: now,
    twoFactorVerified: input.twoFactorVerified,
    authMethods: input.methods,
  };
  store.sessions.unshift(session);
  writeMobileStore(store);
  return {
    accessToken,
    refreshToken,
    expiresAt: session.expiresAt,
    sessionId: session.id,
    deviceId: input.deviceId,
    requires2fa: input.requires2fa,
    twoFactorVerified: input.twoFactorVerified,
  };
}

export function refreshMobileSession(refreshToken: string): MobileAuthResult {
  const store = readMobileStore();
  const hash = hashToken(refreshToken);
  const old = store.sessions.find((s) => s.refreshTokenHash === hash && !s.revokedAt);
  if (!old) throw new Error("INVALID_REFRESH");
  if (new Date(old.refreshExpiresAt).getTime() < Date.now()) throw new Error("REFRESH_EXPIRED");
  old.revokedAt = new Date().toISOString();
  writeMobileStore(store);
  return createSession({
    email: old.customerEmail,
    deviceId: old.deviceId,
    methods: old.authMethods,
    twoFactorVerified: old.twoFactorVerified,
    requires2fa: !old.twoFactorVerified,
  });
}

export function resolveMobileAccessToken(accessToken: string): MobileSession | null {
  const store = readMobileStore();
  const hash = hashToken(accessToken);
  const session = store.sessions.find((s) => s.accessTokenHash === hash && !s.revokedAt);
  if (!session) return null;
  if (new Date(session.expiresAt).getTime() < Date.now()) return null;
  return session;
}

export function secureLogout(accessToken: string): boolean {
  const store = readMobileStore();
  const hash = hashToken(accessToken);
  const session = store.sessions.find((s) => s.accessTokenHash === hash && !s.revokedAt);
  if (!session) return false;
  session.revokedAt = new Date().toISOString();
  writeMobileStore(store);
  return true;
}

export function revokeAllSessionsForDevice(deviceId: string, email: string): number {
  const store = readMobileStore();
  let n = 0;
  const now = new Date().toISOString();
  for (const s of store.sessions) {
    if (s.deviceId === deviceId && s.customerEmail === email.toLowerCase() && !s.revokedAt) {
      s.revokedAt = now;
      n++;
    }
  }
  writeMobileStore(store);
  return n;
}

export function remoteRevokeSession(sessionId: string, actorEmail: string): boolean {
  const store = readMobileStore();
  const session = store.sessions.find(
    (s) => s.id === sessionId && s.customerEmail === actorEmail.toLowerCase() && !s.revokedAt
  );
  if (!session) return false;
  session.revokedAt = new Date().toISOString();
  writeMobileStore(store);
  return true;
}

export function listDevicesForCustomer(email: string) {
  return readMobileStore().devices.filter((d) => d.customerEmail === email.toLowerCase());
}

export function listSessionsForCustomer(email: string) {
  return readMobileStore().sessions.filter((s) => s.customerEmail === email.toLowerCase());
}

/** Demo helper — generate today's expected 2FA for tests */
export function demoTotpForEmail(email: string): string {
  const day = new Date().toISOString().slice(0, 10);
  return createHash("sha256")
    .update(`${email.toLowerCase()}:${day}:tgm-mobile-2fa`)
    .digest("hex")
    .replace(/\D/g, "")
    .slice(0, 6)
    .padStart(6, "0");
}
