import { nowIso } from "@/server/licensing/crypto";
import {
  ensureTradingStoreLoaded,
  flushTradingStore,
  listAccountsForCustomer,
  listTradesForCustomer,
  upsertAccountSnapshot,
  upsertTradeRecord,
} from "./store";
import type {
  TradingAccountSnapshot,
  TradingDashboard,
  TradingTodaySummary,
  TradeRecord,
  TradeSide,
  TradeStatus,
} from "./types";

export type SyncTradeInput = {
  ticket: string | number;
  symbol?: string;
  type?: string;
  side?: string;
  volume?: number;
  openTime?: string;
  closeTime?: string | null;
  profit?: number;
  status?: string;
  comment?: string;
};

export type TradingSyncInput = {
  customerEmail: string;
  account: {
    accountNumber: string | number;
    balance: number;
    equity: number;
    currency?: string;
    serverName?: string;
  };
  openPositions?: SyncTradeInput[];
  closedDeals?: SyncTradeInput[];
};

function normalizeSide(raw?: string): TradeSide {
  const s = String(raw || "").trim().toLowerCase();
  if (s === "sell" || s === "1" || s.includes("sell")) return "sell";
  return "buy";
}

function normalizeStatus(raw?: string, closeTime?: string | null): TradeStatus {
  const s = String(raw || "").trim().toLowerCase();
  if (s === "closed" || s === "close" || s === "deal") return "closed";
  if (s === "open" || s === "position") return "open";
  return closeTime ? "closed" : "open";
}

function toTradeRecord(
  email: string,
  accountNumber: string,
  row: SyncTradeInput,
  fallbackStatus: TradeStatus
): TradeRecord | null {
  const ticket = String(row.ticket ?? "").trim();
  if (!ticket) return null;
  const closeTime =
    row.closeTime == null || row.closeTime === ""
      ? null
      : String(row.closeTime);
  const status = normalizeStatus(row.status, closeTime) || fallbackStatus;
  const profit = Number(row.profit);
  return {
    ticket,
    accountNumber,
    customerEmail: email,
    symbol: String(row.symbol || "—").toUpperCase(),
    type: normalizeSide(row.side || row.type),
    volume: Number.isFinite(Number(row.volume)) ? Number(row.volume) : 0,
    openTime: String(row.openTime || nowIso()),
    closeTime: status === "closed" ? closeTime || nowIso() : null,
    profit: Number.isFinite(profit) ? profit : 0,
    status,
    comment: row.comment != null ? String(row.comment) : undefined,
    updatedAt: nowIso(),
  };
}

/** Persist a single closed trade (also used by trade-closed notification path). */
export async function persistClosedTrade(input: {
  customerEmail: string;
  accountNumber?: string;
  ticket?: string | number;
  symbol?: string;
  side?: string;
  type?: string;
  volume?: number;
  openTime?: string;
  closeTime?: string;
  profit?: number;
  comment?: string;
}): Promise<TradeRecord | null> {
  await ensureTradingStoreLoaded();
  const email = input.customerEmail.trim().toLowerCase();
  const ticket = input.ticket != null ? String(input.ticket).trim() : "";
  if (!email || !ticket) return null;

  const accounts = listAccountsForCustomer(email);
  const accountNumber =
    (input.accountNumber && String(input.accountNumber).trim()) ||
    accounts[0]?.accountNumber ||
    "unknown";

  const record = toTradeRecord(
    email,
    accountNumber,
    {
      ticket,
      symbol: input.symbol,
      side: input.side,
      type: input.type,
      volume: input.volume,
      openTime: input.openTime,
      closeTime: input.closeTime || nowIso(),
      profit: input.profit,
      status: "closed",
      comment: input.comment,
    },
    "closed"
  );
  if (!record) return null;
  const saved = upsertTradeRecord(record);
  await flushTradingStore();
  return saved;
}

export async function applyTradingSync(input: TradingSyncInput): Promise<{
  ok: true;
  account: TradingAccountSnapshot;
  openCount: number;
  closedCount: number;
  newlyClosed: TradeRecord[];
}> {
  await ensureTradingStoreLoaded();
  const email = input.customerEmail.trim().toLowerCase();
  const accountNumber = String(input.account.accountNumber).trim();
  if (!email || !accountNumber) {
    throw new Error("MISSING_ACCOUNT");
  }

  const account = upsertAccountSnapshot({
    accountNumber,
    customerEmail: email,
    balance: Number(input.account.balance) || 0,
    equity: Number(input.account.equity) || 0,
    currency: input.account.currency,
    serverName: input.account.serverName,
    updatedAt: nowIso(),
  });

  const openPositions = input.openPositions || [];
  const closedDeals = input.closedDeals || [];
  const openTickets = new Set<string>();
  let openCount = 0;
  let closedCount = 0;
  const newlyClosed: TradeRecord[] = [];

  for (const row of openPositions) {
    const rec = toTradeRecord(email, accountNumber, { ...row, status: "open", closeTime: null }, "open");
    if (!rec) continue;
    openTickets.add(rec.ticket);
    upsertTradeRecord(rec);
    openCount += 1;
  }

  const existing = listTradesForCustomer(email).filter((t) => t.accountNumber === accountNumber);

  for (const row of closedDeals) {
    const rec = toTradeRecord(email, accountNumber, { ...row, status: "closed" }, "closed");
    if (!rec) continue;
    const prev = existing.find((t) => t.ticket === rec.ticket);
    const wasOpenOrMissing = !prev || prev.status === "open";
    upsertTradeRecord(rec);
    closedCount += 1;
    if (wasOpenOrMissing) newlyClosed.push(rec);
  }

  // Positions that disappeared from open list without a closed deal → leave as open
  // (partial sync). Full close events should arrive via closedDeals / trade-closed.

  await flushTradingStore();
  return { ok: true, account, openCount, closedCount, newlyClosed };
}

function startOfUtcDay(d = new Date()): Date {
  return new Date(Date.UTC(d.getUTCFullYear(), d.getUTCMonth(), d.getUTCDate()));
}

function isTodayIso(iso: string | null | undefined): boolean {
  if (!iso) return false;
  const t = Date.parse(iso);
  if (!Number.isFinite(t)) return false;
  return t >= startOfUtcDay().getTime();
}

export function summarizeToday(trades: TradeRecord[]): TradingTodaySummary {
  const todayOpened = trades.filter((t) => isTodayIso(t.openTime));
  const todayClosed = trades.filter((t) => t.status === "closed" && isTodayIso(t.closeTime));
  const stillOpen = trades.filter((t) => t.status === "open");
  const profitCount = todayClosed.filter((t) => t.profit > 0).length;
  const lossCount = todayClosed.filter((t) => t.profit < 0).length;
  const netProfit = todayClosed.reduce((sum, t) => sum + (Number(t.profit) || 0), 0);
  return {
    openedCount: todayOpened.length,
    profitCount,
    lossCount,
    stillOpenCount: stillOpen.length,
    netProfit,
  };
}

export async function getTradingDashboard(emailRaw: string): Promise<TradingDashboard> {
  await ensureTradingStoreLoaded();
  const email = emailRaw.trim().toLowerCase();
  const accounts = listAccountsForCustomer(email);
  const account = accounts[0] || null;
  const trades = listTradesForCustomer(email);
  const openTrades = trades.filter((t) => t.status === "open");
  const history = trades.filter((t) => t.status === "closed");
  return {
    account,
    today: summarizeToday(trades),
    openTrades,
    history,
    synced: !!account,
  };
}
