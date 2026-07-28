/**
 * Resolves the real commercial installer ZIP (Setup.exe + notes/checksums).
 * Prefer monorepo Commercial/Releases artifacts, then RELEASE_* env URLs/paths.
 */
import fs from "fs";
import path from "path";

export const STABLE_PACKAGE_ID = "rel_100_stable";
export const STABLE_VERSION = "1.0.0";
export const STABLE_PACKAGE_FILE = "TGM_PROFESSIONAL_1.0.0_stable.zip";
/** Known SHA-256 of Commercial/Releases/1.0.0/TGM_PROFESSIONAL_1.0.0_stable.zip */
export const STABLE_SHA256 =
  "2d9885f5c1b53995917af3e1677b49441393eabe0b6d7cf2cf758fbac4d364ad";
export const STABLE_SIZE_BYTES = 4_550_465;

const FAKE_SEED_IDS = new Set(["rel_200_stable", "rel_201_rc", "rel_dev_nightly"]);

export function isLegacySyntheticPackageId(id: string): boolean {
  return FAKE_SEED_IDS.has(id);
}

/** Candidate absolute paths for the stable ZIP on disk (dev / non-serverless). */
export function commercialZipCandidates(): string[] {
  const envPath = (process.env.RELEASE_SOURCE_ZIP || "").trim();
  const envDir = (process.env.RELEASE_SOURCE_DIR || "").trim();
  const cwd = process.cwd();
  const list: string[] = [];

  if (envPath) list.push(path.resolve(envPath));
  if (envDir) {
    list.push(path.join(path.resolve(envDir), STABLE_PACKAGE_FILE));
    list.push(path.join(path.resolve(envDir), "github-assets", STABLE_PACKAGE_FILE));
  }

  // CustomerPortal/web → ../../Releases/1.0.0
  const fromWeb = path.resolve(cwd, "..", "..", "Releases", "1.0.0");
  list.push(path.join(fromWeb, STABLE_PACKAGE_FILE));
  list.push(path.join(fromWeb, "github-assets", STABLE_PACKAGE_FILE));

  // Repo root (if cwd is monorepo root)
  const fromRoot = path.resolve(cwd, "Commercial", "Releases", "1.0.0");
  list.push(path.join(fromRoot, STABLE_PACKAGE_FILE));
  list.push(path.join(fromRoot, "github-assets", STABLE_PACKAGE_FILE));

  return list;
}

export function findLocalCommercialZip(): string | null {
  for (const p of commercialZipCandidates()) {
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
 * Required on Vercel when the monorepo ZIP is not bundled into the deploy.
 */
export function configuredReleaseAssetUrl(): string | null {
  const url = (
    process.env.RELEASE_STABLE_ZIP_URL ||
    process.env.RELEASE_ASSET_URL ||
    ""
  ).trim();
  if (url && /^https:\/\//i.test(url)) return url;

  // Bundled public asset (works on Vercel without private GitHub release auth)
  const base = (
    process.env.AUTH_URL ||
    process.env.NEXTAUTH_URL ||
    "https://the-gold-mind-ai-v2-professional.vercel.app"
  ).replace(/\/$/, "");
  return `${base}/releases/${STABLE_PACKAGE_FILE}`;
}

export function stableReleaseNotes(): string {
  return [
    "THE GOLD MIND PROFESSIONAL 1.0.0 (stable)",
    "Windows installer ZIP — unzip, run Setup.exe / TheGoldMindSetup.exe, enter your existing license key.",
    "Includes MT5 EA deploy, license activation wizard, desktop shortcuts, SHA-256 checksums, and SBOM.",
    "Core Trading Engine remains certified frozen.",
  ].join(" ");
}
