import { NextResponse } from "next/server";
import { auth } from "@/auth";
import { getPackageBytes, recordDownload } from "@/server/releases/release-service";
import { canAccessAdminConsole } from "@/server/admin/roles";
import { isReleaseDownloadAuthRequired } from "@/server/security/dev-bypass";

/**
 * Secure package download — serves verified commercial ZIP (or redirects to hosted asset).
 * Customers: stable channel only. RC / development require Admin Console role.
 */
export async function GET(
  req: Request,
  ctx: { params: Promise<{ id: string }> }
) {
  const { id } = await ctx.params;
  const packed = getPackageBytes(id);
  if (!packed) {
    return NextResponse.json(
      {
        error: "NOT_FOUND",
        message:
          "Release package unavailable. For production, set RELEASE_STABLE_ZIP_URL to the GitHub/Blob ZIP URL.",
      },
      { status: 404 }
    );
  }
  const { buffer, redirectUrl, package: pkg } = packed;

  const proto = req.headers.get("x-forwarded-proto");
  if (process.env.NODE_ENV === "production" && proto && proto !== "https") {
    return NextResponse.json({ error: "HTTPS_REQUIRED" }, { status: 403 });
  }

  const session = await auth();
  if (isReleaseDownloadAuthRequired() && !session?.user?.email) {
    return NextResponse.json({ error: "AUTHENTICATION_REQUIRED" }, { status: 401 });
  }

  const role = (session?.user as { role?: string } | undefined)?.role;
  const isAdmin = canAccessAdminConsole(role);
  if (pkg.channel !== "stable" && !isAdmin) {
    return NextResponse.json(
      { error: "CHANNEL_RESTRICTED", message: "Only stable releases are available in the Customer Portal." },
      { status: 403 }
    );
  }

  const ip = req.headers.get("x-forwarded-for")?.split(",")[0]?.trim() || "127.0.0.1";
  recordDownload(id, session?.user?.email || undefined, ip);

  // Hosted asset (GitHub Release / Vercel Blob / CDN) — auth already checked
  if (redirectUrl && !buffer) {
    return NextResponse.redirect(redirectUrl, 302);
  }

  if (!buffer) {
    return NextResponse.json(
      {
        error: "ASSET_UNAVAILABLE",
        message: "Set RELEASE_STABLE_ZIP_URL or place TGM_PROFESSIONAL_1.0.0_stable.zip on the release path.",
      },
      { status: 503 }
    );
  }

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
