import { NextResponse } from "next/server";
import { auth } from "@/auth";
import { getPackageBytes, recordDownload } from "@/server/releases/release-service";
import { isReleaseDownloadAuthRequired } from "@/server/security/dev-bypass";

/**
 * Secure package download — serves verified ZIP whose SHA-256 matches catalog.
 * Production default: session required (RELEASE_DOWNLOAD_AUTH=public to open).
 * Never ships Trading Engine source.
 */
export async function GET(
  req: Request,
  ctx: { params: Promise<{ id: string }> }
) {
  const { id } = await ctx.params;
  const packed = getPackageBytes(id);
  if (!packed) {
    return NextResponse.json({ error: "NOT_FOUND" }, { status: 404 });
  }
  const { buffer, package: pkg } = packed;

  const proto = req.headers.get("x-forwarded-proto");
  if (process.env.NODE_ENV === "production" && proto && proto !== "https") {
    return NextResponse.json({ error: "HTTPS_REQUIRED" }, { status: 403 });
  }

  const session = await auth();
  if (isReleaseDownloadAuthRequired() && !session?.user?.email) {
    return NextResponse.json({ error: "AUTHENTICATION_REQUIRED" }, { status: 401 });
  }

  const ip = req.headers.get("x-forwarded-for")?.split(",")[0]?.trim() || "127.0.0.1";
  recordDownload(id, session?.user?.email || undefined, ip);

  const body = new Uint8Array(buffer);
  return new NextResponse(body, {
    status: 200,
    headers: {
      "Content-Type": "application/zip",
      "Content-Length": String(buffer.length),
      "Content-Disposition": `attachment; filename="${pkg.packageFile}"`,
      "X-TGM-SHA256": pkg.sha256,
      "X-TGM-Signature-Status": pkg.signatureStatus,
      "X-TGM-Signature-Subject": pkg.signatureSubject,
      "X-TGM-Channel": pkg.channel,
      "X-TGM-Version": pkg.version,
      "X-TGM-Build": pkg.buildNumber,
      "Cache-Control": "no-store",
    },
  });
}
