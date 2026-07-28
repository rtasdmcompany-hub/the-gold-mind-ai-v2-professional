import { NextResponse } from "next/server";
import {
  handleTradeClosedNotification,
  type TradeClosedPayload,
} from "@/server/notifications/trade-alerts";
import { parseTradingAuthFromRequest } from "@/server/trading/auth";

/**
 * POST /api/notifications/trade-closed
 *
 * Called by EA / local agent after a position closes (profit or loss).
 * Auth (one of):
 *   - Authorization: Bearer <activation validation token>
 *   - body.email + body.deviceFingerprint (active device)
 *   - body.email + body.licenseKey
 * Optional: x-tgm-notify-secret / body.notifySecret when TRADE_NOTIFY_SECRET is set.
 * Respects account tradeAlertsEnabled preference (default ON).
 */
export async function POST(req: Request) {
  try {
    const body = (await req.json().catch(() => ({}))) as Record<string, unknown>;
    const notifySecret =
      req.headers.get("x-tgm-notify-secret") ||
      String(body.notifySecret || "").trim() ||
      undefined;

    const bearer = req.headers.get("authorization")?.replace(/^Bearer\s+/i, "").trim();
    const auth = parseTradingAuthFromRequest({ bearer, body });

    if (!auth) {
      return NextResponse.json(
        {
          ok: false,
          error: "MISSING_AUTH",
          hint: "Provide Bearer token, or email+deviceFingerprint, or email+licenseKey",
        },
        { status: 401 }
      );
    }

    const tradeRaw = (body.trade && typeof body.trade === "object" ? body.trade : body) as Record<
      string,
      unknown
    >;
    const trade: TradeClosedPayload = {
      symbol: tradeRaw.symbol != null ? String(tradeRaw.symbol) : undefined,
      side:
        tradeRaw.side != null
          ? String(tradeRaw.side)
          : tradeRaw.type != null
            ? String(tradeRaw.type)
            : undefined,
      ticket: tradeRaw.ticket != null ? (tradeRaw.ticket as string | number) : undefined,
      profit: tradeRaw.profit != null ? Number(tradeRaw.profit) : undefined,
      volume: tradeRaw.volume != null ? Number(tradeRaw.volume) : undefined,
      openTime: tradeRaw.openTime != null ? String(tradeRaw.openTime) : undefined,
      closeTime: tradeRaw.closeTime != null ? String(tradeRaw.closeTime) : undefined,
      comment: tradeRaw.comment != null ? String(tradeRaw.comment) : undefined,
      accountLogin: tradeRaw.accountLogin != null ? String(tradeRaw.accountLogin) : undefined,
    };

    const result = await handleTradeClosedNotification({
      auth,
      trade,
      notifySecret: notifySecret || undefined,
    });

    if (!result.ok) {
      return NextResponse.json({ ok: false, error: result.error }, { status: result.status });
    }

    return NextResponse.json({
      ok: true,
      emailed: result.emailed,
      skipped: result.skipped,
    });
  } catch (e) {
    const msg = e instanceof Error ? e.message : "ERROR";
    return NextResponse.json({ ok: false, error: msg }, { status: 500 });
  }
}
