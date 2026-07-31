/**
 * Resolve the portal's public base URL for checkout success/cancel and
 * sandbox redirect links. Production must never fall back to localhost.
 */
import { brand } from "@/lib/brand";
export function resolveBaseUrl(): string {
  const explicit = (process.env.AUTH_URL || process.env.NEXTAUTH_URL || "").trim();
  if (explicit) return explicit.replace(/\/$/, "");

  const vercelUrl = (process.env.VERCEL_PROJECT_PRODUCTION_URL || process.env.VERCEL_URL || "").trim();
  if (vercelUrl) return `https://${vercelUrl.replace(/^https?:\/\//, "")}`;

  if (process.env.NODE_ENV === "production") {
    return brand.website;
  }
  return "http://localhost:3000";
}
