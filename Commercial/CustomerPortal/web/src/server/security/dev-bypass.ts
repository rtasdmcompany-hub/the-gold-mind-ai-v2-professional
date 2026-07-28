/**
 * Dev-only privilege bypass helpers.
 * Production: email shortcuts never skip RBAC unless PORTAL_ALLOW_DEV_BYPASS=true.
 * Never affects Core Trading Engine.
 */
export const DEV_ADMIN_EMAIL = "admin@goldmind.local";

export function isProductionRuntime(): boolean {
  return process.env.NODE_ENV === "production";
}

/** True only for the local RC superuser shortcut outside production (or explicit override). */
export function isDevAdminBypass(email: string | null | undefined): boolean {
  if (!email || email.toLowerCase() !== DEV_ADMIN_EMAIL) return false;
  if (isProductionRuntime() && process.env.PORTAL_ALLOW_DEV_BYPASS !== "true") {
    return false;
  }
  return true;
}

/**
 * Demo credentials provider — permanently disabled.
 * Use verified email/password accounts or Google OAuth instead.
 */
export function shouldEnableDemoAuth(_unused?: boolean): boolean {
  void _unused;
  return false;
}

export function isReleaseDownloadAuthRequired(): boolean {
  const mode = (process.env.RELEASE_DOWNLOAD_AUTH || "").toLowerCase();
  if (mode === "public") return false;
  if (mode === "required" || mode === "session") return true;
  return isProductionRuntime();
}
