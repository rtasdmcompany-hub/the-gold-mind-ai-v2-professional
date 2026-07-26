/**
 * Minimal ZIP (store method) + on-disk release artifacts.
 * Commercial packages only — never embeds Trading Engine binaries.
 */
import fs from "fs";
import path from "path";
import { createHash } from "crypto";
import type { ReleasePackage } from "./types";
import { mutateReleases, readReleaseStore } from "./store";

const CRC_TABLE = (() => {
  const table = new Uint32Array(256);
  for (let i = 0; i < 256; i++) {
    let c = i;
    for (let k = 0; k < 8; k++) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1;
    table[i] = c >>> 0;
  }
  return table;
})();

function crc32(buf: Buffer): number {
  let c = 0xffffffff;
  for (let i = 0; i < buf.length; i++) c = CRC_TABLE[(c ^ buf[i]) & 0xff] ^ (c >>> 8);
  return (c ^ 0xffffffff) >>> 0;
}

function u16(n: number): Buffer {
  const b = Buffer.alloc(2);
  b.writeUInt16LE(n, 0);
  return b;
}

function u32(n: number): Buffer {
  const b = Buffer.alloc(4);
  b.writeUInt32LE(n >>> 0, 0);
  return b;
}

/** Build an uncompressed ZIP containing the given files. */
export function buildZipArchive(files: { name: string; data: Buffer }[]): Buffer {
  const localParts: Buffer[] = [];
  const centralParts: Buffer[] = [];
  let offset = 0;

  for (const file of files) {
    const nameBuf = Buffer.from(file.name.replace(/\\/g, "/"), "utf8");
    const data = file.data;
    const crc = crc32(data);
    const local = Buffer.concat([
      u32(0x04034b50),
      u16(20),
      u16(0),
      u16(0),
      u16(0),
      u16(0),
      u32(crc),
      u32(data.length),
      u32(data.length),
      u16(nameBuf.length),
      u16(0),
      nameBuf,
      data,
    ]);
    const central = Buffer.concat([
      u32(0x02014b50),
      u16(20),
      u16(20),
      u16(0),
      u16(0),
      u16(0),
      u16(0),
      u32(crc),
      u32(data.length),
      u32(data.length),
      u16(nameBuf.length),
      u16(0),
      u16(0),
      u16(0),
      u16(0),
      u32(0),
      u32(offset),
      nameBuf,
    ]);
    localParts.push(local);
    centralParts.push(central);
    offset += local.length;
  }

  const centralDir = Buffer.concat(centralParts);
  const locals = Buffer.concat(localParts);
  const end = Buffer.concat([
    u32(0x06054b50),
    u16(0),
    u16(0),
    u16(files.length),
    u16(files.length),
    u32(centralDir.length),
    u32(locals.length),
    u16(0),
  ]);
  return Buffer.concat([locals, centralDir, end]);
}

export function sha256Buffer(buf: Buffer): string {
  return createHash("sha256").update(buf).digest("hex");
}

function artifactsDir(): string {
  const dir =
    process.env.RELEASE_ARTIFACTS_DIR ||
    path.join(process.env.RELEASE_DATA_DIR || path.join(process.cwd(), ".data", "releases"), "artifacts");
  if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
  return dir;
}

export function artifactPath(packageId: string): string {
  return path.join(artifactsDir(), `${packageId}.zip`);
}

/** Build commercial-shell ZIP payload for a release package. */
export function buildCommercialPackageZip(pkg: ReleasePackage): Buffer {
  const launcher = Buffer.from(
    [
      "@echo off",
      `echo THE GOLD MIND PROFESSIONAL commercial shell`,
      `echo Version ${pkg.version} Build ${pkg.buildNumber} Channel ${pkg.channel}`,
      "echo Open MetaTrader 5 and attach the Professional EA from your licensed package.",
      "echo Core Trading Engine remains the sole execution authority.",
      "pause",
      "",
    ].join("\r\n"),
    "utf8"
  );
  const versionTxt = Buffer.from(`${pkg.version}\n${pkg.buildNumber}\n${pkg.channel}\n`, "utf8");
  const manifest = Buffer.from(
    JSON.stringify(
      {
        product: pkg.product,
        version: pkg.version,
        buildNumber: pkg.buildNumber,
        channel: pkg.channel,
        coreTag: pkg.compatibility.coreTag,
        coreFrozen: pkg.compatibility.coreFrozen,
        note: "Commercial shell package — does not alter Trading Engine behavior.",
      },
      null,
      2
    ),
    "utf8"
  );
  const readme = Buffer.from(
    [
      "THE GOLD MIND PROFESSIONAL — Commercial Package",
      `Version: ${pkg.version} · Build: ${pkg.buildNumber} · Channel: ${pkg.channel}`,
      "",
      pkg.releaseNotes,
      "",
      "This package installs the commercial shell only.",
      "It never modifies Trading Engine / Strategy / Risk / Recovery / Order Execution / Magic Number logic.",
      "",
    ].join("\n"),
    "utf8"
  );

  return buildZipArchive([
    { name: "bin/TGM-Professional-Launcher.cmd", data: launcher },
    { name: "bin/VERSION.txt", data: versionTxt },
    { name: "config/package-manifest.json", data: manifest },
    { name: "README.txt", data: readme },
  ]);
}

/**
 * Ensure on-disk artifact exists and package metadata (sha256, size) matches bytes.
 * Call before serving downloads so updater checksum validation succeeds.
 */
export function ensurePackageArtifact(pkg: ReleasePackage): { buffer: Buffer; package: ReleasePackage } {
  const p = artifactPath(pkg.id);
  let buffer: Buffer;
  const needsRebuild =
    !fs.existsSync(p) ||
    (() => {
      const existing = fs.readFileSync(p);
      // ZIP local file header magic
      return existing.length < 4 || existing[0] !== 0x50 || existing[1] !== 0x4b;
    })();

  if (needsRebuild) {
    buffer = buildCommercialPackageZip(pkg);
    fs.writeFileSync(p, buffer);
  } else {
    buffer = fs.readFileSync(p);
  }
  const hash = sha256Buffer(buffer);
  const size = buffer.length;
  if (pkg.sha256 !== hash || pkg.packageSizeBytes !== size) {
    mutateReleases((data) => {
      const row = data.packages.find((x) => x.id === pkg.id);
      if (!row) return;
      row.sha256 = hash;
      row.packageSizeBytes = size;
    });
    const refreshed = readReleaseStore().packages.find((x) => x.id === pkg.id)!;
    return { buffer, package: refreshed };
  }
  return { buffer, package: pkg };
}

export function ensureAllPackageArtifacts(): void {
  for (const pkg of readReleaseStore().packages) {
    if (pkg.status === "published") ensurePackageArtifact(pkg);
  }
}
