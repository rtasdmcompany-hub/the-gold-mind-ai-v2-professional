import type { Metadata } from "next";
import { brand } from "@/lib/brand";

/** Shared Next.js metadata builders — always derived from `@/lib/brand`. */
export function brandRootMetadata(): Metadata {
  return {
    metadataBase: new URL(brand.website),
    title: {
      default: brand.productFullName,
      template: `%s · ${brand.productName}`,
    },
    description: brand.description,
    applicationName: brand.productFullName,
    authors: [{ name: brand.productName }],
    creator: brand.productName,
    publisher: brand.productName,
    keywords: [
      brand.brandName,
      brand.productName,
      "MetaTrader 5",
      "Expert Advisor",
      "automated trading",
      "Customer Portal",
    ],
    manifest: "/manifest.webmanifest",
    icons: {
      icon: [
        { url: brand.assets.favicon },
        { url: brand.assets.icon32, sizes: "32x32", type: "image/png" },
        { url: brand.assets.icon192, sizes: "192x192", type: "image/png" },
      ],
      apple: [{ url: brand.assets.icon180, sizes: "180x180", type: "image/png" }],
    },
    openGraph: {
      title: brand.productFullName,
      description: brand.ogDescription,
      type: "website",
      siteName: brand.productFullName,
      images: [
        {
          url: brand.assets.og,
          width: 1200,
          height: 630,
          alt: `${brand.brandName} ${brand.tagline}`,
        },
      ],
    },
    twitter: {
      card: "summary_large_image",
      title: brand.productFullName,
      description: `Official website and Customer Portal for ${brand.brandName}.`,
      images: [brand.assets.twitter],
    },
  };
}

export function brandPageMetadata(input: {
  title: string;
  description: string;
}): Metadata {
  return {
    title: input.title,
    description: input.description,
  };
}
