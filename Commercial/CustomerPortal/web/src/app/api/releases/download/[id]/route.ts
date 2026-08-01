import { NextResponse } from "next/server";
import { auth } from "@/auth";
import { getPackageBytes, recordDownload } from "@/server/releases/release-service";
import { canAccessAdminConsole } from "@/server/admin/roles";
import { isReleaseDownloadAuthRequired } from "@/server/security/dev-bypass";
import { isSafePackageId } from "@/server/releases/commercial-source";

/**
 * Secure package download — serves verified ZIP whose SHA-256 matches catalog.
 * Customers: stable channel only. RC / development require Admin Console role.
 * Package id is catalog-bound only (no arbitrary filesystem reads).
 */
export async function GET(
  req: Request,
  ctx: { params: Promise<{ id: string }> }
) {
  const { id } = await ctx.params;
  if (!isSafePackageId(id)) {
    return NextResponse.json({ error: "INVALID_PACKAGE_ID" }, { status: 400 });
  }

  let packed: Awaited<ReturnType<typeof getPackageBytes>> = null;
  let loadError: string | undefined;
  try {
    packed = await getPackageBytes(id);
  } catch (e) {
    loadError = e instanceof Error ? e.message : "PACKAGE_LOAD_FAILED";
  }
  if (!packed) {
    return NextResponse.json(
      {
        error: loadError ? "PACKAGE_UNAVAILABLE" : "NOT_FOUND",
        message: loadError || "Release package was not found in the catalog.",
        id,
      },
      { status: 404 }
    );
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
