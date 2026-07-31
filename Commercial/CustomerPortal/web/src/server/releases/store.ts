import fs from "fs";
import path from "path";
import { createHash, randomBytes } from "crypto";
import type { ReleaseChannel, ReleasePackage, ReleaseStoreData } from "./types";
import { commercialDataRoot } from "@/server/cloud/data-root";
import {
  buildStableReleasePackage,
  isLegacySyntheticPackageId,
  STABLE_PACKAGE_ID,
  portalBaseUrl,
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

function seedPackages(): ReleasePackage[] {
  return [buildStableReleasePackage(portalBaseUrl())];
}

/**
 * Replace legacy synthetic 2.0.x seeds with the real commercial stable catalog entry.
 * Preserves download/update counters and event history when possible.
 * Refreshes metadata from Build-CommercialRelease portal seed when present.
 */
function migrateCommercialCatalog(data: ReleaseStoreData): boolean {
  let changed = false;
  const base = portalBaseUrl();
  const stableTemplate = buildStableReleasePackage(base);

  for (const pkg of data.packages) {
    if (isLegacySyntheticPackageId(pkg.id) && pkg.status === "published") {
      pkg.status = "yanked";
      changed = true;
    }
  }

  const existing = data.packages.find((p) => p.id === stableTemplate.id) ||
    data.packages.find((p) => p.id === STABLE_PACKAGE_ID);
  if (!existing) {
    data.packages.unshift(stableTemplate);
    changed = true;
  } else {
    const downloadCount = existing.downloadCount;
    const updateSuccessCount = existing.updateSuccessCount;
    const updateFailCount = existing.updateFailCount;
    const rollbackEvents = existing.rollbackEvents;
    const before = `${existing.sha256}|${existing.packageSizeBytes}|${existing.version}|${existing.status}|${existing.packageFile}`;
    Object.assign(existing, {
      ...stableTemplate,
      downloadCount,
      updateSuccessCount,
      updateFailCount,
      rollbackEvents,
    });
    existing.status = "published";
    const after = `${existing.sha256}|${existing.packageSizeBytes}|${existing.version}|${existing.status}|${existing.packageFile}`;
    if (before !== after) changed = true;
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
  if (migrateCommercialCatalog(cache)) {
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
  // rc/dev always "newer" metadata-wise if base equal and channel differs — treat string inequality
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

/** Test helper — clears in-memory cache so the next read hits disk. */
export function clearReleaseStoreCache(): void {
  cache = null;
}
