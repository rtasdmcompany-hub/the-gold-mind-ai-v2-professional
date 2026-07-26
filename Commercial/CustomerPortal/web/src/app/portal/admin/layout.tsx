import { auth } from "@/auth";
import { redirect } from "next/navigation";
import Link from "next/link";
import {
  canAccessAdminConsole,
  hasPermission,
  ROLE_LABELS,
  type AdminPermission,
} from "@/server/admin/roles";
import { getAdminIdleTimeoutMinutes } from "@/server/admin/security";
import { isDevAdminBypass } from "@/server/security/dev-bypass";
import { AdminIdleGuard } from "@/components/AdminIdleGuard";
import { AiAssistantWidget } from "@/components/AiAssistantWidget";

const ADMIN_LINKS: { href: string; label: string; permission: AdminPermission }[] = [
  { href: "/portal/admin", label: "Operations Hub", permission: "admin.dashboard" },
  { href: "/portal/admin/global-ops", label: "Global Ops", permission: "admin.launch.read" },
  { href: "/portal/admin/bi-executive", label: "BI Executive", permission: "admin.launch.read" },
  { href: "/portal/admin/bi-revenue", label: "BI Revenue", permission: "admin.launch.read" },
  { href: "/portal/admin/bi-subscriptions", label: "BI Subs / Ops", permission: "admin.launch.read" },
  { href: "/portal/admin/bi-customers", label: "BI Customers", permission: "admin.launch.read" },
  { href: "/portal/admin/partners", label: "Partners", permission: "admin.launch.read" },
  { href: "/portal/admin/partner-analytics", label: "Partner Analytics", permission: "admin.launch.read" },
  { href: "/portal/admin/enterprise-crm", label: "Enterprise CRM", permission: "admin.launch.read" },
  { href: "/portal/admin/organizations", label: "Organizations", permission: "admin.launch.read" },
  { href: "/portal/admin/enterprise-success", label: "Enterprise Success", permission: "admin.launch.read" },
  { href: "/portal/admin/localization", label: "Localization", permission: "admin.launch.read" },
  { href: "/portal/admin/localization-qa", label: "Localization QA", permission: "admin.launch.read" },
  { href: "/portal/admin/mobile", label: "Mobile Companion", permission: "admin.launch.read" },
  { href: "/portal/admin/mobile-security", label: "Mobile Security", permission: "admin.launch.read" },
  { href: "/portal/admin/ai-assistant", label: "AI Assistant", permission: "admin.launch.read" },
  { href: "/portal/admin/ai-analytics", label: "AI Analytics", permission: "admin.launch.read" },
  { href: "/portal/admin/api-platform", label: "API Platform", permission: "admin.launch.read" },
  { href: "/portal/admin/api-webhooks", label: "API Webhooks", permission: "admin.launch.read" },
  { href: "/portal/admin/ops-center", label: "Ops Center", permission: "admin.launch.read" },
  { href: "/portal/admin/infra-capacity", label: "Infra Capacity", permission: "admin.launch.read" },
  { href: "/portal/admin/sla-executive", label: "SLA Executive", permission: "admin.launch.read" },
  { href: "/portal/admin/phase11-certification", label: "Phase 11 Cert", permission: "admin.launch.read" },
  { href: "/portal/admin/phase11-decision", label: "Phase 11 Decision", permission: "admin.launch.read" },
  { href: "/portal/admin/phase12-lts", label: "Phase 12 LTS", permission: "admin.launch.read" },
  { href: "/portal/admin/phase12-customer-success", label: "P12 Customer Success", permission: "admin.launch.read" },
  { href: "/portal/admin/phase12-monthly", label: "P12 Monthly", permission: "admin.launch.read" },
  { href: "/portal/admin/phase12-v2-planning", label: "P12 V2 Planning", permission: "admin.launch.read" },
  { href: "/portal/admin/business-kpis", label: "Business KPIs", permission: "admin.launch.read" },
  { href: "/portal/admin/commercial-ops", label: "Commercial Ops", permission: "admin.launch.read" },
  { href: "/portal/admin/cs-operations", label: "CS Operations", permission: "admin.launch.read" },
  { href: "/portal/admin/phase10-closure", label: "Phase 10 Closure", permission: "admin.launch.read" },
  { href: "/portal/admin/go-no-go", label: "Go / No-Go", permission: "admin.launch.read" },
  { href: "/portal/admin/executive-scorecard", label: "Exec Scorecard", permission: "admin.launch.read" },
  { href: "/portal/admin/website-launch", label: "Website Launch", permission: "admin.launch.read" },
  { href: "/portal/admin/customer-journey", label: "Customer Journey", permission: "admin.launch.read" },
  { href: "/portal/admin/commercial-workflows", label: "Commercial Workflows", permission: "admin.launch.read" },
  { href: "/portal/admin/production-deployment", label: "Prod Deployment", permission: "admin.launch.read" },
  { href: "/portal/admin/market", label: "MQL5 Market", permission: "admin.releases.read" },
  { href: "/portal/admin/mql5-compliance", label: "MQL5 Compliance", permission: "admin.releases.read" },
  { href: "/portal/admin/store-assets", label: "Store Assets", permission: "admin.releases.read" },
  { href: "/portal/admin/store-metadata", label: "Store Metadata", permission: "admin.releases.read" },
  { href: "/portal/admin/security-audit", label: "Security Audit", permission: "admin.security.manage" },
  { href: "/portal/admin/pentest", label: "Penetration Tests", permission: "admin.security.manage" },
  { href: "/portal/admin/owasp", label: "OWASP Review", permission: "admin.security.manage" },
  { href: "/portal/admin/secret-management", label: "Secrets", permission: "admin.security.manage" },
  { href: "/portal/admin/data-protection", label: "Data Protection", permission: "admin.security.manage" },
  { href: "/portal/admin/disaster-recovery", label: "Disaster Recovery", permission: "admin.security.manage" },
  { href: "/portal/admin/compliance", label: "Compliance", permission: "admin.security.manage" },
  { href: "/portal/admin/performance", label: "Performance", permission: "admin.observability.read" },
  { href: "/portal/admin/benchmarks", label: "Benchmarks", permission: "admin.observability.read" },
  { href: "/portal/admin/scalability", label: "Scalability", permission: "admin.observability.read" },
  { href: "/portal/admin/load-tests", label: "Load Tests", permission: "admin.observability.read" },
  { href: "/portal/admin/database-optimization", label: "DB Optimization", permission: "admin.observability.read" },
  { href: "/portal/admin/cloud-performance", label: "Cloud Performance", permission: "admin.observability.read" },
  { href: "/portal/admin/resilience", label: "Resilience", permission: "admin.observability.read" },
  { href: "/portal/admin/success", label: "CS Executive", permission: "admin.launch.read" },
  { href: "/portal/admin/customer-success", label: "Customer Success", permission: "admin.support.read" },
  { href: "/portal/admin/support-analytics", label: "Support Analytics", permission: "admin.support.read" },
  { href: "/portal/admin/stabilization", label: "Stabilization", permission: "admin.launch.read" },
  { href: "/portal/admin/observability", label: "Observability", permission: "admin.observability.read" },
  { href: "/portal/admin/telemetry", label: "Telemetry", permission: "admin.observability.read" },
  { href: "/portal/admin/usage", label: "Usage Analytics", permission: "admin.observability.read" },
  { href: "/portal/admin/alerts", label: "Alerts", permission: "admin.observability.read" },
  { href: "/portal/admin/ops-intelligence", label: "Ops Intelligence", permission: "admin.observability.read" },
  { href: "/portal/admin/incident-timeline", label: "Incident Timeline", permission: "admin.observability.read" },
  { href: "/portal/admin/monitoring-security", label: "Monitoring Security", permission: "admin.observability.read" },
  { href: "/portal/admin/launch", label: "Launch Dashboard", permission: "admin.launch.read" },
  { href: "/portal/admin/beta-dashboard", label: "Beta Dashboard", permission: "admin.launch.read" },
  { href: "/portal/admin/beta", label: "Beta Program", permission: "admin.launch.read" },
  { href: "/portal/admin/issues", label: "Issues", permission: "admin.launch.read" },
  { href: "/portal/admin/metrics", label: "Metrics", permission: "admin.launch.read" },
  { href: "/portal/admin/incidents", label: "Incidents", permission: "admin.launch.read" },
  { href: "/portal/admin/feedback", label: "Feedback", permission: "admin.launch.read" },
  { href: "/portal/admin/customers", label: "Customers", permission: "admin.customers.read" },
  { href: "/portal/admin/licenses", label: "Licenses", permission: "admin.licenses.read" },
  { href: "/portal/admin/support", label: "Support Console", permission: "admin.support.read" },
  { href: "/portal/admin/bi", label: "Business Intelligence", permission: "admin.bi.read" },
  { href: "/portal/admin/audit", label: "Audit Center", permission: "admin.audit.read" },
  { href: "/portal/admin/billing", label: "Billing", permission: "admin.billing.read" },
  { href: "/portal/admin/releases", label: "Releases", permission: "admin.releases.read" },
  { href: "/portal/admin/cloud", label: "Cloud Health", permission: "admin.cloud.read" },
  { href: "/portal/admin/security", label: "Admin Security", permission: "admin.security.manage" },
  { href: "/portal/admin/roles", label: "Roles & Permissions", permission: "admin.roles.manage" },
];

