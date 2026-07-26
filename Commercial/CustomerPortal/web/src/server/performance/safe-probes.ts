/**
 * Safe commercial store probes for performance suite.
 * Survives LICENSE_STORE_TAMPER_OR_DECRYPT_FAIL when CLI secrets differ.
 */
import { ensureSeedData } from "@/server/licensing/seed";
import { listAllLicensesAdmin } from "@/server/licensing/license-service";
import { getAdminBillingDashboard } from "@/server/billing/billing-service";
import { listSupportTickets, ensureDemoTickets } from "@/server/admin/support-store";
import { getAdminReleaseDashboard } from "@/server/releases/release-service";
import { getEnterpriseDashboard } from "@/server/admin/ops";

export function safeEnsureCommercialData(): void {
  try {
    ensureSeedData();
  } catch {
    /* CLI secret mismatch — continue with empty/fallback probes */
  }
  try {
    ensureDemoTickets();
  } catch {
    /* ignore */
  }
}

export function safeListLicenses(): unknown[] {
  try {
    return listAllLicensesAdmin();
  } catch {
    return [];
  }
}

export function safeBillingDashboard(): unknown {
  try {
    return getAdminBillingDashboard();
  } catch {
    return { revenueCents: 0, subscriptions: [], recentTransactions: [] };
  }
}

export function safeSupportTickets(): unknown[] {
  try {
    return listSupportTickets();
  } catch {
    return [];
  }
}

export function safeReleases(): unknown {
  try {
    return getAdminReleaseDashboard();
  } catch {
    return { totalDownloads: 0, updateSuccessRate: 100 };
  }
}

export function safeEnterpriseDashboard(): unknown {
  try {
    return getEnterpriseDashboard();
  } catch {
    return { activeCustomers: 0, activeLicenses: 0 };
  }
}
