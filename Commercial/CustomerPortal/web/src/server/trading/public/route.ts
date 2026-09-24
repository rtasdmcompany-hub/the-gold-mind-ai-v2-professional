import { NextResponse } from "next/server";
import { getPublicTradingDashboard } from "@/server/trading/service";
import { ensureTradingStoreLoaded } from "@/server/trading/store";

export async function GET() {
  try {
    await ensureTradingStoreLoaded();
    const dashboard = getPublicTradingDashboard();
    
    if (!dashboard || !dashboard.account) {
      return NextResponse.json(
        { ok: false, error: "NO_DATA_SYNCED_YET" }, 
        { status: 404 }
      );
    }
    
    return NextResponse.json({ ok: true, data: dashboard });
  } catch (e) {
    console.error("[Public Trading API Error]:", e);
    return NextResponse.json(
      { ok: false, error: "INTERNAL_ERROR" }, 
      { status: 500 }
    );
  }
}