import { auth } from "@/auth";
import { StatusBadge } from "@/components/StatusBadge";
import { AiAssistantWidget } from "@/components/AiAssistantWidget";
import { ensureSeedData } from "@/server/licensing/seed";
import { listLicensesForCustomer } from "@/server/licensing/license-service";
import { listDevicesForCustomer } from "@/server/licensing/device-service";
import { listSubscriptionsForCustomer } from "@/server/licensing/subscription-service";
import { graceDays } from "@/server/licensing/crypto";
import { getTradingDashboard } from "@/server/trading/service";
import Link from "next/link";

export default async function DashboardPage() {
  await ensureSeedData();
  const session = await auth();
  const email = session?.user?.email?.toLowerCase() || "";
  const name = session?.user?.name || "Customer";
  const licenses = email ? listLicensesForCustomer(email) : [];
  const devices = email ? listDevicesForCustomer(email) : [];
  const subs = email ? listSubscriptionsForCustomer(email) : [];
  const active = licenses.find((l) => l.status === "active" || l.status === "grace");
  const activeDevices = devices.filter((d) => d.status === "active").length;
  const sub = subs[0];
  const trading = email ? await getTradingDashboard(email) : null;
  const currency = trading?.account?.currency;

  function fmtMoney(n: number | null | undefined): string {
    if (n == null || !Number.isFinite(n)) return "—";
    return `${currency ? currency + " " : ""}${n.toFixed(2)}`;
  }

  return (
    <>
      <header style={{ marginBottom: 20 }}>
        <h1 className="page-title">Dashboard</h1>
        <p className="page-sub">
          Live license status from the commercial Licensing Engine · grace {graceDays()} day(s) · Core Trading Engine
          isolated. Installer activation is required — Dashboard shows Active only after Setup.exe (or portal)
          confirms your key for this account.
        </p>
      </header>

      <div className="grid grid-3" style={{ marginBottom: 16 }}>
        <div className="card">
          <h3>Customer</h3>
          <div className="value" style={{ fontSize: 18 }}>
            {name}
          </div>
          <div className="meta">{email}</div>
        </div>
        <div className="card">
          <h3>Subscription</h3>
          <div className="value" style={{ fontSize: 18 }}>
            <StatusBadge status={sub?.status || "None"} />
          </div>
          <div className="meta">
            {sub ? `${sub.plan} · exp ${sub.expirationDate?.slice(0, 10) || "—"}` : "No subscription"}
          </div>
        </div>
        <div className="card">
          <h3>License</h3>
          <div className="value" style={{ fontSize: 18 }}>
            <StatusBadge status={active?.status || "None"} />
          </div>
          <div className="meta">{active?.keyMasked || "—"}</div>
        </div>
        <div className="card">
          <h3>Product Edition</h3>
          <div className="value" style={{ fontSize: 16 }}>
            THE GOLD MIND PROFESSIONAL
          </div>
        </div>
        <div className="card">
          <h3>Devices</h3>
          <div className="value">
            {activeDevices} / {active?.seatsMax ?? "—"}
          </div>
          <div className="meta">
            <Link href="/portal/devices">Manage devices</Link>
          </div>
        </div>
        <div className="card">
          <h3>Downloads</h3>
          <div className="value" style={{ fontSize: 16 }}>
            Latest stable ZIP
          </div>
          <div className="meta">
            <Link href="/portal/downloads">Open Download Center</Link>
          </div>
        </div>
        <div className="card">
          <h3>Last validated</h3>
          <div className="value" style={{ fontSize: 14 }}>
            {active?.lastValidatedAt?.replace("T", " ").slice(0, 19) || "—"}
          </div>
        </div>
      </div>

      <h2 className="page-title" style={{ fontSize: 18, marginBottom: 12 }}>
        Trading account
      </h2>
      <div className="grid grid-3" style={{ marginBottom: 16 }}>
        <div className="card">
          <h3>Balance</h3>
          <div className="value">{fmtMoney(trading?.account?.balance)}</div>
          <div className="meta">
            {trading?.synced ? `MT5 ${trading.account?.accountNumber}` : "Waiting for MT5 sync"}
          </div>
        </div>
        <div className="card">
          <h3>Equity</h3>
          <div className="value">{fmtMoney(trading?.account?.equity)}</div>
          <div className="meta">
            <Link href="/portal/trading">Open trading details</Link>
          </div>
        </div>
        <div className="card">
          <h3>Today opened</h3>
          <div className="value">{trading?.today.openedCount ?? 0}</div>
          <div className="meta">Trades opened today</div>
        </div>
        <div className="card">
          <h3>Today W / L</h3>
          <div className="value">
            {trading?.today.profitCount ?? 0} / {trading?.today.lossCount ?? 0}
          </div>
          <div className="meta">Closed wins / losses</div>
        </div>
        <div className="card">
          <h3>Today P/L</h3>
          <div className="value">{fmtMoney(trading?.today.netProfit ?? 0)}</div>
          <div className="meta">Net closed today</div>
        </div>
        <div className="card">
          <h3>Still open</h3>
          <div className="value">{trading?.today.stillOpenCount ?? 0}</div>
          <div className="meta">Open positions</div>
        </div>
      </div>

      <AiAssistantWidget
        surface="customer_portal"
        role="customer"
        customerEmail={email || undefined}
        title="AI Support"
      />
    </>
  );
}
