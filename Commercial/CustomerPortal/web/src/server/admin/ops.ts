/**
 * Enterprise Admin aggregations — commercial data only.
 */
import { listAllLicensesAdmin } from "@/server/licensing/license-service";
import { listAllDevicesAdmin } from "@/server/licensing/device-service";
import { listAllSubscriptionsAdmin } from "@/server/licensing/subscription-service";
import { getAdminBillingDashboard, getBillingSummary } from "@/server/billing/billing-service";
import { getAdminReleaseDashboard } from "@/server/releases/release-service";
import { runHealthChecks } from "@/server/cloud/monitoring";
import { listAudit, auditCount } from "@/server/cloud/audit";
import { listSupportTickets } from "./support-store";
import { readBillingStore } from "@/server/billing/store";

export function getEnterpriseDashboard() {
  const licenses = listAllLicensesAdmin();
  const devices = listAllDevicesAdmin();
  const subs = listAllSubscriptionsAdmin();
  const billing = getAdminBillingDashboard();
  const releases = getAdminReleaseDashboard();
  const tickets = listSupportTickets();
  const emails = new Set(licenses.map((l) => l.customerEmail.toLowerCase()));
  for (const p of billing.recentTransactions) emails.add(p.customerEmail.toLowerCase());

  const activeLicenses = licenses.filter((l) => l.status === "active" || l.status === "grace");
  const activeSubs = billing.subscriptions.filter((s) => s.status === "active" || s.status === "trialing");
  const today = new Date().toISOString().slice(0, 10);
  const dailyActivations = licenses.filter((l) => l.activatedAt?.slice(0, 10) === today).length;
  // registrations ≈ first license created today
  const newRegistrations = licenses.filter((l) => l.createdAt?.slice(0, 10) === today).length;
  const openTickets = tickets.filter((t) => t.status === "open" || t.status === "pending").length;

  return {
    activeCustomers: emails.size,
    activeLicenses: activeLicenses.length,
    subscriptions: activeSubs.length,
    revenueOverview: billing.revenueFormatted,
    revenueCents: billing.revenueCents,
    dailyActivations,
    newRegistrations,
    supportTicketsOpen: openTickets,
    supportTicketsTotal: tickets.length,
    latestRelease: releases.latestRelease
      ? {
          version: releases.latestRelease.version,
          channel: releases.latestRelease.channel,
          build: releases.latestRelease.buildNumber,
        }
      : null,
    deviceCount: devices.length,
    entitlementSubs: subs.length,
    failedPayments: billing.failedPayments.length,
    rollbackEvents: releases.rollbackEvents,
    auditEntries: auditCount(),
  };
}

export async function getEnterpriseDashboardWithHealth() {
  const base = getEnterpriseDashboard();
  const health = await runHealthChecks(false);
  return {
    ...base,
    systemHealth: health.status,
    platformStatus: health.status === "healthy" ? "operational" : health.status,
    healthServices: health.services,
  };
}

export function searchCustomers(q: string) {
  const query = q.toLowerCase().trim();
  const licenses = listAllLicensesAdmin();
  const devices = listAllDevicesAdmin();
  const billing = readBillingStore();
  const map = new Map<
    string,
    {
      email: string;
      name: string;
      licenseCount: number;
      deviceCount: number;
      accountStatus: "active" | "suspended" | "unknown";
      lastOrderAt?: string;
    }
  >();

  for (const l of licenses) {
    const e = l.customerEmail.toLowerCase();
    const row = map.get(e) || {
      email: e,
      name: l.customerName,
      licenseCount: 0,
      deviceCount: 0,
      accountStatus: (l.status === "revoked" ? "suspended" : "active") as "active" | "suspended",
    };
    row.licenseCount += 1;
    if (l.status === "revoked") row.accountStatus = "suspended";
    if (!row.name) row.name = l.customerName;
    map.set(e, row);
  }

  for (const d of devices) {
    const e = d.customerEmail.toLowerCase();
    const row = map.get(e) || {
      email: e,
      name: e,
      licenseCount: 0,
      deviceCount: 0,
      accountStatus: "unknown" as const,
    };
    row.deviceCount += 1;
    map.set(e, row);
  }

  for (const p of billing.payments) {
    const e = p.customerEmail.toLowerCase();
    const row = map.get(e);
    if (!row) continue;
    if (!row.lastOrderAt || p.createdAt > row.lastOrderAt) row.lastOrderAt = p.createdAt;
  }

  let rows = [...map.values()];
  if (query) {
    rows = rows.filter((r) => r.email.includes(query) || r.name.toLowerCase().includes(query));
  }
  return rows.sort((a, b) => a.email.localeCompare(b.email));
}

