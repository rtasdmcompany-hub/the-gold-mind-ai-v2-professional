import { nowIso } from "@/server/licensing/crypto";
import { createClient } from "@supabase/supabase-js";
import type {
  TradingAccountSnapshot,
  TradingDashboard,
  TradingTodaySummary,
  TradeRecord,
  TradeSide,
  TradeStatus,
} from "./types";

// ✅ Supabase Client
const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL || process.env.SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY || process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;

const supabase = supabaseUrl && supabaseKey 
  ? createClient(supabaseUrl, supabaseKey) 
  : null;

// In-memory cache (fast access)
let accountsCache: TradingAccountSnapshot[] = [];
let tradesCache: TradeRecord[] = [];
let lastSyncTime: string | null = null;

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

async function syncFromSupabase(email: string): Promise<void> {
  if (!supabase) {
    console.warn("⚠️ Supabase not configured");
    return;
  }

  try {
    // Fetch accounts
    const { data: accountsData, error: accountsError } = await supabase
      .from("user_mt5_accounts")
      .select("*")
      .eq("customerEmail", email)
      .order("updatedAt", { ascending: false });

    if (accountsError) {
      console.error("Error fetching accounts:", accountsError);
    } else if (accountsData) {
      accountsCache = accountsData.map((acc) => ({
        accountNumber: acc.accountNumber,
        customerEmail: acc.customerEmail,
        balance: acc.balance,
        equity: acc.equity,
        currency: acc.currency,
        serverName: acc.serverName,
        updatedAt: acc.updatedAt,
      }));
    }

    // Fetch trades
    const { data: tradesData, error: tradesError } = await supabase
      .from("master_trades")
      .select("*")
      .eq("customerEmail", email)
      .order("openTime", { ascending: false });

    if (tradesError) {
      console.error("Error fetching trades:", tradesError);
    } else if (tradesData) {
      tradesCache = tradesData.map((t) => ({
        ticket: t.ticket,
        accountNumber: t.accountNumber,
        customerEmail: t.customerEmail,
        symbol: t.symbol,
        type: t.type,
        volume: t.volume,
        openTime: t.openTime,
        closeTime: t.closeTime,
        profit: t.profit,
        status: t.status,
        comment: t.comment,
        updatedAt: t.updatedAt,
      }));
    }

    lastSyncTime = nowIso();
  } catch (error) {
    console.error("Sync error:", error);
  }
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

export async function applyTradingSync(input: TradingSyncInput): Promise<{
  ok: true;
  account: TradingAccountSnapshot;
  openCount: number;
  closedCount: number;
  newlyClosed: TradeRecord[];
}> {
  if (!supabase) {
    throw new Error("SUPABASE_NOT_CONFIGURED");
  }

  const email = input.customerEmail.trim().toLowerCase();
  const accountNumber = String(input.account.accountNumber).trim();
  if (!email || !accountNumber) {
    throw new Error("MISSING_ACCOUNT");
  }

  // Save account to Supabase
  const accountSnapshot: TradingAccountSnapshot = {
    accountNumber,
    customerEmail: email,
    balance: Number(input.account.balance) || 0,
    equity: Number(input.account.equity) || 0,
    currency: input.account.currency,
    serverName: input.account.serverName,
    updatedAt: nowIso(),
  };

  const { error: accountError } = await supabase
    .from("user_mt5_accounts")
    .upsert(accountSnapshot, { onConflict: "accountNumber,customerEmail" });

  if (accountError) {
    console.error("Account save error:", accountError);
    throw new Error("FAILED_TO_SAVE_ACCOUNT");
  }

  const openPositions = input.openPositions || [];
  const closedDeals = input.closedDeals || [];
  const openTickets = new Set<string>();
  let openCount = 0;
  let closedCount = 0;
  const newlyClosed: TradeRecord[] = [];

  // Save open positions
  for (const row of openPositions) {
    const rec = toTradeRecord(email, accountNumber, { ...row, status: "open", closeTime: null }, "open");
    if (!rec) continue;
    openTickets.add(rec.ticket);

    const { error } = await supabase
      .from("master_trades")
      .upsert(rec, { onConflict: "ticket,accountNumber" });

    if (error) {
      console.error("Open position save error:", error);
    } else {
      openCount += 1;
    }
  }

  // Save closed deals
  for (const row of closedDeals) {
    const rec = toTradeRecord(email, accountNumber, { ...row, status: "closed" }, "closed");
    if (!rec) continue;

    // Check if it was previously open
    const prevTrade = tradesCache.find((t) => t.ticket === rec.ticket && t.accountNumber === accountNumber);
    const wasOpenOrMissing = !prevTrade || prevTrade.status === "open";

    const { error } = await supabase
      .from("master_trades")
      .upsert(rec, { onConflict: "ticket,accountNumber" });

    if (error) {
      console.error("Closed deal save error:", error);
    } else {
      closedCount += 1;
      if (wasOpenOrMissing) newlyClosed.push(rec);
    }
  }

  // Update cache
  await syncFromSupabase(email);

  return { ok: true, account: accountSnapshot, openCount, closedCount, newlyClosed };
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
  const email = emailRaw.trim().toLowerCase();
  
  // Sync from Supabase
  await syncFromSupabase(email);

  const account = accountsCache[0] || null;
  const trades = tradesCache.filter((t) => t.customerEmail === email);
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

export function getPublicTradingDashboard(): TradingDashboard | null {
  if (accountsCache.length === 0) return null;
  
  const latestAccount = accountsCache.sort((a, b) => b.updatedAt.localeCompare(a.updatedAt))[0];
  const trades = tradesCache.filter((t) => t.customerEmail === latestAccount.customerEmail);
  
  return {
    account: latestAccount,
    today: summarizeToday(trades),
    openTrades: trades.filter((t) => t.status === "open"),
    history: trades.filter((t) => t.status === "closed"),
    synced: true,
  };
}