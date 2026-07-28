import fs from "fs";
import path from "path";
import { commercialDataRoot } from "@/server/cloud/data-root";
import {
  durableGet,
  durableSet,
  isDurableStoreConfigured,
} from "@/server/cloud/cache";
import { decryptJson, encryptJson, nowIso } from "@/server/licensing/crypto";
import type { TradingAccountSnapshot, TradingStoreData, TradeRecord } from "./types";

const STORE_FILE = "trading.enc";
const DURABLE_KEY = "tgm:trading:store:v1";
const MAX_TRADES = 5000;

const EMPTY: TradingStoreData = { version: 1, accounts: [], trades: [] };

let memoryCache: TradingStoreData | null = null;
let writeChain: Promise<void> = Promise.resolve();
let loadPromise: Promise<void> | null = null;

function storePath(): string {
  return path.join(commercialDataRoot("trading"), STORE_FILE);
}

function loadRawFromDisk(): TradingStoreData {
  const p = storePath();
  if (!fs.existsSync(p)) return structuredClone(EMPTY);
  try {
    return decryptJson<TradingStoreData>(fs.readFileSync(p, "utf8"));
  } catch {
    return structuredClone(EMPTY);
  }
}

export async function ensureTradingStoreLoaded(): Promise<void> {
  if (memoryCache) return;
  if (!loadPromise) {
    loadPromise = (async () => {
      if (isDurableStoreConfigured()) {
        try {
          const remote = await durableGet(DURABLE_KEY);
          if (remote) {
            memoryCache = decryptJson<TradingStoreData>(remote);
            return;
          }
        } catch {
          /* fall through */
        }
      }
      memoryCache = loadRawFromDisk();
      if (isDurableStoreConfigured() && (memoryCache.accounts.length > 0 || memoryCache.trades.length > 0)) {
        try {
          await durableSet(DURABLE_KEY, encryptJson(memoryCache));
        } catch {
          /* non-fatal */
        }
      }
    })().finally(() => {
      if (!memoryCache) loadPromise = null;
    });
  }
  await loadPromise;
  if (!memoryCache) memoryCache = structuredClone(EMPTY);
}

export function readTradingStore(): TradingStoreData {
  if (!memoryCache) memoryCache = loadRawFromDisk();
  return memoryCache;
}

function writeTradingStore(data: TradingStoreData): void {
  memoryCache = data;
  const blob = encryptJson(data);
  writeChain = writeChain.then(async () => {
    try {
      fs.writeFileSync(storePath(), blob, "utf8");
    } catch {
      /* serverless may only have durable store */
    }
    if (isDurableStoreConfigured()) {
      try {
        await durableSet(DURABLE_KEY, blob);
      } catch {
        /* non-fatal on local */
      }
    }
  });
}

export async function flushTradingStore(): Promise<void> {
  await writeChain;
}

export function mutateTradingStore(mutator: (data: TradingStoreData) => void): TradingStoreData {
  const data = structuredClone(readTradingStore());
  mutator(data);
  if (data.trades.length > MAX_TRADES) {
    data.trades = data.trades
      .sort((a, b) => (b.updatedAt || "").localeCompare(a.updatedAt || ""))
      .slice(0, MAX_TRADES);
  }
  writeTradingStore(data);
  return data;
}

export function upsertAccountSnapshot(snapshot: TradingAccountSnapshot): TradingAccountSnapshot {
  const email = snapshot.customerEmail.trim().toLowerCase();
  const accountNumber = String(snapshot.accountNumber).trim();
  const next: TradingAccountSnapshot = {
    ...snapshot,
    customerEmail: email,
    accountNumber,
    updatedAt: snapshot.updatedAt || nowIso(),
  };
  mutateTradingStore((data) => {
    const idx = data.accounts.findIndex(
      (a) => a.customerEmail === email && a.accountNumber === accountNumber
    );
    if (idx >= 0) data.accounts[idx] = next;
    else data.accounts.unshift(next);
  });
  return next;
}

export function upsertTradeRecord(trade: TradeRecord): TradeRecord {
  const email = trade.customerEmail.trim().toLowerCase();
  const ticket = String(trade.ticket).trim();
  const next: TradeRecord = {
    ...trade,
    customerEmail: email,
    ticket,
    updatedAt: trade.updatedAt || nowIso(),
  };
  mutateTradingStore((data) => {
    const idx = data.trades.findIndex((t) => t.customerEmail === email && t.ticket === ticket);
    if (idx >= 0) {
      const prev = data.trades[idx];
      data.trades[idx] = {
        ...prev,
        ...next,
        openTime: next.openTime || prev.openTime,
        closeTime: next.closeTime ?? prev.closeTime,
      };
    } else {
      data.trades.unshift(next);
    }
  });
  return next;
}

export function listAccountsForCustomer(emailRaw: string): TradingAccountSnapshot[] {
  const email = emailRaw.trim().toLowerCase();
  return readTradingStore()
    .accounts.filter((a) => a.customerEmail === email)
    .sort((a, b) => b.updatedAt.localeCompare(a.updatedAt));
}

export function listTradesForCustomer(emailRaw: string): TradeRecord[] {
  const email = emailRaw.trim().toLowerCase();
  return readTradingStore()
    .trades.filter((t) => t.customerEmail === email)
    .sort((a, b) => {
      const at = a.closeTime || a.openTime || a.updatedAt;
      const bt = b.closeTime || b.openTime || b.updatedAt;
      return bt.localeCompare(at);
    });
}
