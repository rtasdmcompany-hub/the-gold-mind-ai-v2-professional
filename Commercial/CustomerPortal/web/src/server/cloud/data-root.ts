/**
 * Writable commercial data root for Node runtimes.
 * On Vercel/serverless the deploy FS is read-only — use /tmp (or COMMERCIAL_DATA_ROOT under /tmp).
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

function tmpCommercialBase(): string {
  return path.join("/tmp", "tgm-commercial-data");
}

function canUseDir(dir: string): boolean {
  try {
    if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
    const probe = path.join(dir, ".write-probe");
    fs.writeFileSync(probe, "ok", "utf8");
    fs.unlinkSync(probe);
    return true;
  } catch {
    return false;
  }
}

/**
 * Resolve a writable directory for commercial file stores.
 * Serverless always prefers /tmp — configured roots outside /tmp are ignored on Vercel.
 */
export function commercialDataRoot(...segments: string[]): string {
  const configured = (process.env.COMMERCIAL_DATA_ROOT || "").trim();
  const serverless = isServerlessRuntime();

  let base: string;
  if (configured) {
    const abs = path.isAbsolute(configured) ? configured : path.resolve(process.cwd(), configured);
    // On serverless, only honor configured roots that live under /tmp.
    if (serverless && !abs.startsWith("/tmp")) {
      base = tmpCommercialBase();
    } else {
      base = abs;
    }
  } else if (serverless) {
    base = tmpCommercialBase();
  } else {
    base = path.join(process.cwd(), ".data");
  }

  const dir = path.join(base, ...segments);
  if (!canUseDir(dir)) {
    const fallback = path.join(tmpCommercialBase(), ...segments);
    if (!canUseDir(fallback)) {
      // Last resort: return fallback path even if probe failed (caller may be read-only).
      try {
        fs.mkdirSync(fallback, { recursive: true });
      } catch {
        /* ignore */
      }
      return fallback;
    }
    return fallback;
  }
  return dir;
}
