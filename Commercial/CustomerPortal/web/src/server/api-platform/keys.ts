/**
 * API Keys + OAuth 2.0-style client credentials tokens.
 */
import {
  hashSecret,
  issueSecret,
  newApiId,
  readApiStore,
  writeApiStore,
} from "./store";
import type { ApiKeyRecord, ApiScope, OAuthTokenRecord } from "./types";
import { ALL_COMMERCIAL_SCOPES } from "./types";

function addSec(iso: string, sec: number): string {
  return new Date(new Date(iso).getTime() + sec * 1000).toISOString();
}

export function createApiKey(input: {
  name: string;
  ownerEmail: string;
  scopes?: ApiScope[];
  ipAllowlist?: string[];
  rateLimitPerMin?: number;
}): { record: ApiKeyRecord; plaintextKey: string } {
  const plaintextKey = issueSecret("tgm_live");
  const now = new Date().toISOString();
  const record: ApiKeyRecord = {
    id: newApiId("apk"),
    name: input.name,
    ownerEmail: input.ownerEmail.toLowerCase(),
    keyHash: hashSecret(plaintextKey),
    keyPrefix: plaintextKey.slice(0, 12),
    scopes: input.scopes?.length ? input.scopes : [...ALL_COMMERCIAL_SCOPES],
    createdAt: now,
    ipAllowlist: input.ipAllowlist || [],
    rateLimitPerMin: input.rateLimitPerMin || 120,
  };
  const store = readApiStore();
  store.keys.unshift(record);
  writeApiStore(store);
  return { record, plaintextKey };
}

export function rotateApiKey(keyId: string, ownerEmail: string): { record: ApiKeyRecord; plaintextKey: string } {
  const store = readApiStore();
  const old = store.keys.find(
    (k) => k.id === keyId && k.ownerEmail === ownerEmail.toLowerCase() && !k.revokedAt
  );
  if (!old) throw new Error("API_KEY_NOT_FOUND");
  old.revokedAt = new Date().toISOString();
  writeApiStore(store);
  const next = createApiKey({
    name: `${old.name} (rotated)`,
    ownerEmail,
    scopes: old.scopes,
    ipAllowlist: old.ipAllowlist,
    rateLimitPerMin: old.rateLimitPerMin,
  });
  next.record.rotatedFromId = old.id;
  const s2 = readApiStore();
  const row = s2.keys.find((k) => k.id === next.record.id);
  if (row) row.rotatedFromId = old.id;
  writeApiStore(s2);
  return next;
}

export function revokeApiKey(keyId: string, ownerEmail: string): boolean {
  const store = readApiStore();
  const key = store.keys.find(
    (k) => k.id === keyId && k.ownerEmail === ownerEmail.toLowerCase() && !k.revokedAt
  );
  if (!key) return false;
  key.revokedAt = new Date().toISOString();
  writeApiStore(store);
  return true;
}

export function listApiKeys(ownerEmail: string): Omit<ApiKeyRecord, "keyHash">[] {
  return readApiStore()
    .keys.filter((k) => k.ownerEmail === ownerEmail.toLowerCase())
    .map(({ keyHash, ...rest }) => {
      void keyHash;
      return rest;
    });
}

export function resolveApiKey(plaintext: string): ApiKeyRecord | null {
  const hash = hashSecret(plaintext);
  const store = readApiStore();
  const key = store.keys.find((k) => k.keyHash === hash && !k.revokedAt);
  if (!key) return null;
  key.lastUsedAt = new Date().toISOString();
  writeApiStore(store);
  return key;
}

export function issueOAuthToken(apiKeyPlaintext: string): {
  accessToken: string;
  refreshToken: string;
  expiresIn: number;
  token: OAuthTokenRecord;
} {
  const key = resolveApiKey(apiKeyPlaintext);
  if (!key) throw new Error("INVALID_CLIENT");
  const now = new Date().toISOString();
  const accessToken = issueSecret("tgm_atk");
  const refreshToken = issueSecret("tgm_rtk");
  const token: OAuthTokenRecord = {
    id: newApiId("tok"),
    apiKeyId: key.id,
    ownerEmail: key.ownerEmail,
    accessTokenHash: hashSecret(accessToken),
    refreshTokenHash: hashSecret(refreshToken),
    scopes: key.scopes,
    expiresAt: addSec(now, 3600),
    refreshExpiresAt: addSec(now, 60 * 60 * 24 * 30),
    createdAt: now,
  };
  const store = readApiStore();
  store.tokens.unshift(token);
  writeApiStore(store);
  return { accessToken, refreshToken, expiresIn: 3600, token };
}

export function resolveAccessToken(accessToken: string): OAuthTokenRecord | null {
  const hash = hashSecret(accessToken);
  const token = readApiStore().tokens.find((t) => t.accessTokenHash === hash && !t.revokedAt);
  if (!token) return null;
  if (new Date(token.expiresAt).getTime() < Date.now()) return null;
  return token;
}

export function refreshOAuthToken(refreshToken: string) {
  const store = readApiStore();
  const hash = hashSecret(refreshToken);
  const old = store.tokens.find((t) => t.refreshTokenHash === hash && !t.revokedAt);
  if (!old) throw new Error("INVALID_REFRESH");
  if (new Date(old.refreshExpiresAt).getTime() < Date.now()) throw new Error("REFRESH_EXPIRED");
  old.revokedAt = new Date().toISOString();
  writeApiStore(store);
  const key = store.keys.find((k) => k.id === old.apiKeyId && !k.revokedAt);
  if (!key) throw new Error("API_KEY_REVOKED");
  // Re-issue using key plaintext unavailable — issue from key id path
  const now = new Date().toISOString();
  const accessToken = issueSecret("tgm_atk");
  const newRefresh = issueSecret("tgm_rtk");
  const token: OAuthTokenRecord = {
    id: newApiId("tok"),
    apiKeyId: key.id,
    ownerEmail: key.ownerEmail,
    accessTokenHash: hashSecret(accessToken),
    refreshTokenHash: hashSecret(newRefresh),
    scopes: old.scopes,
    expiresAt: addSec(now, 3600),
    refreshExpiresAt: addSec(now, 60 * 60 * 24 * 30),
    createdAt: now,
  };
  const s2 = readApiStore();
  s2.tokens.unshift(token);
  writeApiStore(s2);
  return { accessToken, refreshToken: newRefresh, expiresIn: 3600, token };
}

export function keyHasScope(key: { scopes: ApiScope[] }, scope: ApiScope): boolean {
  return key.scopes.includes(scope);
}
