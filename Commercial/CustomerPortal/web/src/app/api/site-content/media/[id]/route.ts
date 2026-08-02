import { NextResponse } from "next/server";
import {
  ensureMediaStoreLoaded,
  getStoredMedia,
} from "@/server/site-content/store";

export const dynamic = "force-dynamic";
export const runtime = "nodejs";

export async function GET(
  _req: Request,
  ctx: { params: Promise<{ id: string }> }
) {
  const { id } = await ctx.params;
  const safe = String(id || "").replace(/[^a-zA-Z0-9_-]/g, "");
  if (!safe || safe !== id) {
    return NextResponse.json({ ok: false, error: "Invalid id" }, { status: 400 });
  }

  await ensureMediaStoreLoaded();
  const item = getStoredMedia(safe);
  if (!item) {
    return NextResponse.json({ ok: false, error: "Not found" }, { status: 404 });
  }

  const bytes = Buffer.from(item.base64, "base64");
  return new NextResponse(bytes, {
    status: 200,
    headers: {
      "Content-Type": item.contentType,
      "Content-Length": String(bytes.length),
      "Cache-Control": "public, max-age=86400, immutable",
      "Content-Disposition": `inline; filename="${item.filename}"`,
    },
  });
}
