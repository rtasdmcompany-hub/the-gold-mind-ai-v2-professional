/**
 * Enterprise billing — org subscriptions, invoices, POs, renewals/upgrades.
 */
import type { OrgInvoice, OrgSubscription, PurchaseOrder } from "./types";
import { mutateEnterpriseStore, newId, readEnterpriseStore } from "./store";
import { createLicensePool } from "./licensing";

export function createOrgSubscription(input: {
  orgId: string;
  planCode: string;
  seats: number;
  amountCents: number;
  actor: string;
  createPool?: boolean;
}): OrgSubscription {
  let sub: OrgSubscription | null = null;
  mutateEnterpriseStore((d) => {
    if (!d.organizations.some((o) => o.id === input.orgId)) throw new Error("ORG_NOT_FOUND");
    const renewal = new Date();
    renewal.setUTCMonth(renewal.getUTCMonth() + 1);
    sub = {
      id: newId("osub"),
      orgId: input.orgId,
      planCode: input.planCode,
      status: "active",
      seats: input.seats,
      amountCents: input.amountCents,
      renewalDate: renewal.toISOString().slice(0, 10),
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    };
    d.subscriptions.unshift(sub);
    d.invoices.unshift({
      id: newId("oinv"),
      orgId: input.orgId,
      subscriptionId: sub.id,
      amountCents: input.amountCents,
      status: "paid",
      createdAt: new Date().toISOString(),
      paidAt: new Date().toISOString(),
    });
    d.audit.unshift({
      id: newId("eaud"),
      orgId: input.orgId,
      at: new Date().toISOString(),
      actor: input.actor,
      action: "billing_subscription_create",
      detail: `${sub.id} ${input.planCode}`,
      immutable: true,
    });
  });
  if (input.createPool !== false) {
    createLicensePool({
      orgId: input.orgId,
      name: `${input.planCode} pool`,
      planCode: input.planCode,
      seats: input.seats,
      subscriptionId: sub!.id,
      actor: input.actor,
    });
  }
  return sub!;
}

export function upgradeSubscription(orgId: string, subscriptionId: string, seats: number, amountCents: number, actor: string): void {
  mutateEnterpriseStore((d) => {
    const s = d.subscriptions.find((x) => x.id === subscriptionId);
    if (!s || s.orgId !== orgId) throw new Error("SUB_NOT_FOUND");
    s.seats = seats;
    s.amountCents = amountCents;
    s.updatedAt = new Date().toISOString();
    d.audit.unshift({
      id: newId("eaud"),
      orgId,
      at: new Date().toISOString(),
      actor,
      action: "billing_upgrade",
      detail: `${subscriptionId} seats=${seats}`,
      immutable: true,
    });
  });
}

export function downgradeSubscription(orgId: string, subscriptionId: string, seats: number, amountCents: number, actor: string): void {
  mutateEnterpriseStore((d) => {
    const s = d.subscriptions.find((x) => x.id === subscriptionId);
    if (!s || s.orgId !== orgId) throw new Error("SUB_NOT_FOUND");
    s.seats = seats;
    s.amountCents = amountCents;
    s.updatedAt = new Date().toISOString();
    d.audit.unshift({
      id: newId("eaud"),
      orgId,
      at: new Date().toISOString(),
      actor,
      action: "billing_downgrade",
      detail: `${subscriptionId} seats=${seats}`,
      immutable: true,
    });
  });
}

export function renewSubscription(orgId: string, subscriptionId: string, actor: string): OrgInvoice {
  let inv: OrgInvoice | null = null;
  mutateEnterpriseStore((d) => {
    const s = d.subscriptions.find((x) => x.id === subscriptionId);
    if (!s || s.orgId !== orgId) throw new Error("SUB_NOT_FOUND");
    const renewal = new Date();
    renewal.setUTCMonth(renewal.getUTCMonth() + 1);
    s.renewalDate = renewal.toISOString().slice(0, 10);
    s.status = "active";
    s.updatedAt = new Date().toISOString();
    inv = {
      id: newId("oinv"),
      orgId,
      subscriptionId,
      amountCents: s.amountCents,
      status: "paid",
      createdAt: new Date().toISOString(),
      paidAt: new Date().toISOString(),
    };
    d.invoices.unshift(inv);
    d.audit.unshift({
      id: newId("eaud"),
      orgId,
      at: new Date().toISOString(),
      actor,
      action: "billing_renewal",
      detail: subscriptionId,
      immutable: true,
    });
  });
  return inv!;
}

export function createPurchaseOrder(orgId: string, poNumber: string, amountCents: number, actor: string): PurchaseOrder {
  let po: PurchaseOrder | null = null;
  mutateEnterpriseStore((d) => {
    po = {
      id: newId("po"),
      orgId,
      poNumber,
      amountCents,
      status: "open",
      createdAt: new Date().toISOString(),
    };
    d.purchaseOrders.unshift(po);
    d.audit.unshift({
      id: newId("eaud"),
      orgId,
      at: new Date().toISOString(),
      actor,
      action: "billing_po_create",
      detail: poNumber,
      immutable: true,
    });
  });
  return po!;
}

export function listOrgBilling(orgId: string) {
  const store = readEnterpriseStore();
  return {
    subscriptions: store.subscriptions.filter((s) => s.orgId === orgId),
    invoices: store.invoices.filter((i) => i.orgId === orgId),
    purchaseOrders: store.purchaseOrders.filter((p) => p.orgId === orgId),
    billingContacts: store.contacts.filter((c) => c.orgId === orgId && c.role === "billing"),
  };
}
