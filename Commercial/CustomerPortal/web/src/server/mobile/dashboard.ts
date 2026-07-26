/**
 * Mobile customer dashboard — profile, licenses, billing, support, health.
 * Reads commercial licensing APIs only — zero Core / trading data.
 */
import { listLicensesForCustomer } from "@/server/licensing/license-service";
import { listDevicesForCustomer as listLicenseDevices } from "@/server/licensing/device-service";
import type { DevicePublicDto, LicensePublicDto } from "@/server/licensing/types";
import { listDevicesForCustomer, listSessionsForCustomer } from "./auth";
import { listPushInbox, getPushPreferences } from "./push";
import { listTicketsForCustomer, listKnowledgeArticles, listFaqs } from "./support";
import { readMobileStore } from "./store";
import { MOBILE_CORE_ISOLATION, MOBILE_TRADING_PROHIBITED } from "./types";

function safeLicenses(email: string): LicensePublicDto[] {
  try {
    return listLicensesForCustomer(email);
  } catch {
    return [];
  }
}

function safeLicenseDevices(email: string): DevicePublicDto[] {
  try {
    return listLicenseDevices(email);
  } catch {
    return [];
  }
}

export function buildMobileCustomerDashboard(email: string) {
  const e = email.toLowerCase();
  const licenses = safeLicenses(e);
  const active = licenses.filter((l) => l.status === "active" || l.status === "grace");
  const licenseDevices = safeLicenseDevices(e);
  const mobileDevices = listDevicesForCustomer(e).filter((d) => !d.revokedAt);
  const sessions = listSessionsForCustomer(e).filter((s) => !s.revokedAt);
  const inbox = listPushInbox(e).slice(0, 10);
  const tickets = listTicketsForCustomer(e);
  const prefs = getPushPreferences(e);
  const versions = readMobileStore().appVersions;

  const renewalDate =
    active
      .map((l) => l.expiresAt)
      .filter(Boolean)
      .sort()[0] || null;

  return {
    profile: {
      email: e,
      displayName: e.split("@")[0],
      trustedDevices: mobileDevices.filter((d) => d.trusted).length,
      biometricDevices: mobileDevices.filter((d) => d.biometricEnabled).length,
    },
    licenseStatus: {
      total: licenses.length,
      active: active.length,
      items: licenses.slice(0, 20),
    },
    subscriptionStatus: {
      hasActiveSubscription: active.length > 0,
      renewalDate,
      planSummary: active[0]?.type || "none",
    },
    renewalDate,
    invoices: [] as { id: string; amountCents: number; status: string; at: string }[],
    downloads: [
      { id: "installer", label: "Windows Installer", channel: "stable" },
      { id: "docs", label: "User Guide PDF", channel: "docs" },
    ],
    supportTickets: tickets.slice(0, 10),
    announcements: inbox.filter((m) => m.category === "maintenance" || m.category === "software_update"),
    platformHealth: {
      api: "healthy",
      push: "healthy",
      auth: "healthy",
      tradingEngineOnMobile: false,
      note: MOBILE_CORE_ISOLATION,
    },
    knowledgePreview: listKnowledgeArticles().slice(0, 5),
    faqsPreview: listFaqs().slice(0, 5),
    mobileDevices,
    licenseDevices: licenseDevices.slice(0, 20),
    activeSessions: sessions.length,
    pushOptInMarketing: prefs.categories.marketing,
    appVersions: versions,
    tradingProhibited: MOBILE_TRADING_PROHIBITED,
    at: new Date().toISOString(),
  };
}
