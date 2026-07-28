import { getAccountByEmail } from "@/server/accounts/store";
import { isTradeAlertsEnabled } from "@/server/accounts/service";
import { packageLabel, sendTransactionalEmail } from "@/server/accounts/mailer";
import { authenticateTradingCaller, type TradingCallerAuth } from "@/server/trading/auth";
import { persistClosedTrade } from "@/server/trading/service";

export type TradeClosedPayload = {
  symbol?: string;
  side?: string;
  ticket?: string | number;
  profit?: number;
  volume?: number;
  openTime?: string;
  closeTime?: string;
  comment?: string;
  accountLogin?: string;
};

export type TradeClosedAuth = TradingCallerAuth;

export type TradeClosedResult =
  | { ok: true; emailed: boolean; skipped?: string }
  | { ok: false; error: string; status: number };

/**
 * Authenticate caller, respect opt-out, send trade-close email via Resend.
 * EA / local agent should POST here after a position closes.
 */
export async function handleTradeClosedNotification(input: {
  auth: TradeClosedAuth;
  trade: TradeClosedPayload;
  notifySecret?: string;
}): Promise<TradeClosedResult> {
  const expectedSecret = (process.env.TRADE_NOTIFY_SECRET || "").trim();
  if (expectedSecret) {
    if (!input.notifySecret || input.notifySecret !== expectedSecret) {
      return { ok: false, error: "INVALID_NOTIFY_SECRET", status: 401 };
    }
  }

  const identity = await authenticateTradingCaller(input.auth);
  if (!identity.ok) return identity;

  const email = identity.email;
  const trade = input.trade;

  // Portal history always updates — notification opt-out must not hide trades.
  await persistClosedTrade({
    customerEmail: email,
    accountNumber: trade.accountLogin != null ? String(trade.accountLogin) : undefined,
    ticket: trade.ticket,
    symbol: trade.symbol,
    side: trade.side,
    volume: trade.volume,
    openTime: trade.openTime,
    closeTime: trade.closeTime,
    profit: trade.profit,
    comment: trade.comment,
  }).catch((e) => console.warn("[trade-alerts] portal persist failed:", e));

  const account = await getAccountByEmail(email);
  if (!isTradeAlertsEnabled(account)) {
    return { ok: true, emailed: false, skipped: "trade_alerts_disabled" };
  }
  const profit = typeof trade.profit === "number" ? trade.profit : Number(trade.profit);
  const outcome =
    Number.isFinite(profit) ? (profit >= 0 ? "Profit" : "Loss") : "Closed";
  const profitStr = Number.isFinite(profit)
    ? `${profit >= 0 ? "+" : ""}${profit.toFixed(2)}`
    : "n/a";
  const symbol = String(trade.symbol || "—").toUpperCase();
  const side = String(trade.side || "—").toUpperCase();
  const ticket = trade.ticket != null ? String(trade.ticket) : "—";

  const lic = identity.licenseType
    ? packageLabel(identity.licenseType)
    : undefined;

  const subject = `Trade closed · ${symbol} ${outcome} ${profitStr} — THE GOLD MIND PROFESSIONAL`;
  const text = [
    `Trade closed on your THE GOLD MIND PROFESSIONAL account.`,
    ``,
    `Account: ${email}`,
    lic ? `Package: ${lic}` : "",
    `Symbol: ${symbol}`,
    `Side: ${side}`,
    `Ticket: ${ticket}`,
    `Result: ${outcome} (${profitStr})`,
    trade.volume != null ? `Volume: ${trade.volume}` : "",
    trade.openTime ? `Opened: ${trade.openTime}` : "",
    trade.closeTime ? `Closed: ${trade.closeTime}` : "",
    trade.comment ? `Comment: ${trade.comment}` : "",
    trade.accountLogin ? `MT5 login: ${trade.accountLogin}` : "",
    ``,
    `Turn off trade emails anytime: Customer Portal → Account Settings.`,
    ``,
    `— THE GOLD MIND PROFESSIONAL`,
  ]
    .filter(Boolean)
    .join("\n");

  const html = `
    <p>A trade closed on your <strong>THE GOLD MIND PROFESSIONAL</strong> account.</p>
    <ul>
      <li><strong>Account:</strong> ${escapeHtml(email)}</li>
      ${lic ? `<li><strong>Package:</strong> ${escapeHtml(lic)}</li>` : ""}
      <li><strong>Symbol:</strong> ${escapeHtml(symbol)}</li>
      <li><strong>Side:</strong> ${escapeHtml(side)}</li>
      <li><strong>Ticket:</strong> ${escapeHtml(ticket)}</li>
      <li><strong>Result:</strong> ${escapeHtml(outcome)} (<code>${escapeHtml(profitStr)}</code>)</li>
      ${trade.volume != null ? `<li><strong>Volume:</strong> ${escapeHtml(String(trade.volume))}</li>` : ""}
      ${trade.openTime ? `<li><strong>Opened:</strong> ${escapeHtml(String(trade.openTime))}</li>` : ""}
      ${trade.closeTime ? `<li><strong>Closed:</strong> ${escapeHtml(String(trade.closeTime))}</li>` : ""}
      ${trade.comment ? `<li><strong>Comment:</strong> ${escapeHtml(String(trade.comment))}</li>` : ""}
    </ul>
    <p style="font-size:13px;color:#666">Turn off trade emails anytime in Customer Portal → Account Settings.</p>
  `;

  const sent = await sendTransactionalEmail({
    to: email,
    subject,
    html,
    text,
    template: "support_ticket",
  });

  return { ok: true, emailed: sent.ok, skipped: sent.ok ? undefined : "resend_unavailable" };
}

function escapeHtml(s: string): string {
  return s
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}
