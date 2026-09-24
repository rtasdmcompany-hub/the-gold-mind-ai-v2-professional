/**
 * Task 6 — Customer Success dashboards (Phase 11).
 */
import {
  safeBillingDashboard,
  safeCustomerHealthDirectory,
  safeCustomerSuccessSummary,
  safeEnsureCommercialData,
  safeListLicenses,
  safeSupportTickets,
} from "./safe";
import { savePhase11Run } from "./store";

export async function buildCustomerSuccessDashboard() {
  safeEnsureCommercialData();
  const licenses = await safeListLicenses();
  const billing = safeBillingDashboard();
  const tickets = safeSupportTickets();
  
  // FIX: Added await here
  const summary = await safeCustomerSuccessSummary();
  const directory = await safeCustomerHealthDirectory();

  const emails = new Set(licenses.map((l) => l.customerEmail.toLowerCase()));
  const trialEmails = new Set(
    licenses.filter((l) => l.type === "trial").map((l) => l.customerEmail.toLowerCase())
  );
  const paidEmails = new Set(
    licenses
      .filter((l) => l.type !== "trial" && (l.status === "active" || l.status === "grace"))
      .map((l) => l.customerEmail.toLowerCase())
  );
  const today = new Date().toISOString().slice(0, 10);
  const newCustomers = licenses
    .filter((l) => l.createdAt?.slice(0, 10) === today)
    .map((l) => l.customerEmail.toLowerCase());
  const uniqueNew = [...new Set(newCustomers)];

  const renewalsDue = billing.renewals.slice(0, 20).map((r) => ({
    id: r.id,
    email: r.customerEmail,
    at: r.createdAt,
  }));

  const churnRisk = directory
    .filter((c) => c.healthScore < 50)
    .slice(0, 25)
    .map((c) => ({
      email: c.email,
      healthScore: c.healthScore,
      openTickets: c.openTickets,
      licenseStatus: c.licenseStatus,
    }));

  const supportHistory = tickets.slice(0, 25).map((t) => ({
    id: t.id,
    email: t.customerEmail,
    subject: t.subject,
    status: t.status,
    priority: t.priority,
    updatedAt: t.updatedAt,
  }));

  const payload = {
    newCustomers: { count: uniqueNew.length, emails: uniqueNew.slice(0, 20) },
    trialCustomers: { count: trialEmails.size },
    paidCustomers: { count: paidEmails.size },
    renewals: { count: billing.renewals.length, sample: renewalsDue },
    churnRisk: { count: churnRisk.length, customers: churnRisk },
    supportHistory,
    customerSatisfaction: summary.avgSatisfaction,
    avgHealthScore: summary.avgHealthScore,
    atRisk: summary.atRisk,
    totalTracked: emails.size || summary.customersTracked,
    traceable: true,
    at: new Date().toISOString(),
  };
  savePhase11Run("success", "Customer Success dashboard snapshot", payload);
  return payload;
}