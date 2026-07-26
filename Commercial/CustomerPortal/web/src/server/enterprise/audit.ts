/**
 * Enterprise audit & compliance views — immutable org logs.
 */
import { forOrg, readEnterpriseStore } from "./store";

export function buildAuditComplianceReport(orgId: string) {
  const store = readEnterpriseStore();
  const audit = forOrg(store.audit, orgId);
  const licenseChanges = forOrg(store.licenseAudit, orgId);
  const logins = forOrg(store.logins, orgId);
  const roleChanges = audit.filter((a) => a.action === "role_change");
  const billingEvents = audit.filter((a) => a.action.startsWith("billing_"));
  const adminActions = audit.filter((a) =>
    ["org_settings", "member_add", "custom_role_create", "org_register"].includes(a.action)
  );

  return {
    orgId,
    immutable: true,
    userLogins: logins.slice(0, 50),
    roleChanges: roleChanges.slice(0, 50),
    licenseChanges: licenseChanges.slice(0, 50),
    billingEvents: billingEvents.slice(0, 50),
    administrativeActions: adminActions.slice(0, 50),
    organizationActivity: audit.slice(0, 100),
    totals: {
      auditEntries: audit.length,
      licenseAuditEntries: licenseChanges.length,
      logins: logins.length,
    },
    isolationNote: "All entries are scoped by orgId — multi-tenant isolation enforced",
    at: new Date().toISOString(),
  };
}
