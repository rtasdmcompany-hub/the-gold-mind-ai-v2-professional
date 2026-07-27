/**
 * Writable commercial data root for Node runtimes.
 * On Vercel/serverless the deploy FS is read-only — use /tmp (or COMMERCIAL_DATA_ROOT).
 * Never touches Trading Engine / Core.
 */
import fs from "fs";
import path from "path";

export function isServerlessRuntime(): boolean {
  return !!(
    process.env.VERCEL ||
    process.env.AWS_LAMBDA_FUNCTION_NAME ||
    process.env.COMMERCIAL_FORCE_TMP_DATA === "true"
  );
}

export function commercialDataRoot(...segments: string[]): string {
  const configured = (process.env.COMMERCIAL_DATA_ROOT || "").trim();
  const base = configured
    ? configured
    : isServerlessRuntime()
      ? path.join("/tmp", "tgm-commercial-data")
      : path.join(process.cwd(), ".data");
  const dir = path.join(base, ...segments);
  if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
  return dir;
}
