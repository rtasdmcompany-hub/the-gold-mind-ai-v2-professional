import type { MetadataRoute } from "next";

const BASE = process.env.NEXTAUTH_URL || "https://the-gold-mind-ai-v2-professional.vercel.app";

export default function robots(): MetadataRoute.Robots {
  return {
    rules: {
      userAgent: "*",
      allow: "/",
      disallow: ["/portal/", "/api/", "/portal/admin/"],
    },
    sitemap: `${BASE}/sitemap.xml`,
  };
}
