import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  poweredByHeader: false,
  compress: true,
  // Keep commercial installer ZIP inside the download serverless function FS on Vercel.
  outputFileTracingIncludes: {
    "/api/releases/download/[id]": ["./public/releases/**/*"],
    "/api/releases/download/*": ["./public/releases/**/*"],
  },
  images: {
    formats: ["image/avif", "image/webp"],
    deviceSizes: [640, 750, 828, 1080, 1200, 1920],
    imageSizes: [16, 32, 48, 64, 96, 128, 180, 256],
    remotePatterns: [
      { protocol: "https", hostname: "lh3.googleusercontent.com", pathname: "/**" },
    ],
  },
  experimental: {
    optimizePackageImports: ["@/components/enterprise"],
  },
};

export default nextConfig;
