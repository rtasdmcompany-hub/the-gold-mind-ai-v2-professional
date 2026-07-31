import {
  compareSemver,
  id,
  latestForChannel,
  mutateReleases,
  readReleaseStore,
} from "./store";
import { ensurePackageArtifact } from "./package-artifact";
import { isSafePackageId } from "./commercial-source";
import type { ReleaseChannel, ReleasePackage } from "./types";

export function listPublished(channel?: ReleaseChannel): ReleasePackage[] {
  // Catalog metadata only — download path loads real ZIP bytes on demand.
  return readReleaseStore()
    .packages.filter((p) => p.status === "published" && (!channel || p.channel === channel))
    .sort((a, b) => compareSemver(b.version, a.version));
}

export function getPackage(packageId: string): ReleasePackage | undefined {
  if (!isSafePackageId(packageId)) return undefined;
  return readReleaseStore().packages.find((p) => p.id === packageId);
}

export function checkForUpdate(input: {
  channel: ReleaseChannel;
  version: string;
  email?: string;
}) {
  const latestPkg = latestForChannel(input.channel);
  const updateAvailable = !!latestPkg && compareSemver(latestPkg.version, input.version) > 0;

  mutateReleases((data) => {
    data.updateEvents.unshift({
      id: id("uevt"),
      at: new Date().toISOString(),
      email: input.email,
      fromVersion: input.version,
      toVersion: latestPkg?.version || input.version,
      channel: input.channel,
      result: "check",
      detail: updateAvailable ? "update available" : "up to date",
    });
  });

  const latestPayload = latestPkg
    ? {
        id: latestPkg.id,
        version: latestPkg.version,
        buildNumber: latestPkg.buildNumber,
        releaseNotes: latestPkg.releaseNotes,
        packageUrl: latestPkg.packageUrl,
        downloadUrl: latestPkg.packageUrl,
        sha256: latestPkg.sha256,
        signatureRequired: latestPkg.signatureRequired,
        signatureSubject: latestPkg.signatureSubject,
        signatureStatus: latestPkg.signatureStatus,
        packageSizeBytes: latestPkg.packageSizeBytes,
        httpsOnly: true,
        compatibility: latestPkg.compatibility,
      }
    : null;

  // Nested `latest` for portal UI + top-level fields for desktop updater clients.
  return {
    updateAvailable,
    available: updateAvailable,
    channel: input.channel,
    current: input.version,
    version: latestPayload?.version,
    targetVersion: latestPayload?.version,
    downloadUrl: latestPayload?.packageUrl,
    sha256: latestPayload?.sha256,
    latest: latestPayload,
  };
}

export function recordDownload(packageId: string, email?: string, ip?: string) {
  mutateReleases((data) => {
    const pkg = data.packages.find((p) => p.id === packageId);
    if (!pkg) return;
    pkg.downloadCount += 1;
    data.downloadEvents.unshift({
      id: id("dl"),
      at: new Date().toISOString(),
      email,
      packageId,
      version: pkg.version,
      ipMasked: maskIp(ip),
    });
  });
}

export function recordUpdateResult(input: {
  email?: string;
  fromVersion: string;
  toVersion: string;
  channel: ReleaseChannel;
  result: "success" | "fail" | "rollback";
  detail: string;
  packageId?: string;
}) {
  mutateReleases((data) => {
    data.updateEvents.unshift({
      id: id("uevt"),
      at: new Date().toISOString(),
      email: input.email,
      fromVersion: input.fromVersion,
      toVersion: input.toVersion,
      channel: input.channel,
      result: input.result,
      detail: input.detail,
    });
    const pkg =
      (input.packageId && data.packages.find((p) => p.id === input.packageId)) ||
      data.packages.find((p) => p.version === input.toVersion);
    if (!pkg) return;
    if (input.result === "success") pkg.updateSuccessCount += 1;
    if (input.result === "fail") pkg.updateFailCount += 1;
    if (input.result === "rollback") pkg.rollbackEvents += 1;
  });
}

/** Last known installed version for a customer from update success events. */
export function getReportedInstalledVersion(email: string): string | null {
  const e = email.toLowerCase();
  const hit = readReleaseStore().updateEvents.find(
    (ev) => ev.email?.toLowerCase() === e && ev.result === "success"
  );
  return hit?.toVersion || null;
}

export function getCompatibilityMatrix() {
  return listPublished().map((p) => ({
    version: p.version,
    channel: p.channel,
    buildNumber: p.buildNumber,
    os: p.compatibility.os,
    mt5: p.compatibility.mt5,
    coreTag: p.compatibility.coreTag,
    coreFrozen: p.compatibility.coreFrozen,
  }));
}

export function getAdminReleaseDashboard() {
  const data = readReleaseStore();
  const published = data.packages.filter((p) => p.status === "published");
  const latest = latestForChannel("stable");
  const totalDownloads = published.reduce((a, p) => a + p.downloadCount, 0);
  const totalSuccess = published.reduce((a, p) => a + p.updateSuccessCount, 0);
  const totalFail = published.reduce((a, p) => a + p.updateFailCount, 0);
  const successRate =
    totalSuccess + totalFail === 0 ? 100 : Math.round((totalSuccess / (totalSuccess + totalFail)) * 1000) / 10;

  return {
    latestRelease: latest,
    previousReleases: published.filter((p) => p.id !== latest?.id),
    packages: published,
    totalDownloads,
    updateSuccessRate: successRate,
    rollbackEvents: published.reduce((a, p) => a + p.rollbackEvents, 0),
    recentUpdateEvents: data.updateEvents.slice(0, 40),
    recentDownloads: data.downloadEvents.slice(0, 40),
    compatibilityMatrix: getCompatibilityMatrix(),
  };
}

function maskIp(ip?: string): string {
  if (!ip) return "***.***.***.***";
  const parts = ip.split(".");
  if (parts.length === 4) return `${parts[0]}.${parts[1]}.${parts[2]}.***`;
  return "***";
}

/** @deprecated use ensurePackageArtifact — kept for import compatibility */
export async function buildPlaceholderPackageBuffer(pkg: ReleasePackage): Promise<Buffer> {
  return (await ensurePackageArtifact(pkg)).buffer;
}

export async function getPackageBytes(
  packageId: string
): Promise<{ buffer: Buffer; package: ReleasePackage } | null> {
  if (!isSafePackageId(packageId)) return null;
  const pkg = readReleaseStore().packages.find((p) => p.id === packageId);
  if (!pkg || pkg.status !== "published") return null;
  try {
    return await ensurePackageArtifact(pkg);
  } catch {
    return null;
  }
}
