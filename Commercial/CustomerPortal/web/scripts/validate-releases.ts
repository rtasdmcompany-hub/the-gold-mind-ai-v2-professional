/**
 * Focused validation for the customer portal Downloads / Updates release pipeline.
 * Run: npx tsx scripts/validate-releases.ts
 */
import fs from "fs";
import path from "path";
import os from "os";
import { createHash } from "crypto";

type Result = { name: string; pass: boolean; notes: string };
const results: Result[] = [];

function assert(name: string, cond: boolean, notes: string) {
  results.push({ name, pass: !!cond, notes });
}

async function main() {
  const tmp = fs.mkdtempSync(path.join(os.tmpdir(), "tgm-release-validate-"));
  process.env.RELEASE_DATA_DIR = path.join(tmp, "releases");
  process.env.RELEASE_ARTIFACTS_DIR = path.join(tmp, "artifacts");
  process.env.NEXTAUTH_URL = "http://localhost:3000";
  process.env.RELEASE_DOWNLOAD_AUTH = "public";
  delete process.env.RELEASE_STABLE_ZIP_URL;
  delete process.env.RELEASE_ASSET_URL;

  const webRoot = path.resolve(__dirname, "..");
  const publicZip = path.join(webRoot, "public", "releases", "TGM_PROFESSIONAL_1.0.0_stable.zip");
  const commercialZip = path.resolve(
    webRoot,
    "..",
    "..",
    "Releases",
    "1.0.0",
    "TGM_PROFESSIONAL_1.0.0_stable.zip"
  );

  const {
    STABLE_PACKAGE_ID,
    STABLE_SHA256,
    STABLE_SIZE_BYTES,
    isSafePackageId,
    isLegacySyntheticPackageId,
    findLocalCommercialZip,
    buildStableReleasePackage,
  } = await import("../src/server/releases/commercial-source");
  const { clearReleaseStoreCache, compareSemver, readReleaseStore } = await import(
    "../src/server/releases/store"
  );
  const { listPublished, checkForUpdate, getPackageBytes, recordDownload, getReportedInstalledVersion } =
    await import("../src/server/releases/release-service");

  assert("id.safe_accepts_stable", isSafePackageId(STABLE_PACKAGE_ID), STABLE_PACKAGE_ID);
  assert("id.safe_rejects_traversal", !isSafePackageId("../etc/passwd") && !isSafePackageId("a/b"), "traversal blocked");
  assert("id.legacy_synthetic", isLegacySyntheticPackageId("rel_200_stable"), "rel_200_stable");

  const local = findLocalCommercialZip();
  assert(
    "zip.local_resolves",
    !!local && (local.includes("public") || local.includes("Releases")),
    local || "missing ZIP under public/releases or Commercial/Releases"
  );

  if (local && fs.existsSync(local)) {
    const buf = fs.readFileSync(local);
    const hash = createHash("sha256").update(buf).digest("hex");
    assert("zip.magic", buf[0] === 0x50 && buf[1] === 0x4b, `len=${buf.length}`);
    assert(
      "zip.sha256_matches_catalog",
      hash === STABLE_SHA256,
      `expected ${STABLE_SHA256.slice(0, 12)}… got ${hash.slice(0, 12)}…`
    );
    assert(
      "zip.size_sensible",
      buf.length === STABLE_SIZE_BYTES || buf.length > 1_000_000,
      `size=${buf.length}`
    );

    // Spot-check Setup.exe presence via central directory names (uncompressed store or deflate)
    const asLatin = buf.toString("binary");
    assert(
      "zip.contains_setup",
      asLatin.includes("Setup.exe") || asLatin.includes("setup.exe"),
      "Setup.exe entry expected in commercial ZIP"
    );
  }

  clearReleaseStoreCache();
  const store = readReleaseStore();
  const published = store.packages.filter((p) => p.status === "published" && p.channel === "stable");
  assert("catalog.stable_published", published.length >= 1, `count=${published.length}`);
  assert(
    "catalog.latest_is_100",
    published[0]?.id === STABLE_PACKAGE_ID || published[0]?.version === "1.0.0",
    `${published[0]?.id} ${published[0]?.version}`
  );
  assert(
    "catalog.legacy_yanked",
    !store.packages.some((p) => p.id === "rel_200_stable" && p.status === "published"),
    "synthetic 2.0.0 must not remain published"
  );

  const listed = listPublished("stable");
  assert("list.stable_only", listed.every((p) => p.channel === "stable"), `n=${listed.length}`);

  const checkUpToDate = checkForUpdate({ channel: "stable", version: "1.0.0", email: "qa@example.com" });
  assert("check.up_to_date", checkUpToDate.updateAvailable === false, JSON.stringify(checkUpToDate.latest?.version));
  assert("check.top_level_downloadUrl", typeof checkUpToDate.downloadUrl === "string" && !!checkUpToDate.downloadUrl, checkUpToDate.downloadUrl || "missing");
  assert("check.nested_latest_id", checkUpToDate.latest?.id === STABLE_PACKAGE_ID, checkUpToDate.latest?.id || "missing");

  const checkNeedUpdate = checkForUpdate({ channel: "stable", version: "0.9.0" });
  assert("check.update_available", checkNeedUpdate.updateAvailable === true && checkNeedUpdate.available === true, "0.9.0 → 1.0.0");

  assert("semver.order", compareSemver("1.0.0", "0.9.0") > 0 && compareSemver("2.0.0", "1.0.0") > 0, "ok");

  const packed = await getPackageBytes(STABLE_PACKAGE_ID);
  assert("download.bytes_present", !!packed && packed.buffer.length > 1000, packed ? `len=${packed.buffer.length}` : "null");
  if (packed) {
    assert(
      "download.content_type_shape",
      packed.package.packageFile.endsWith(".zip") && packed.buffer[0] === 0x50,
      packed.package.packageFile
    );
    recordDownload(STABLE_PACKAGE_ID, "qa@example.com", "203.0.113.10");
    const hist = readReleaseStore().downloadEvents.filter((d) => d.email === "qa@example.com");
    assert("download.history_recorded", hist.length >= 1 && hist[0].ipMasked.endsWith(".***"), hist[0]?.ipMasked || "none");
  }

  assert("download.rejects_bad_id", (await getPackageBytes("../secret")) === null, "path id rejected");
  assert("download.rejects_yanked", (await getPackageBytes("rel_200_stable")) === null, "yanked not served");

  const meta = buildStableReleasePackage("http://localhost:3000");
  assert("meta.package_url", meta.packageUrl.includes(`/api/releases/download/${meta.id}`), meta.packageUrl);

  // Assets on disk for deploy path
  assert(
    "asset.public_or_commercial_exists",
    fs.existsSync(publicZip) || fs.existsSync(commercialZip),
    `public=${fs.existsSync(publicZip)} commercial=${fs.existsSync(commercialZip)}`
  );

  // Reported installed version stays null until success telemetry
  assert("updates.reported_null", getReportedInstalledVersion("nobody@example.com") === null, "ok");

  const failed = results.filter((r) => !r.pass);
  for (const r of results) {
    console.log(`${r.pass ? "PASS" : "FAIL"}  ${r.name} — ${r.notes}`);
  }
  console.log(`\n${results.length - failed.length}/${results.length} passed`);
  if (failed.length) process.exit(1);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
