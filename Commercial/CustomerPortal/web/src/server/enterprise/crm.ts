/**
 * Enterprise CRM aggregations — org-scoped.
 */
import { listSupportTickets } from "@/server/admin/support-store";
import type { CrmLead } from "./types";
import {
  appendOrgAudit,
  forOrg,
  mutateEnterpriseStore,
  newId,
  readEnterpriseStore,
} from "./store";
import { computeOrgHealth } from "./success";

export function createLead(input: {
  company: string;
  contactEmail: string;
  contactName: string;
  source?: string;
  actor: string;
}): CrmLead {
  let lead: CrmLead | null = null;
  mutateEnterpriseStore((d) => {
    lead = {
      id: newId("lead"),
      company: input.company,
      contactEmail: input.contactEmail.toLowerCase(),
      contactName: input.contactName,
      status: "new",
      source: input.source,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    };
    d.leads.unshift(lead);
  });
  return lead!;
}

export function convertLeadToCustomer(leadId: string, orgId: string, actor: string): void {
  mutateEnterpriseStore((d) => {
    const lead = d.leads.find((l) => l.id === leadId);
    if (!lead) throw new Error("LEAD_NOT_FOUND");
    lead.status = "won";
    lead.orgId = orgId;
    lead.updatedAt = new Date().toISOString();
    d.audit.unshift({
      id: newId("eaud"),
      orgId,
      at: new Date().toISOString(),
      actor,
      action: "lead_convert",
      detail: leadId,
      immutable: true,
    });
  });
}

export function buildCrmDashboard(orgId?: string) {
  const store = readEnterpriseStore();
  const orgs = orgId ? store.organizations.filter((o) => o.id === orgId) : store.organizations;
  const tickets = (() => {
    try {
      return listSupportTickets();
    } catch {
      return [];
    }
  })();

  const rows = orgs.map((org) => {
    const contacts = forOrg(store.contacts, org.id);
    const subs = forOrg(store.subscriptions, org.id);
    const licenses = forOrg(store.seats, org.id);
    const invoices = forOrg(store.invoices, org.id);
    const renewals = subs.filter((s) => s.status === "active" || s.status === "trialing");
    const health = computeOrgHealth(org.id);
    const supportHistory = tickets
      .filter((t) => contacts.some((c) => c.email === t.customerEmail.toLowerCase()))
      .slice(0, 10)
      .map((t) => ({ id: t.id, subject: t.subject, status: t.status }));

    return {
      organization: org,
      contacts,
      leadsLinked: store.leads.filter((l) => l.orgId === org.id),
      customers: org.status === "active" || org.status === "trial" ? 1 : 0,
      subscriptions: subs,
      licenses: {
        total: licenses.length,
        assigned: licenses.filter((s) => s.status === "assigned").length,
      },
      supportHistory,
      renewals,
      invoices,
      customerHealthScore: health.score,
    };
  });

  return {
    organizations: rows,
    totalOrgs: store.organizations.length,
    totalLeads: store.leads.length,
    openLeads: store.leads.filter((l) => l.status === "new" || l.status === "qualified").length,
    at: new Date().toISOString(),
  };
}

export function addBillingContact(orgId: string, email: string, name: string, actor: string): void {
  mutateEnterpriseStore((d) => {
    d.contacts.unshift({
      id: newId("ctc"),
      orgId,
      email: email.toLowerCase(),
      name,
      role: "billing",
      createdAt: new Date().toISOString(),
    });
  });
  appendOrgAudit(orgId, actor, "billing_contact_add", email);
}
