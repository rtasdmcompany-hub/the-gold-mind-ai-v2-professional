/**
 * Mobile security controls — biometric flags, encrypted storage, TLS, tokens, integrity.
 */
import { createHash } from "crypto";
import { readMobileStore, writeMobileStore } from "./store";
import { listSessionsForCustomer, remoteRevokeSession, revokeAllSessionsForDevice } from "./auth";
import { MOBILE_CORE_ISOLATION, MOBILE_TRADING_PROHIBITED } from "./types";

export function setBiometricEnabled(deviceId: string, email: string, enabled: boolean) {
  const store = readMobileStore();
  const device = store.devices.find(
    (d) => d.id === deviceId && d.customerEmail === email.toLowerCase() && !d.revokedAt
  );
  if (!device) throw new Error("DEVICE_NOT_FOUND");
  device.biometricEnabled = enabled;
  writeMobileStore(store);
  return device;
}

export function recordDeviceIntegrity(deviceId: string, email: string, ok: boolean) {
  const store = readMobileStore();
  const device = store.devices.find(
    (d) => d.id === deviceId && d.customerEmail === email.toLowerCase() && !d.revokedAt
  );
  if (!device) throw new Error("DEVICE_NOT_FOUND");
  device.integrityOk = ok;
  if (!ok) {
    revokeAllSessionsForDevice(deviceId, email);
  }
  writeMobileStore(store);
  return device;
}

export function upsertOfflineCache(email: string, keys: string[], ttlSec = 3600) {
  const store = readMobileStore();
  const e = email.toLowerCase();
  store.offlineCaches = store.offlineCaches.filter((c) => c.customerEmail !== e);
  store.offlineCaches.unshift({
    customerEmail: e,
    cachedAt: new Date().toISOString(),
    ttlSec,
    keys,
  });
  writeMobileStore(store);
  return store.offlineCaches[0];
}

export function certificateValidationPolicy() {
  return {
    tlsMinVersion: "1.2",
    pinMode: "optional_public_key_pinning",
    validateHostname: true,
    rejectExpiredCerts: true,
    note: "Companion must use HTTPS to commercial APIs only.",
  };
}

export function encryptedLocalStorageSpec() {
  return {
    android: "EncryptedSharedPreferences / Keystore",
    ios: "Keychain + Data Protection Complete",
    keysStored: ["refresh_token", "device_fingerprint", "biometric_flag"],
    neverStored: ["trading_credentials", "mt5_passwords", "strategy_params"],
  };
}

export function securityPosture(email?: string) {
  const store = readMobileStore();
  const sessions = email ? listSessionsForCustomer(email) : store.sessions;
  const active = sessions.filter((s) => !s.revokedAt);
  const devices = email
    ? store.devices.filter((d) => d.customerEmail === email.toLowerCase())
    : store.devices;
  const integrityFails = devices.filter((d) => !d.integrityOk && !d.revokedAt).length;

  return {
    tradingProhibited: MOBILE_TRADING_PROHIBITED,
    coreIsolation: MOBILE_CORE_ISOLATION,
    activeSessions: active.length,
    trustedDevices: devices.filter((d) => d.trusted && !d.revokedAt).length,
    biometricEnabled: devices.filter((d) => d.biometricEnabled && !d.revokedAt).length,
    integrityFails,
    certificatePolicy: certificateValidationPolicy(),
    localStorage: encryptedLocalStorageSpec(),
    tokenRefresh: "access 1h · refresh 30d · rotation on refresh",
    remoteRevocation: true,
    apiAuth: "Bearer access token over TLS",
    at: new Date().toISOString(),
  };
}

export function adminRemoteRevoke(sessionId: string, customerEmail: string) {
  return remoteRevokeSession(sessionId, customerEmail);
}

export function appAttestChallenge(deviceId: string): string {
  return createHash("sha256")
    .update(`${deviceId}:${Date.now()}:tgm-attest`)
    .digest("hex")
    .slice(0, 32);
}
