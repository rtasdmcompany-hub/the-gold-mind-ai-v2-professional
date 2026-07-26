import { NextResponse } from "next/server";
import { auth } from "@/auth";
import { checkForUpdate, listPublished } from "@/server/releases/release-service";
import type { ReleaseChannel } from "@/server/releases/types";

export async function GET(req: Request) {
  const url = new URL(req.url);
  const channel = (url.searchParams.get("channel") || "stable") as ReleaseChannel;
  const version = url.searchParams.get("version") || "0.0.0";
  const session = await auth();
  const result = checkForUpdate({
    channel,
    version,
    email: session?.user?.email || undefined,
  });
  return NextResponse.json(result);
}

export async function POST() {
  // list for portal
  return NextResponse.json({ packages: listPublished() });
}
