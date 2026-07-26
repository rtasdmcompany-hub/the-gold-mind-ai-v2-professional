/**
 * Commercial API resource aggregators — never touches Core Trading Engine.
 */
import { listLicensesForCustomer } from "@/server/licensing/license-service";
import { listDevicesForCustomer } from "@/server/licensing/device-service";
import { listSubscriptionsForCustomer } from "@/server/licensing/subscription-service";
import { getPartnerByEmail } from "@/server/partners/portal";
import { readEnterpriseStore } from "@/server/enterprise/store";
import { listPushInbox } from "@/server/mobile/push";
import { listTicketsForCustomer } from "@/server/mobile/support";
import { API_CORE_ISOLATION } from "./types";

function safe<T>(fn: () => T, fallback: T): T {
  try {
    return fn();
  } catch {
    return fallback;
  }
}

export function commercialProfile(email: string) {
  return {
    email: email.toLowerCase(),
    displayName: email.split("@")[0],
    isolation: API_CORE_ISOLATION,
  };
}

export function commercialLicenses(email: string) {
  return {
    licenses: safe(() => listLicensesForCustomer(email), []),
    devices: safe(() => listDevicesForCustomer(email), []),
  };
}

export function commercialSubscriptions(email: string) {
  return { subscriptions: safe(() => listSubscriptionsForCustomer(email), []) };
}

export function commercialInvoices(email: string) {
  void email;
  return {
    invoices: [] as { id: string; amountCents: number; status: string; at: string }[],
    note: "Invoice projection via commercial billing; empty when store unavailable",
  };
}

export function commercialDownloads() {
  return {
    downloads: [
      { id: "installer", label: "Windows Installer", channel: "stable" },
      { id: "docs", label: "User Guide", channel: "docs" },
    ],
  };
}

export function commercialNotifications(email: string) {
  return { notifications: safe(() => listPushInbox(email).slice(0, 50), []) };
}

export function commercialSupportTickets(email: string) {
  return { tickets: safe(() => listTicketsForCustomer(email), []) };
}

export function commercialPartner(email: string) {
  const partner = safe(() => getPartnerByEmail(email), null);
  return {
    partner: partner
      ? { id: partner.id, name: partner.name, tier: partner.tier, status: partner.status }
      : null,
  };
}

export function commercialOrganizations(email: string) {
  const store = safe(() => readEnterpriseStore(), null);
  if (!store) return { organizations: [] };
  const memberOrgIds = new Set(
    store.members.filter((m) => m.email === email.toLowerCase()).map((m) => m.orgId)
  );
  const orgs = store.organizations.filter((o) => memberOrgIds.has(o.id));
  return {
    organizations: orgs.map((o) => ({
      id: o.id,
      name: o.name,
      status: o.status,
    })),
  };
}
