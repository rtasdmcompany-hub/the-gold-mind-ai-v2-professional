/**
 * Resolves the real commercial installer ZIP ({product.installer.name} + EA payload + scripts).
 * Prefer monorepo Commercial/Releases artifacts, then public/releases, then RELEASE_* env URLs.
 */
import fs from "fs";
import path from "path";
import type { ReleasePackage } from "./types";
import { RELEASE_INTERNAL_FETCH_HEADER } from "./internal-fetch";
import { brand } from "@/lib/brand";
import { product } from "@/lib/product";

export const STABLE_PACKAGE_ID = product.installer.stablePackageId;
export const STABLE_VERSION = product.version;
export const STABLE_BUILD_NUMBER = product.buildNumber;
export const STABLE_PACKAGE_FILE = product.installer.zipName;
/** Known SHA-256 of Commercial/Releases/1.0.0/TGM_PROFESSIONAL_1.0.0_stable.zip */
export const STABLE_SHA256 =
  "08a391eab307fe4e95bcfe48efcb650dab48ebca79fdf5e3d8c30976aa012e69";
export const STABLE_SIZE_BYTES = 861_612;
export const STABLE_RELEASED_AT = "2026-08-01T18:25:00Z";

const FAKE_SEED_IDS = new Set(["rel_200_stable", "rel_201_rc", "rel_dev_nightly"]);

/** Package ids accepted by download API — blocks path traversal / arbitrary reads. */
export const SAFE_PACKAGE_ID = /^[a-zA-Z0-9][a-zA-Z0-9._-]{0,63}$/;

export function isSafePackageId(id: string): boolean {
  return SAFE_PACKAGE_ID.test(id);
}

export function isLegacySyntheticPackageId(id: string): boolean {
  return FAKE_SEED_IDS.has(id);
}

export function isCommercialStablePackage(pkg: Pick<ReleasePackage, "id" | "channel" | "version" | "packageFile">): boolean {
  if (pkg.channel !== "stable") return false;
  if (isLegacySyntheticPackageId(pkg.id)) return false;
  if (pkg.id === STABLE_PACKAGE_ID) return true;
  if (pkg.version === STABLE_VERSION) return true;
  if (pkg.packageFile === STABLE_PACKAGE_FILE) return true;
  // Future stable builds published via Build-CommercialRelease portal seed
  if (pkg.packageFile?.startsWith("TGM_PROFESSIONAL_") && pkg.packageFile.endsWith(".zip")) return true;
  return false;
}

export function portalBaseUrl(): string {
  return product.urls.portal;
}

/** Optional overlay written by Build-CommercialRelease.ps1 → public/releases/latest-stable.json */
export function readPortalStableSeed(): Partial<ReleasePackage> | null {
  const candidates = [
    path.join(process.cwd(), "public", "releases", "latest-stable.json"),
    path.resolve(process.cwd(), "..", "..", "CustomerPortal", "web", "public", "releases", "latest-stable.json"),
  ];
  for (const p of candidates) {
    try {
      if (!fs.existsSync(p)) continue;
      const raw = JSON.parse(fs.readFileSync(p, "utf8")) as Partial<ReleasePackage>;
      if (raw && typeof raw.version === "string" && typeof raw.sha256 === "string") return raw;
    } catch {
      /* continue */
    }
  }
  return null;
}

/** Candidate absolute paths for the stable ZIP on disk (dev / non-serverless). */
export function commercialZipCandidates(packageFile = STABLE_PACKAGE_FILE): string[] {
  const envPath = (process.env.RELEASE_SOURCE_ZIP || "").trim();
  const envDir = (process.env.RELEASE_SOURCE_DIR || "").trim();
  const cwd = process.cwd();
  const list: string[] = [];
  const versionDir = packageFile.includes(product.version) ? product.version : packageFile.replace(/^TGM_PROFESSIONAL_/, "").replace(/_stable\.zip$/i, "").split("_")[0] || product.version;

  if (envPath) list.push(path.resolve(envPath));
  if (envDir) {
    list.push(path.join(path.resolve(envDir), packageFile));
  }

  // Bundled static asset (CustomerPortal/web/public/releases)
  list.push(path.join(cwd, "public", "releases", packageFile));

  // CustomerPortal/web → ../../Releases/<version>
  const fromWeb = path.resolve(cwd, "..", "..", "Releases", versionDir);
  list.push(path.join(fromWeb, packageFile));

  // Repo root (if cwd is monorepo root)
  const fromRoot = path.resolve(cwd, "Commercial", "Releases", versionDir);
  list.push(path.join(fromRoot, packageFile));

  // Always include known 1.0.0 path as fallback for current production package
  if (packageFile !== STABLE_PACKAGE_FILE) {
    list.push(path.join(cwd, "public", "releases", STABLE_PACKAGE_FILE));
  }

  return list;
}

