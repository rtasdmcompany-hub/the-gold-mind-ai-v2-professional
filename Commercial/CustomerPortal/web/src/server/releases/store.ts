import fs from "fs";
import path from "path";
import { createHash, randomBytes } from "crypto";
import type { ReleaseChannel, ReleasePackage, ReleaseStoreData } from "./types";
import { commercialDataRoot } from "@/server/cloud/data-root";
import {
  STABLE_PACKAGE_FILE,
  STABLE_PACKAGE_ID,
  STABLE_SHA256,
  STABLE_SIZE_BYTES,
  STABLE_VERSION,
  configuredReleaseAssetUrl,
  isLegacySyntheticPackageId,
  stableReleaseNotes,
} from "./commercial-source";

function dataDir(): string {
  const dir = process.env.RELEASE_DATA_DIR || commercialDataRoot("releases");
  if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
  return dir;
}

function storePath(): string {
  return path.join(dataDir(), "releases.json");
}

const EMPTY: ReleaseStoreData = { version: 1, packages: [], updateEvents: [], downloadEvents: [] };

let cache: ReleaseStoreData | null = null;

function buildStablePackage(): ReleasePackage {
  const base = process.env.NEXTAUTH_URL || "http://localhost:3000";
  const external = configuredReleaseAssetUrl() || undefined;
  return {
    id: STABLE_PACKAGE_ID,
    product: "THE GOLD MIND PROFESSIONAL",
    version: STABLE_VERSION,
    buildNumber: "10000",
    channel: "stable",
    status: "published",
    releasedAt: "2026-07-28T12:28:31.000Z",
    packageFile: STABLE_PACKAGE_FILE,
    packageUrl: `${base}/api/releases/download/${STABLE_PACKAGE_ID}`,
    externalAssetUrl: external,
    packageSizeBytes: STABLE_SIZE_BYTES,
    sha256: STABLE_SHA256,
    signatureRequired: false,
    signatureSubject: "CN=RTAS Group of Companies (pending public code sign)",
    signatureStatus: "pending_code_sign",
    releaseNotes: stableReleaseNotes(),
    compatibility: {
      os: ["Windows 10", "Windows 11"],
      mt5: "build 3800+",
      coreTag: "1.0.0",
      coreFrozen: true,
    },
    downloadCount: 0,
    updateSuccessCount: 0,
    updateFailCount: 0,
    rollbackEvents: 0,
  };
}

function seedPackages(): ReleasePackage[] {
  return [buildStablePackage()];
}

/** Ensure real 1.0.0 stable is catalogued; supersede legacy synthetic seeds. */
function migrateCatalog(data: ReleaseStoreData): boolean {
  let changed = false;

  for (const pkg of data.packages) {
    if (isLegacySyntheticPackageId(pkg.id) && pkg.status === "published") {
      pkg.status = "superseded";
      changed = true;
    }
  }

  const existing = data.packages.find((p) => p.id === STABLE_PACKAGE_ID);
  const fresh = buildStablePackage();
  if (!existing) {
    data.packages.unshift(fresh);
    changed = true;
  } else {
    // Keep counters; refresh identity / notes / integrity defaults when still on placeholders
    if (existing.version !== STABLE_VERSION) {
      existing.version = STABLE_VERSION;
      changed = true;
    }
    if (existing.packageFile !== STABLE_PACKAGE_FILE) {
      existing.packageFile = STABLE_PACKAGE_FILE;
      changed = true;
    }
    if (existing.status !== "published") {
      existing.status = "published";
      changed = true;
    }
    if (existing.channel !== "stable") {
      existing.channel = "stable";
      changed = true;
    }
    if (!existing.sha256 || existing.sha256.length < 32) {
      existing.sha256 = STABLE_SHA256;
      changed = true;
    }
    if (!existing.packageSizeBytes || existing.packageSizeBytes < 100_000) {
      existing.packageSizeBytes = STABLE_SIZE_BYTES;
      changed = true;
    }
    const ext = configuredReleaseAssetUrl();
    if (ext && existing.externalAssetUrl !== ext) {
      existing.externalAssetUrl = ext;
      changed = true;
    }
    if (!existing.releaseNotes?.includes("1.0.0")) {
      existing.releaseNotes = stableReleaseNotes();
      changed = true;
    }
    existing.compatibility = {
      ...existing.compatibility,
      coreTag: "1.0.0",
      coreFrozen: true,
    };
  }

  return changed;
}

export function readReleaseStore(): ReleaseStoreData {
  if (cache) return cache;
  const p = storePath();
  if (!fs.existsSync(p)) {
    cache = { ...EMPTY, packages: seedPackages() };
    writeReleaseStore(cache);
    return cache;
  }
  cache = JSON.parse(fs.readFileSync(p, "utf8")) as ReleaseStoreData;
  if (!Array.isArray(cache.packages)) cache.packages = [];
  if (!Array.isArray(cache.updateEvents)) cache.updateEvents = [];
  if (!Array.isArray(cache.downloadEvents)) cache.downloadEvents = [];
  if (migrateCatalog(cache)) {
    writeReleaseStore(cache);
  }
  return cache;
}

export function writeReleaseStore(data: ReleaseStoreData): void {
  cache = data;
  fs.writeFileSync(storePath(), JSON.stringify(data, null, 2), "utf8");
}

export function mutateReleases(mutator: (data: ReleaseStoreData) => void): ReleaseStoreData {
  const data = structuredClone(readReleaseStore());
  mutator(data);
  if (data.updateEvents.length > 2000) data.updateEvents.length = 2000;
  if (data.downloadEvents.length > 2000) data.downloadEvents.length = 2000;
  writeReleaseStore(data);
  return data;
}

export function compareSemver(a: string, b: string): number {
  const norm = (v: string) =>
    v
      .replace(/-rc\.\d+/i, "")
      .replace(/-dev.*/i, "")
      .split(".")
      .map((n) => parseInt(n, 10) || 0);
  const aa = norm(a);
  const bb = norm(b);
  for (let i = 0; i < 3; i++) {
    if ((aa[i] || 0) > (bb[i] || 0)) return 1;
    if ((aa[i] || 0) < (bb[i] || 0)) return -1;
  }
  if (a === b) return 0;
  return a > b ? 1 : -1;
}

export function latestForChannel(channel: ReleaseChannel): ReleasePackage | undefined {
  return readReleaseStore()
    .packages.filter((p) => p.channel === channel && p.status === "published")
    .sort((x, y) => compareSemver(y.version, x.version))[0];
}

export function id(prefix: string): string {
  return `${prefix}_${Date.now().toString(36)}_${randomBytes(2).toString("hex")}`;
}

export function sha256Text(s: string): string {
  return createHash("sha256").update(s).digest("hex");
}
