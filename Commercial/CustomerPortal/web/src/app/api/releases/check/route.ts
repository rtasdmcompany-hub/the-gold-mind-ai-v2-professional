import { NextResponse } from "next/server";
import { auth } from "@/auth";
import { checkForUpdate, listPublished } from "@/server/releases/release-service";
import { canAccessAdminConsole } from "@/server/admin/roles";
import type { ReleaseChannel } from "@/server/releases/types";

/**
 * Public updater/check endpoint — customers are stable-only. RC / development
 * channels are only honored for authenticated Admin Console roles.
 */
export async function GET(req: Request) {
  const url = new URL(req.url);
  const requestedChannel = (url.searchParams.get("channel") || "stable") as ReleaseChannel;
  const version = url.searchParams.get("version") || "0.0.0";
  const session = await auth();
  const role = (session?.user as { role?: string } | undefined)?.role;
  const channel: ReleaseChannel = canAccessAdminConsole(role) ? requestedChannel : "stable";
  const result = checkForUpdate({
    channel,
    version,
    email: session?.user?.email || undefined,
  });
  return NextResponse.json(result);
}

export async function POST() {
  const session = await auth();
  const role = (session?.user as { role?: string } | undefined)?.role;
  const isAdmin = canAccessAdminConsole(role);
  return NextResponse.json({ packages: listPublished(isAdmin ? undefined : "stable") });
}
