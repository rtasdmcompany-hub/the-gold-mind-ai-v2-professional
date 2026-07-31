import { auth } from "@/auth";
import { StatusBadge } from "@/components/StatusBadge";
import { AiAssistantWidget } from "@/components/AiAssistantWidget";
import { AiCommandCenterPreview } from "@/components/AiCommandCenterPreview";
import { ensureSeedData } from "@/server/licensing/seed";
import { listLicensesForCustomer } from "@/server/licensing/license-service";
import { listDevicesForCustomer } from "@/server/licensing/device-service";
import { listSubscriptionsForCustomer } from "@/server/licensing/subscription-service";
import { graceDays } from "@/server/licensing/crypto";
import { ensureBillingStoreLoaded } from "@/server/billing/store";
import { getBillingSummary } from "@/server/billing/billing-service";
import { ensureSupportStoreLoaded } from "@/server/admin/support-store";
import { listSupportTickets } from "@/server/admin/support-store";
import Link from "next/link";

export default async function DashboardPage() {
  await ensureSeedData();
  await ensureBillingStoreLoaded();
  await ensureSupportStoreLoaded();
  const session = await auth();
  const email = session?.user?.email?.toLowerCase() || "";
  const name = session?.user?.name || "Customer";
  const licenses = email ? listLicensesForCustomer(email) : [];
  const devices = email ? listDevicesForCustomer(email) : [];
  const subs = email ? listSubscriptionsForCustomer(email) : [];
  const billing = email ? getBillingSummary(email) : { invoices: [], payments: [], subscriptions: [], emails: [] };
  const tickets = email ? listSupportTickets({ customerEmail: email }) : [];
  const active = licenses.find((l) => l.status === "active" || l.status === "grace");
  const activeDevices = devices.filter((d) => d.status === "active").length;
  const sub = subs[0] || billing.subscriptions[0];
  const openTickets = tickets.filter((t) => t.status === "open" || t.status === "pending").length;

  return (
    <>
      <header style={{ marginBottom: 20 }}>
        <h1 className="page-title">Dashboard</h1>
        <p className="page-sub">
          Live commercial status · grace {graceDays()} day(s) · Core Trading Engine isolated. Installer activation is
          required — Dashboard shows Active only after Setup.exe (or portal) confirms your key.
        </p>
      </header>

      <div className="grid grid-3" style={{ marginBottom: 16 }}>
        <div className="card">
          <h3>Customer</h3>
          <div className="value" style={{ fontSize: 18 }}>
            {name}
          </div>
          <div className="meta">{email || "Not signed in"}</div>
        </div>
        <div className="card">
          <h3>Subscription</h3>
          <div className="value" style={{ fontSize: 18 }}>
            <StatusBadge status={(sub as { status?: string })?.status || "None"} />
          </div>
          <div className="meta">
            {subs[0]
              ? `${subs[0].plan} · exp ${subs[0].expirationDate?.slice(0, 10) || "—"}`
              : billing.subscriptions[0]
                ? `${billing.subscriptions[0].plan} (billing)`
                : "No subscription — "}
            {!subs[0] && !billing.subscriptions[0] && <Link href="/portal/billing">Billing</Link>}
          </div>
        </div>
        <div className="card">
          <h3>License</h3>
          <div className="value" style={{ fontSize: 18 }}>
            <StatusBadge status={active?.status || "None"} />
          </div>
          <div className="meta">
            {active?.keyMasked || (
              <>
                — <Link href="/portal/licenses">My Licenses</Link>
              </>
            )}
          </div>
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
          <h3>Last validated</h3>
          <div className="value" style={{ fontSize: 14 }}>
            {active?.lastValidatedAt?.replace("T", " ").slice(0, 19) || "—"}
          </div>
        </div>
        <div className="card">
          <h3>Invoices / Orders</h3>
          <div className="value" style={{ fontSize: 18 }}>
            {billing.invoices.length} / {billing.payments.filter((p) => p.status === "succeeded").length}
          </div>
          <div className="meta">
            <Link href="/portal/invoices">Invoices</Link> · <Link href="/portal/orders">Orders</Link>
          </div>
        </div>
        <div className="card">
          <h3>Open support tickets</h3>
          <div className="value">{openTickets}</div>
          <div className="meta">
            <Link href="/portal/support">Support</Link>
          </div>
        </div>
        <div className="card">
          <h3>Quick links</h3>
          <div className="meta">
            <Link href="/portal/downloads">Downloads</Link> · <Link href="/portal/announcements">Announcements</Link> ·{" "}
            <Link href="/portal/account">Account</Link>
          </div>
        </div>
      </div>

      <AiCommandCenterPreview />

      <AiAssistantWidget
        surface="customer_portal"
        role="customer"
        customerEmail={email || undefined}
        title="AI Support"
      />
    </>
  );
}
