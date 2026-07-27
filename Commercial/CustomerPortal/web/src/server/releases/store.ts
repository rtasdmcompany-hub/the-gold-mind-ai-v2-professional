import fs from "fs";
import path from "path";
import { createHash, randomBytes } from "crypto";
import type { ReleaseChannel, ReleasePackage, ReleaseStoreData } from "./types";
import { commercialDataRoot } from "@/server/cloud/data-root";

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
  const base = process.env.NEXTAUTH_URL || "http://localhost:3000";
  return [
    {
      id: "rel_200_stable",
      product: "THE GOLD MIND PROFESSIONAL",
      version: "2.0.0",
      buildNumber: "21060",
      channel: "stable",
      status: "published",
      releasedAt: "2026-07-20T00:00:00.000Z",
      packageFile: "TGM_PROFESSIONAL_2.0.0_stable.zip",
      packageUrl: `${base}/api/releases/download/rel_200_stable`,
      packageSizeBytes: 1300234,
      sha256: "a3f1c9e8b2d4470f91c6e5a8d0b3f7e1c4a6928d5e7b1f0c3d6a9e2b5c8f1d4a",
      signatureRequired: false,
      signatureSubject: "CN=RTAS Group of Companies (pending public code sign)",
      signatureStatus: "pending_code_sign",
      releaseNotes:
        "Professional commercial shell · installer/updater · Core Trading Engine unchanged (certified frozen).",
      compatibility: {
        os: ["Windows 10", "Windows 11"],
        mt5: "build 3800+",
        coreTag: "2.0.0",
        coreFrozen: true,
      },
      downloadCount: 0,
      updateSuccessCount: 0,
      updateFailCount: 0,
      rollbackEvents: 0,
    },
    {
      id: "rel_201_rc",
      product: "THE GOLD MIND PROFESSIONAL",
      version: "2.0.1-rc.1",
      buildNumber: "21061",
      channel: "rc",
      status: "published",
      releasedAt: "2026-07-25T00:00:00.000Z",
      packageFile: "TGM_PROFESSIONAL_2.0.1-rc.1_rc.zip",
      packageUrl: `${base}/api/releases/download/rel_201_rc`,
      packageSizeBytes: 1310000,
      sha256: "b8e2d1a7c4f9053e62a1b9d8c7e6f5a4b3c2d1e0f9a8b7c6d5e4f3a2b1c0d9e8",
      signatureRequired: false,
      signatureSubject: "unsigned RC",
      signatureStatus: "none",
      releaseNotes: "Release Candidate — installer hardening. Not for production accounts.",
      compatibility: {
        os: ["Windows 10", "Windows 11"],
        mt5: "build 3800+",
        coreTag: "2.0.0",
        coreFrozen: true,
      },
      downloadCount: 0,
      updateSuccessCount: 0,
      updateFailCount: 0,
      rollbackEvents: 0,
    },
    {
      id: "rel_dev_nightly",
      product: "THE GOLD MIND PROFESSIONAL",
      version: "2.1.0-dev",
      buildNumber: "21070",
      channel: "development",
      status: "published",
      releasedAt: "2026-07-26T00:00:00.000Z",
      packageFile: "TGM_PROFESSIONAL_2.1.0-dev_development.zip",
      packageUrl: `${base}/api/releases/download/rel_dev_nightly`,
      packageSizeBytes: 900000,
      sha256: "c1d2e3f4a5b697887766554433221100ffeeddccbbaa99887766554433221100",
      signatureRequired: false,
      signatureSubject: "dev only",
      signatureStatus: "none",
      releaseNotes: "Development channel — internal testing.",
      compatibility: {
        os: ["Windows 10", "Windows 11"],
        mt5: "build 3800+",
        coreTag: "2.0.0",
        coreFrozen: true,
      },
      downloadCount: 0,
      updateSuccessCount: 0,
      updateFailCount: 0,
      rollbackEvents: 0,
    },
  ];
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