export function findLocalCommercialZip(packageFile = STABLE_PACKAGE_FILE): string | null {
  for (const p of commercialZipCandidates(packageFile)) {
    try {
      if (fs.existsSync(p) && fs.statSync(p).isFile() && fs.statSync(p).size > 1024) {
        return p;
      }
    } catch {
      /* continue */
    }
  }
  return null;
}

/**
 * Public HTTPS URL for the stable ZIP (GitHub Release, Vercel Blob, CDN).
 * Required on Vercel when the monorepo ZIP is not readable from the serverless FS.
 */
export function configuredReleaseAssetUrl(packageFile = STABLE_PACKAGE_FILE): string | null {
  const url = (
    process.env.RELEASE_STABLE_ZIP_URL ||
    process.env.RELEASE_ASSET_URL ||
    ""
  ).trim();
  if (url && /^https:\/\//i.test(url)) return url;

  // Bundled public asset (works on Vercel without private GitHub release auth)
  return `${portalBaseUrl()}/releases/${packageFile}`;
}

export function stableReleaseNotes(): string {
  return [
    `${brand.productName} ${product.version} (stable).`,
    `"Windows installer ZIP — extract, run ${product.installer.name}, enter your existing license email and key."`,
    "Mandatory license activation completes before the commercial shell is ready.",
    "Includes MT5 EA deploy, activation wizard, desktop shortcuts, SHA-256 checksums, and SBOM.",
    "Core Trading Engine remains certified frozen.",
  ].join(" ");
}

/** Canonical published stable package metadata for the portal catalog. */
export function buildStableReleasePackage(baseUrl = portalBaseUrl()): ReleasePackage {
  const seed = readPortalStableSeed();
  const packageFile = seed?.packageFile || STABLE_PACKAGE_FILE;
  const id = (seed?.id && typeof seed.id === "string" ? seed.id : STABLE_PACKAGE_ID) as string;
  const version = seed?.version || STABLE_VERSION;
  return {
    id,
    product: brand.productName,
    version,
    buildNumber: seed?.buildNumber || STABLE_BUILD_NUMBER,
    channel: "stable",
    status: "published",
    releasedAt: seed?.releasedAt || STABLE_RELEASED_AT,
    packageFile,
    // Customer/API-facing download path is the authenticated download route only.
    // /releases/* static assets are never advertised as a download URL.
    packageUrl: `${baseUrl}/api/releases/download/${id}`,
    packageSizeBytes: typeof seed?.packageSizeBytes === "number" ? seed.packageSizeBytes : STABLE_SIZE_BYTES,
    sha256: seed?.sha256 || STABLE_SHA256,
    signatureRequired: seed?.signatureRequired === true,
    signatureSubject: seed?.signatureSubject || "Code signing pending",
    signatureStatus: (seed?.signatureStatus as ReleasePackage["signatureStatus"]) || "pending_code_sign",
    releaseNotes: seed?.releaseNotes || stableReleaseNotes(),
    compatibility: {
      os: seed?.compatibility?.os || ["Windows 10", "Windows 11"],
      mt5: seed?.compatibility?.mt5 || "build 3800+",
      coreTag: seed?.compatibility?.coreTag || version,
      coreFrozen: seed?.compatibility?.coreFrozen !== false,
    },
    downloadCount: 0,
    updateSuccessCount: 0,
    updateFailCount: 0,
    rollbackEvents: 0,
  };
}

/**
 * Load commercial ZIP bytes: local disk first, then HTTPS asset URL (cached by caller).
 */
export async function loadCommercialZipBytes(
  packageFile = STABLE_PACKAGE_FILE
): Promise<{ buffer: Buffer; source: string } | null> {
  const local = findLocalCommercialZip(packageFile);
  if (local) {
    return { buffer: fs.readFileSync(local), source: local };
  }

  const url = configuredReleaseAssetUrl(packageFile);
  if (!url) return null;

  try {
    // /releases/* is not a public customer download surface — this same-origin
    // fallback fetch (used when local disk is unavailable, e.g. serverless) is
    // authorized only via this internal shared-secret header, never exposed to
    // browsers/customers.
    const internalSecret = (process.env.AUTH_SECRET || process.env.NEXTAUTH_SECRET || "").trim();
    const res = await fetch(url, {
      redirect: "follow",
      headers: {
        Accept: "application/zip,application/octet-stream,*/*",
        ...(internalSecret ? { [RELEASE_INTERNAL_FETCH_HEADER]: internalSecret } : {}),
      },
      cache: "no-store",
    });
    if (!res.ok) return null;
    const ab = await res.arrayBuffer();
    const buffer = Buffer.from(ab);
    if (buffer.length < 1024 || buffer[0] !== 0x50 || buffer[1] !== 0x4b) return null;
    return { buffer, source: url };
  } catch {
    return null;
  }
}
