import type { MetadataRoute } from "next";
import { brand } from "@/lib/brand";

const BASE = process.env.NEXTAUTH_URL || brand.website;

const PUBLIC_PATHS = [
  "",
  "/about",
  "/company",
  "/technology",
  "/infrastructure",
  "/security",
  "/pricing",
  "/docs",
  "/contact",
  "/login",
  "/register",
  "/privacy",
  "/terms",
  "/eula",
  "/cookies",
  "/refund",
  "/disclaimer",
  "/risk",
  "/developers",
  "/partners/apply",
];

export default function sitemap(): MetadataRoute.Sitemap {
  const now = new Date();
  return PUBLIC_PATHS.map((path) => ({
    url: `${BASE}${path}`,
    lastModified: now,
    changeFrequency: path === "" ? "weekly" : "monthly",
    priority: path === "" ? 1 : 0.7,
  }));
}
