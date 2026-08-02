import { NextResponse } from "next/server";
import {
  ensureSiteContentLoaded,
  getPublicSiteContent,
  isSiteContentDurable,
} from "@/server/site-content/store";

export const dynamic = "force-dynamic";
export const runtime = "nodejs";

/** Public marketing content (phone ads, hero, logos, header/footer copy). */
export async function GET() {
  await ensureSiteContentLoaded();
  const content = getPublicSiteContent();
  return NextResponse.json(
    {
      ok: true,
      durable: isSiteContentDurable(),
      ...content,
    },
    {
      headers: {
        "Cache-Control": "public, max-age=30, stale-while-revalidate=120",
      },
    }
  );
}
