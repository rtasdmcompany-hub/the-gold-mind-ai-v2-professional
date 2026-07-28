import { NextResponse } from "next/server";
import { authenticateTradingCaller, parseTradingAuthFromRequest } from "@/server/trading/auth";
import { applyTradingSync, type SyncTradeInput } from "@/server/trading/service";
import { handleTradeClosedNotification } from "@/server/notifications/trade-alerts";

/**
 * POST /api/trading/sync
 *
 * EA / local agent heartbeat: upsert MT5 account snapshot + open positions + recent closed deals.
 * Auth (one of):
 *   - Authorization: Bearer <activation validation token>
 *   - body.email + body.deviceFingerprint (active device)
 *   - body.email + body.licenseKey
 * Optional: x-tgm-notify-secret / body.notifySecret when TRADE_NOTIFY_SECRET is set.
 * Optional: body.notifyClosed=true — email newly closed deals (default false; prefer /api/notifications/trade-closed on deal close).
 */
export async function POST(req: Request) {
  try {
    const body = (await req.json().catch(() => ({}))) as Record<string, unknown>;
    const notifySecret =
      req.headers.get("x-tgm-notify-secret") ||
      String(body.notifySecret || "").trim() ||
      undefined;

    const expectedSecret = (process.env.TRADE_NOTIFY_SECRET || "").trim();
    if (expectedSecret) {
      if (!notifySecret || notifySecret !== expectedSecret) {
        return NextResponse.json({ ok: false, error: "INVALID_NOTIFY_SECRET" }, { status: 401 });
      }
    }

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

    const identity = await authenticateTradingCaller(auth);
    if (!identity.ok) {
      return NextResponse.json({ ok: false, error: identity.error }, { status: identity.status });
    }

    const accountRaw =
      body.account && typeof body.account === "object"
        ? (body.account as Record<string, unknown>)
        : body;
    const accountNumber = accountRaw.accountNumber ?? accountRaw.login ?? accountRaw.accountLogin;
    if (accountNumber == null || String(accountNumber).trim() === "") {
      return NextResponse.json({ ok: false, error: "MISSING_ACCOUNT_NUMBER" }, { status: 400 });
    }

    const openPositions = asTradeArray(body.openPositions ?? body.positions);
    const closedDeals = asTradeArray(body.closedDeals ?? body.deals ?? body.history);

    const result = await applyTradingSync({
      customerEmail: identity.email,
      account: {
        accountNumber: String(accountNumber),
        balance: Number(accountRaw.balance ?? 0),
        equity: Number(accountRaw.equity ?? accountRaw.balance ?? 0),
        currency: accountRaw.currency != null ? String(accountRaw.currency) : undefined,
        serverName: accountRaw.serverName != null ? String(accountRaw.serverName) : undefined,
      },
      openPositions,
      closedDeals,
    });

    const notifyClosed = body.notifyClosed === true || body.notifyClosed === "true";
    let emailed = 0;
    let emailSkipped = 0;
    if (notifyClosed && result.newlyClosed.length > 0) {
      for (const trade of result.newlyClosed) {
        const notify = await handleTradeClosedNotification({
          auth,
          trade: {
            symbol: trade.symbol,
            side: trade.type,
            ticket: trade.ticket,
            profit: trade.profit,
            volume: trade.volume,
            openTime: trade.openTime,
            closeTime: trade.closeTime || undefined,
            comment: trade.comment,
            accountLogin: trade.accountNumber,
          },
          notifySecret,
        });
        if (notify.ok && notify.emailed) emailed += 1;
        else if (notify.ok && notify.skipped) emailSkipped += 1;
      }
    }

    return NextResponse.json({
      ok: true,
      account: result.account,
      openCount: result.openCount,
      closedCount: result.closedCount,
      newlyClosed: result.newlyClosed.length,
      emailed,
      emailSkipped,
    });
  } catch (e) {
    const msg = e instanceof Error ? e.message : "ERROR";
    return NextResponse.json({ ok: false, error: msg }, { status: 500 });
  }
}

function asTradeArray(raw: unknown): SyncTradeInput[] {
  if (!Array.isArray(raw)) return [];
  return raw.map((item) => {
    const r = (item && typeof item === "object" ? item : {}) as Record<string, unknown>;
    return {
      ticket: (r.ticket ?? r.positionTicket ?? r.deal ?? "") as string | number,
      symbol: r.symbol != null ? String(r.symbol) : undefined,
      type: r.type != null ? String(r.type) : undefined,
      side: r.side != null ? String(r.side) : undefined,
      volume: r.volume != null ? Number(r.volume) : undefined,
      openTime: r.openTime != null ? String(r.openTime) : undefined,
      closeTime: r.closeTime != null ? String(r.closeTime) : null,
      profit: r.profit != null ? Number(r.profit) : undefined,
      status: r.status != null ? String(r.status) : undefined,
      comment: r.comment != null ? String(r.comment) : undefined,
    };
  });
}
