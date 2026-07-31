import type { MetadataRoute } from "next";
import { brand } from "@/lib/brand";

/** Dynamic web manifest — values come only from central brand config. */
export default function manifest(): MetadataRoute.Manifest {
  return {
    name: brand.productFullName,
    short_name: brand.brandName,
    description: brand.description,
    start_url: "/",
    display: "standalone",
    background_color: "#050505",
    theme_color: "#050505",
    icons: [
      {
        src: brand.assets.icon192,
        sizes: "192x192",
        type: "image/png",
      },
      {
        src: brand.assets.icon180,
        sizes: "180x180",
        type: "image/png",
      },
    ],
  };
}
