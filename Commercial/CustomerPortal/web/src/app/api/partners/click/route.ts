import { NextResponse } from "next/server";
import { recordReferralClick } from "@/server/partners/affiliate";

/** POST /api/partners/click — public click beacon (hashed visitor) */
export async function POST(req: Request) {
  try {
    const body = (await req.json()) as {
      referralCode?: string;
      visitorKey?: string;
      landingPath?: string;
      campaignId?: string;
    };
    if (!body.referralCode || !body.visitorKey) {
      return NextResponse.json({ ok: false, error: "MISSING_FIELDS" }, { status: 400 });
    }
    const click = recordReferralClick({
      referralCode: body.referralCode,
      visitorKey: body.visitorKey,
      landingPath: body.landingPath,
      campaignId: body.campaignId,
      ip: req.headers.get("x-forwarded-for") || undefined,
    });
    return NextResponse.json({
      ok: true,
      clickId: click.id,
      cookieDays: 30,
      note: "Set first-party cookie ref locally; Core never involved",
    });
  } catch (e) {
    return NextResponse.json(
      { ok: false, error: e instanceof Error ? e.message : "CLICK_FAIL" },
      { status: 400 }
    );
  }
}
