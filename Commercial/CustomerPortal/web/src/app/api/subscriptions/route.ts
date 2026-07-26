import { NextResponse } from "next/server";
import { requireSession } from "@/server/licensing/session";
import { listSubscriptionsForCustomer } from "@/server/licensing/subscription-service";

export async function GET() {
  try {
    const s = await requireSession();
    return NextResponse.json({ subscriptions: listSubscriptionsForCustomer(s.email) });
  } catch (e) {
    const msg = e instanceof Error ? e.message : "ERROR";
    return NextResponse.json({ error: msg }, { status: msg === "UNAUTHORIZED" ? 401 : 500 });
  }
}
