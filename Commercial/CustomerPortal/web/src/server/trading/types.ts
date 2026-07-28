export type TradeSide = "buy" | "sell";
export type TradeStatus = "open" | "closed";

/** MT5 account snapshot synced from EA / local agent. */
export type TradingAccountSnapshot = {
  accountNumber: string;
  customerEmail: string;
  balance: number;
  equity: number;
  currency?: string;
  serverName?: string;
  updatedAt: string;
};

/** Individual position / deal row for portal Today + History. */
export type TradeRecord = {
  ticket: string;
  accountNumber: string;
  customerEmail: string;
  symbol: string;
  type: TradeSide;
  volume: number;
  openTime: string;
  closeTime: string | null;
  profit: number;
  status: TradeStatus;
  comment?: string;
  updatedAt: string;
};

export type TradingStoreData = {
  version: 1;
  accounts: TradingAccountSnapshot[];
  trades: TradeRecord[];
};

export type TradingTodaySummary = {
  openedCount: number;
  profitCount: number;
  lossCount: number;
  stillOpenCount: number;
  netProfit: number;
};

export type TradingDashboard = {
  account: TradingAccountSnapshot | null;
  today: TradingTodaySummary;
  openTrades: TradeRecord[];
  history: TradeRecord[];
  synced: boolean;
};