export function getCustomerProfile(email: string) {
  const e = email.toLowerCase();
  const licenses = listAllLicensesAdmin().filter((l) => l.customerEmail === e);
  const devices = listAllDevicesAdmin().filter((d) => d.customerEmail === e);
  const entitlements = listAllSubscriptionsAdmin().filter((s) => s.customerEmail === e);
  const billing = getBillingSummary(e);
  const tickets = listSupportTickets().filter((t) => t.customerEmail === e);
  const audits = listAudit(30, { user: e });
  const suspended = licenses.length > 0 && licenses.every((l) => l.status === "revoked");
  return {
    email: e,
    name: licenses[0]?.customerName || e,
    accountStatus: suspended ? ("suspended" as const) : ("active" as const),
    licenses,
    devices,
    subscriptions: billing.subscriptions,
    entitlements,
    orders: billing.payments,
    invoices: billing.invoices,
    supportHistory: tickets,
    audit: audits,
  };
}

export function getLicenseAdminView(q?: string) {
  let licenses = listAllLicensesAdmin();
  if (q) {
    const qq = q.toLowerCase();
    licenses = licenses.filter(
      (l) =>
        l.customerEmail.includes(qq) ||
        l.id.includes(qq) ||
        l.customerName.toLowerCase().includes(qq) ||
        l.type.includes(qq)
    );
  }
  const now = Date.now();
  const soon = now + 14 * 24 * 3600 * 1000;
  const expiring = licenses.filter(
    (l) => l.expiresAt && Date.parse(l.expiresAt) <= soon && Date.parse(l.expiresAt) >= now
  );
  const trials = licenses.filter((l) => l.type === "trial");
  const lifetime = licenses.filter((l) => l.type === "lifetime");
  const monthly = licenses.filter((l) => l.type === "monthly");
  const yearly = licenses.filter((l) => l.type === "yearly");
  const renewalQueue = expiring.map((l) => ({
    licenseId: l.id,
    email: l.customerEmail,
    type: l.type,
    expiresAt: l.expiresAt,
  }));

  return {
    licenses,
    activationHistory: licenses
      .filter((l) => l.activatedAt)
      .sort((a, b) => (b.activatedAt || "").localeCompare(a.activatedAt || ""))
      .slice(0, 40),
    expirationMonitoring: expiring,
    renewalQueue,
    counts: {
      trial: trials.length,
      lifetime: lifetime.length,
      monthly: monthly.length,
      yearly: yearly.length,
      total: licenses.length,
    },
  };
}

export function getBusinessIntelligence() {
  const billing = getAdminBillingDashboard();
  const licenses = listAllLicensesAdmin();
  const releases = getAdminReleaseDashboard();
  const tickets = listSupportTickets();
  const payments = billing.recentTransactions;
  const succeeded = payments.filter((p) => p.status === "succeeded");
  const refunds = payments.filter((p) => p.status === "refunded");

  // Simple monthly buckets from payment dates
  const byMonth = new Map<string, number>();
  for (const p of succeeded) {
    const m = p.createdAt.slice(0, 7);
    byMonth.set(m, (byMonth.get(m) || 0) + p.amountCents);
  }
  const revenueTrends = [...byMonth.entries()]
    .sort((a, b) => a[0].localeCompare(b[0]))
    .map(([month, cents]) => ({ month, cents, formatted: `USD ${(cents / 100).toFixed(2)}` }));

  const activeSubs = billing.subscriptionCount;
  const totalLicenses = licenses.length;
  const activated = licenses.filter((l) => l.activatedAt).length;
  const activationRate = totalLicenses === 0 ? 0 : Math.round((activated / totalLicenses) * 1000) / 10;

  const renewals = billing.renewals.length;
  const renewalRate =
    activeSubs === 0 ? 0 : Math.round((renewals / Math.max(activeSubs, 1)) * 1000) / 10;

  const resolved = tickets.filter((t) => t.status === "resolved" || t.status === "closed").length;
  const supportPerf =
    tickets.length === 0 ? 100 : Math.round((resolved / tickets.length) * 1000) / 10;

  // Retention proxy: active licenses / customers with any license
  const customers = new Set(licenses.map((l) => l.customerEmail));
  const activeCustomers = new Set(
    licenses.filter((l) => l.status === "active" || l.status === "grace").map((l) => l.customerEmail)
  );
  const retention =
    customers.size === 0 ? 0 : Math.round((activeCustomers.size / customers.size) * 1000) / 10;

  return {
    revenueTrends,
    subscriptionGrowth: {
      active: activeSubs,
      billingSubs: billing.subscriptions.length,
    },
    customerRetention: retention,
    activationRate,
    renewalRate,
    refundStatistics: {
      count: refunds.length,
      cents: refunds.reduce((a, p) => a + p.amountCents, 0),
    },
    supportPerformance: {
      resolvedRate: supportPerf,
      open: tickets.filter((t) => t.status === "open" || t.status === "pending").length,
      total: tickets.length,
    },
    productAdoption: {
      downloads: releases.totalDownloads,
      updateSuccessRate: releases.updateSuccessRate,
      licensesByType: {
        trial: licenses.filter((l) => l.type === "trial").length,
        monthly: licenses.filter((l) => l.type === "monthly").length,
        yearly: licenses.filter((l) => l.type === "yearly").length,
        lifetime: licenses.filter((l) => l.type === "lifetime").length,
      },
    },
  };
}
