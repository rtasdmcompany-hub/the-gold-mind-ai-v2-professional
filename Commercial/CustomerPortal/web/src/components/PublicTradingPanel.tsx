"use client";

import { useEffect, useState } from "react";

interface TradingData {
  account: {
    accountNumber: string;
    balance: number;
    equity: number;
    currency?: string;
  };
  today: {
    openedCount: number;
    profitCount: number;
    lossCount: number;
    stillOpenCount: number;
    netProfit: number;
  };
  openTrades: Array<{
    ticket: string | number;
    symbol: string;
    type: string;
    volume: number;
    profit: number;
    openTime: string;
  }>;
}

export default function PublicTradingPanel() {
  const [data, setData] = useState<TradingData | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchData = async () => {
    try {
      const res = await fetch("/api/trading/public", { cache: "no-store" });
      const json = await res.json();
      if (json.ok) {
        setData(json.data);
        setError(null);
      } else {
        setError("No live trading data available yet.");
      }
    } catch {
      // Ignore error - already handled by setError
      setError("Failed to load trading data.");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchData();
    const interval = setInterval(fetchData, 10000);
    return () => clearInterval(interval);
  }, []);

  if (loading) {
    return (
      <section className="e-section" style={{ background: "#0a0a0a" }}>
        <div className="e-container" style={{ textAlign: "center", padding: "40px" }}>
          <p style={{ color: "#d4af37" }}>Loading Live Trading Panel...</p>
        </div>
      </section>
    );
  }

  if (error) {
    return (
      <section className="e-section" style={{ background: "#0a0a0a" }}>
        <div className="e-container" style={{ textAlign: "center", padding: "40px" }}>
          <p style={{ color: "#888" }}>{error}</p>
        </div>
      </section>
    );
  }

  if (!data) return null;

  const { account, today, openTrades } = data;
  const currency = account.currency || "USD";
  const isProfit = today.netProfit >= 0;

  return (
    <section className="e-section" style={{ background: "#0a0a0a", color: "#ffffff" }}>
      <div className="e-container">
        <div style={{ textAlign: "center", marginBottom: "30px" }}>
          <p className="e-eyebrow" style={{ color: "#d4af37" }}>Live Performance</p>
          <h2 className="e-section-title">Real-Time Trading Dashboard</h2>
          <p className="e-section-sub" style={{ color: "#aaa" }}>
            Direct feed from THE GOLD MIND AI Engine (Account: {account.accountNumber})
          </p>
        </div>

        <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(200px, 1fr))", gap: "16px", marginBottom: "30px" }}>
          <div className="e-glass-card" style={{ textAlign: "center", border: "1px solid #1a1a1a" }}>
            <p style={{ fontSize: "14px", color: "#888", marginBottom: "8px" }}>Balance</p>
            <p style={{ fontSize: "24px", fontWeight: "bold", color: "#d4af37" }}>
              {currency} {account.balance.toLocaleString()}
            </p>
          </div>
          <div className="e-glass-card" style={{ textAlign: "center", border: "1px solid #1a1a1a" }}>
            <p style={{ fontSize: "14px", color: "#888", marginBottom: "8px" }}>Equity</p>
            <p style={{ fontSize: "24px", fontWeight: "bold", color: "#ffffff" }}>
              {currency} {account.equity.toLocaleString()}
            </p>
          </div>
          <div className="e-glass-card" style={{ textAlign: "center", border: "1px solid #1a1a1a" }}>
            <p style={{ fontSize: "14px", color: "#888", marginBottom: "8px" }}>Today&apos;s P/L</p>
            <p style={{ fontSize: "24px", fontWeight: "bold", color: isProfit ? "#10b981" : "#ef4444" }}>
              {isProfit ? "+" : ""}{currency} {today.netProfit.toLocaleString()}
            </p>
          </div>
          <div className="e-glass-card" style={{ textAlign: "center", border: "1px solid #1a1a1a" }}>
            <p style={{ fontSize: "14px", color: "#888", marginBottom: "8px" }}>Open Trades</p>
            <p style={{ fontSize: "24px", fontWeight: "bold", color: "#ffffff" }}>
              {today.stillOpenCount}
            </p>
          </div>
        </div>

        {openTrades.length > 0 && (
          <div className="e-glass-card" style={{ border: "1px solid #1a1a1a", overflow: "hidden" }}>
            <h3 style={{ padding: "16px 20px", borderBottom: "1px solid #1a1a1a", fontSize: "16px", color: "#d4af37" }}>
              Active Positions
            </h3>
            <div style={{ overflowX: "auto" }}>
              <table style={{ width: "100%", borderCollapse: "collapse", fontSize: "14px" }}>
                <thead>
                  <tr style={{ backgroundColor: "#111", color: "#888" }}>
                    <th style={{ padding: "12px 20px", textAlign: "left" }}>Ticket</th>
                    <th style={{ padding: "12px 20px", textAlign: "left" }}>Symbol</th>
                    <th style={{ padding: "12px 20px", textAlign: "left" }}>Type</th>
                    <th style={{ padding: "12px 20px", textAlign: "left" }}>Volume</th>
                    <th style={{ padding: "12px 20px", textAlign: "right" }}>Profit</th>
                  </tr>
                </thead>
                <tbody>
                  {openTrades.map((trade) => {
                    const tradeProfit = trade.profit || 0;
                    const tradeIsProfit = tradeProfit >= 0;
                    return (
                      <tr key={trade.ticket} style={{ borderBottom: "1px solid #1a1a1a" }}>
                        <td style={{ padding: "12px 20px", fontFamily: "monospace", color: "#aaa" }}>{trade.ticket}</td>
                        <td style={{ padding: "12px 20px", fontWeight: "bold" }}>{trade.symbol}</td>
                        <td style={{ padding: "12px 20px" }}>
                          <span style={{ 
                            padding: "4px 8px", 
                            borderRadius: "4px", 
                            fontSize: "12px", 
                            fontWeight: "bold",
                            backgroundColor: trade.type?.toLowerCase() === "buy" ? "rgba(16, 185, 129, 0.2)" : "rgba(239, 68, 68, 0.2)",
                            color: trade.type?.toLowerCase() === "buy" ? "#10b981" : "#ef4444"
                          }}>
                            {trade.type?.toUpperCase()}
                          </span>
                        </td>
                        <td style={{ padding: "12px 20px" }}>{trade.volume}</td>
                        <td style={{ padding: "12px 20px", textAlign: "right", fontWeight: "bold", color: tradeIsProfit ? "#10b981" : "#ef4444" }}>
                          {tradeIsProfit ? "+" : ""}{currency} {tradeProfit.toLocaleString()}
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
          </div>
        )}
      </div>
    </section>
  );
}