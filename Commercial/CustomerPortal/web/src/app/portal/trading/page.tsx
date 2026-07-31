import { auth } from "@/auth";
import { StatusBadge } from "@/components/StatusBadge";
import { getTradingDashboard } from "@/server/trading/service";
import Link from "next/link";
import { redirect } from "next/navigation";
import { brand } from "@/lib/brand";

function fmtMoney(n: number | null | undefined, currency?: string): string {
  if (n == null || !Number.isFinite(n)) return "—";
  const prefix = currency ? `${currency} ` : "";
  return `${prefix}${n.toFixed(2)}`;
}

function fmtTime(iso: string | null | undefined): string {
  if (!iso) return "—";
  return iso.slice(0, 19).replace("T", " ");
}

export default async function TradingPage() {
  const session = await auth();
  if (!session?.user?.email) redirect("/login");
  const email = session.user.email.toLowerCase();
  const dash = await getTradingDashboard(email);
  const currency = dash.account?.currency;

  return (
    <>
      <header style={{ marginBottom: 20 }}>
        <h1 className="page-title">Trading Account</h1>
        <p className="page-sub">
          Live MT5 balance, equity, and trade history synced from {brand.productName}. Email alerts are
          optional — this page stays available even when trade emails are off.
        </p>
      </header>

      {!dash.synced && (
        <div className="card" style={{ marginBottom: 16, borderColor: "var(--gm-warning)" }}>
          <h3>Waiting for MT5 sync</h3>
          <p className="meta" style={{ marginTop: 8, lineHeight: 1.5 }}>
            No account snapshot yet. Enable Portal Trading Sync on the EA (or run the local reporter) so balance,
            equity, and trades appear here. See{" "}
            <Link href="/docs">Docs</Link> / installer notes for allowing the portal URL in MT5 WebRequest.
          </p>
        </div>
      )}

      <div className="grid grid-3" style={{ marginBottom: 16 }}>
        <div className="card">
          <h3>Balance</h3>
          <div className="value">{fmtMoney(dash.account?.balance, currency)}</div>
          <div className="meta">
            MT5 {dash.account?.accountNumber || "—"}
            {dash.account?.serverName ? ` · ${dash.account.serverName}` : ""}
          </div>
        </div>
        <div className="card">
          <h3>Equity</h3>
          <div className="value">{fmtMoney(dash.account?.equity, currency)}</div>
          <div className="meta">Updated {fmtTime(dash.account?.updatedAt)}</div>
        </div>
        <div className="card">
          <h3>Today opened</h3>
          <div className="value">{dash.today.openedCount}</div>
          <div className="meta">Trades opened today (UTC)</div>
        </div>
        <div className="card">
          <h3>Today W / L</h3>
          <div className="value">
            {dash.today.profitCount} / {dash.today.lossCount}
          </div>
          <div className="meta">Closed wins / losses today</div>
        </div>
        <div className="card">
          <h3>Today P/L</h3>
          <div
            className="value"
            style={{
              color:
                dash.today.netProfit > 0
                  ? "var(--gm-success)"
                  : dash.today.netProfit < 0
                    ? "var(--gm-danger)"
                    : undefined,
            }}
          >
            {fmtMoney(dash.today.netProfit, currency)}
          </div>
          <div className="meta">Net closed today</div>
        </div>
        <div className="card">
          <h3>Still open</h3>
          <div className="value">{dash.today.stillOpenCount}</div>
          <div className="meta">Open positions right now</div>
        </div>
      </div>

      <section style={{ marginBottom: 24 }}>
        <h2 className="page-title" style={{ fontSize: 18, marginBottom: 12 }}>
          Today — open &amp; today&apos;s activity
        </h2>
        <div className="table-wrap">
          <table className="data">
            <thead>
              <tr>
                <th>Ticket</th>
                <th>Symbol</th>
                <th>Type</th>
                <th>Volume</th>
                <th>Opened</th>
                <th>Closed</th>
                <th>Profit</th>
                <th>Status</th>
              </tr>
            </thead>
            <tbody>
              {dash.openTrades.length === 0 &&
                dash.history.filter((t) => (t.closeTime || t.openTime || "").slice(0, 10) === new Date().toISOString().slice(0, 10))
                  .length === 0 && (
                  <tr>
                    <td colSpan={8}>No trades today — waiting for MT5 sync or market activity.</td>
                  </tr>
                )}
              {dash.openTrades.map((t) => (
                <tr key={`o-${t.ticket}`}>
                  <td className="mono">{t.ticket}</td>
                  <td>{t.symbol}</td>
                  <td>{t.type.toUpperCase()}</td>
                  <td>{t.volume}</td>
                  <td>{fmtTime(t.openTime)}</td>
                  <td>—</td>
                  <td>{fmtMoney(t.profit, currency)}</td>
                  <td>
                    <StatusBadge status="open" />
                  </td>
                </tr>
              ))}
              {dash.history
                .filter((t) => {
                  const day = (t.closeTime || t.openTime || "").slice(0, 10);
                  return day === new Date().toISOString().slice(0, 10);
                })
                .map((t) => (
                  <tr key={`c-${t.ticket}`}>
                    <td className="mono">{t.ticket}</td>
                    <td>{t.symbol}</td>
                    <td>{t.type.toUpperCase()}</td>
                    <td>{t.volume}</td>
                    <td>{fmtTime(t.openTime)}</td>
                    <td>{fmtTime(t.closeTime)}</td>
                    <td
                      style={{
                        color: t.profit > 0 ? "var(--gm-success)" : t.profit < 0 ? "var(--gm-danger)" : undefined,
                      }}
                    >
                      {fmtMoney(t.profit, currency)}
                    </td>
                    <td>
                      <StatusBadge status="closed" />
                    </td>
                  </tr>
                ))}
            </tbody>
          </table>
        </div>
      </section>

      <section>
        <h2 className="page-title" style={{ fontSize: 18, marginBottom: 12 }}>
          History — all trades
        </h2>
        <p className="page-sub" style={{ marginBottom: 12 }}>
          Closed: {dash.history.length} · Profit: {dash.history.filter((t) => t.profit > 0).length} · Loss:{" "}
          {dash.history.filter((t) => t.profit < 0).length}
        </p>
        <div className="table-wrap">
          <table className="data">
            <thead>
              <tr>
                <th>Ticket</th>
                <th>Symbol</th>
                <th>Type</th>
                <th>Volume</th>
                <th>Opened</th>
                <th>Closed</th>
                <th>Profit</th>
                <th>Account</th>
              </tr>
            </thead>
            <tbody>
              {dash.history.length === 0 && (
                <tr>
                  <td colSpan={8}>No closed trades synced yet.</td>
                </tr>
              )}
              {dash.history.map((t) => (
                <tr key={t.ticket}>
                  <td className="mono">{t.ticket}</td>
                  <td>{t.symbol}</td>
                  <td>{t.type.toUpperCase()}</td>
                  <td>{t.volume}</td>
                  <td>{fmtTime(t.openTime)}</td>
                  <td>{fmtTime(t.closeTime)}</td>
                  <td
                    style={{
                      color: t.profit > 0 ? "var(--gm-success)" : t.profit < 0 ? "var(--gm-danger)" : undefined,
                    }}
                  >
                    {fmtMoney(t.profit, currency)}
                  </td>
                  <td className="mono">{t.accountNumber}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </section>
    </>
  );
}
