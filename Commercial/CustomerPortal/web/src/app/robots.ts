import type { MetadataRoute } from "next";
import { brand } from "@/lib/brand";

const BASE = process.env.NEXTAUTH_URL || brand.website;

export default function robots(): MetadataRoute.Robots {
  return {
    rules: {
      userAgent: "*",
      allow: "/",
      disallow: ["/portal/", "/api/", "/releases/"],
    },
    sitemap: `${BASE}/sitemap.xml`,
  };
}
