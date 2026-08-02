import { NextResponse } from "next/server";
import { auth } from "@/auth";
import { hasPermission } from "@/server/admin/roles";
import { isDevAdminBypass } from "@/server/security/dev-bypass";
import { ensureMediaStoreLoaded, flushSiteContent } from "@/server/site-content/store";
import { mediaUploadHints, uploadSiteMedia } from "@/server/site-content/media";

export const dynamic = "force-dynamic";
export const runtime = "nodejs";

export async function GET() {
  const session = await auth();
  const email = session?.user?.email?.toLowerCase() || "";
  const role = (session?.user as { role?: string } | undefined)?.role;
  if (!hasPermission(role, "admin.launch.read") && !isDevAdminBypass(email)) {
    return NextResponse.json({ ok: false, error: "Forbidden" }, { status: 403 });
  }
  return NextResponse.json({ ok: true, ...mediaUploadHints() });
}

export async function POST(req: Request) {
  const session = await auth();
  const email = session?.user?.email?.toLowerCase() || "";
  const role = (session?.user as { role?: string } | undefined)?.role;
  if (!hasPermission(role, "admin.launch.write") && !isDevAdminBypass(email)) {
    return NextResponse.json({ ok: false, error: "Forbidden" }, { status: 403 });
  }

  await ensureMediaStoreLoaded();

  let form: FormData;
  try {
    form = await req.formData();
  } catch {
    return NextResponse.json({ ok: false, error: "Expected multipart form data" }, { status: 400 });
  }

  const file = form.get("file");
  if (!(file instanceof File)) {
    return NextResponse.json({ ok: false, error: "Missing file field" }, { status: 400 });
  }

  const buf = Buffer.from(await file.arrayBuffer());
  const result = await uploadSiteMedia({
    filename: file.name || "upload.bin",
    contentType: file.type || "application/octet-stream",
    bytes: buf,
  });
  await flushSiteContent();

  if (!result.ok) {
    return NextResponse.json(result, { status: 400 });
  }
  return NextResponse.json(result);
}