export default async function AdminLayout({ children }: { children: React.ReactNode }) {
  const session = await auth();
  const email = session?.user?.email?.toLowerCase() || "";
  const role = (session?.user as { role?: string } | undefined)?.role || "customer";
  if (!canAccessAdminConsole(role) && !isDevAdminBypass(email)) {
    redirect("/portal");
  }

  const links = ADMIN_LINKS.filter(
    (l) => isDevAdminBypass(email) || hasPermission(role, l.permission)
  );
  const idleMin = getAdminIdleTimeoutMinutes();

  return (
    <div>
      <AdminIdleGuard timeoutMinutes={idleMin} />
      <div
        className="card"
        style={{ marginBottom: 16, display: "flex", flexWrap: "wrap", gap: 8, alignItems: "center" }}
      >
        <strong style={{ marginRight: 8 }}>Enterprise Admin</strong>
        <span className="meta">
          {ROLE_LABELS[role] || role} · {email} · idle {idleMin}m
        </span>
        <span className="meta" style={{ marginLeft: "auto" }}>
          Commercial services only — Trading Engine isolated
        </span>
      </div>
      <nav aria-label="Admin sections" style={{ display: "flex", flexWrap: "wrap", gap: 8, marginBottom: 20 }}>
        {links.map((l) => (
          <Link key={l.href} href={l.href} className="btn">
            {l.label}
          </Link>
        ))}
      </nav>
      {children}
      <AiAssistantWidget surface="admin_portal" role="admin" customerEmail={email} title="Admin AI" />
    </div>
  );
}
