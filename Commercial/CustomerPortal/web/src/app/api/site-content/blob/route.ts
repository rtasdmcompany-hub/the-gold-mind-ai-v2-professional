import { handleUpload, type HandleUploadBody } from "@vercel/blob/client";
import { NextResponse } from "next/server";
import { auth } from "@/auth";
import { hasPermission } from "@/server/admin/roles";
import { isDevAdminBypass } from "@/server/security/dev-bypass";

export const dynamic = "force-dynamic";
export const runtime = "nodejs";

/**
 * Client-direct Blob upload token endpoint.
 * Browser uploads videos/images straight to Vercel Blob (bypasses 4.5MB function body limit).
 */
export async function POST(request: Request): Promise<NextResponse> {
  const session = await auth();
  const email = session?.user?.email?.toLowerCase() || "";
  const role = (session?.user as { role?: string } | undefined)?.role;
  if (!hasPermission(role, "admin.launch.write") && !isDevAdminBypass(email)) {
    return NextResponse.json({ error: "Forbidden" }, { status: 403 });
  }

  if (!(process.env.BLOB_READ_WRITE_TOKEN || "").trim()) {
    return NextResponse.json(
      {
        error:
          "BLOB_READ_WRITE_TOKEN missing. Create a Vercel Blob store and reconnect the project.",
      },
      { status: 503 }
    );
  }

  let body: HandleUploadBody;
  try {
    body = (await request.json()) as HandleUploadBody;
  } catch {
    return NextResponse.json({ error: "Invalid JSON body" }, { status: 400 });
  }

  try {
    const jsonResponse = await handleUpload({
      body,
      request,
      onBeforeGenerateToken: async () => {
        // Re-check auth at token mint time.
        const s = await auth();
        const em = s?.user?.email?.toLowerCase() || "";
        const r = (s?.user as { role?: string } | undefined)?.role;
        if (!hasPermission(r, "admin.launch.write") && !isDevAdminBypass(em)) {
          throw new Error("Forbidden");
        }
        return {
          allowedContentTypes: [
            "video/mp4",
            "video/webm",
            "image/jpeg",
            "image/png",
            "image/webp",
            "image/gif",
            // Some phone editors send empty/octet-stream; allow then validate by extension client-side.
            "application/octet-stream",
          ],
          addRandomSuffix: true,
          maximumSizeInBytes: 80 * 1024 * 1024,
          tokenPayload: JSON.stringify({ email: em || "admin" }),
        };
      },
      onUploadCompleted: async () => {
        // No DB write required — admin pastes/uses returned URL into CMS fields.
      },
    });
    return NextResponse.json(jsonResponse);
  } catch (error) {
    return NextResponse.json(
      { error: error instanceof Error ? error.message : "Blob upload failed" },
      { status: 400 }
    );
  }
}
