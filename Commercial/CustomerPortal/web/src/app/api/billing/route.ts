import { NextResponse } from "next/server";
import { requireSession } from "@/server/licensing/session";
import { startCheckout, getBillingSummary, PLAN_CATALOG } from "@/server/billing/billing-service";
import type { PlanCode, PaymentProviderId } from "@/server/billing/types";
import { listProviders } from "@/server/billing/payment-port";

export async function GET() {
  try {
    const s = await requireSession();
    const summary = getBillingSummary(s.email);
    return NextResponse.json({
      edition: "Professional_Website",
      catalog: PLAN_CATALOG,
      providers: listProviders().filter((p) => p !== "stripe"),
      ...summary,
    });
  } catch (e) {
    const msg = e instanceof Error ? e.message : "ERROR";
    return NextResponse.json({ error: msg }, { status: msg === "UNAUTHORIZED" ? 401 : 500 });
  }
}

export async function POST(req: Request) {
  try {
    const s = await requireSession();
    const body = await req.json();
    if (body.action === "checkout") {
      const plan = body.plan as PlanCode;
      if (!PLAN_CATALOG[plan]) {
        return NextResponse.json({ error: "INVALID_PLAN" }, { status: 400 });
      }
      const session = await startCheckout({
        plan,
        customerEmail: s.email,
        customerName: s.name,
        successUrl: `${process.env.NEXTAUTH_URL || ""}/portal/billing?ok=1`,
        cancelUrl: `${process.env.NEXTAUTH_URL || ""}/portal/billing?cancel=1`,
        provider: body.provider as PaymentProviderId | undefined,
      });
      return NextResponse.json({ checkout: session });
    }
    return NextResponse.json({ error: "UNKNOWN_ACTION" }, { status: 400 });
  } catch (e) {
    const msg = e instanceof Error ? e.message : "ERROR";
    return NextResponse.json({ error: msg }, { status: msg === "UNAUTHORIZED" ? 401 : 500 });
  }
}
