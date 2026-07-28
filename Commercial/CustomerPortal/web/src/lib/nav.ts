export const customerNav = [
  { href: "/portal", label: "Dashboard" },
  { href: "/portal/trading", label: "Trading Account" },
  { href: "/portal/licenses", label: "My Licenses" },
  { href: "/portal/downloads", label: "Downloads" },
  { href: "/portal/updates", label: "Updates" },
  { href: "/portal/billing", label: "Billing" },
  { href: "/portal/subscriptions", label: "Subscriptions" },
  { href: "/portal/devices", label: "Devices" },
  { href: "/portal/invoices", label: "Invoices" },
  { href: "/portal/orders", label: "Orders" },
  { href: "/portal/support", label: "Support" },
  { href: "/portal/partner", label: "Partner Portal" },
  { href: "/portal/beta", label: "Beta Onboarding" },
  { href: "/portal/feedback", label: "Feedback" },
  { href: "/portal/knowledge-base", label: "Knowledge Base" },
  { href: "/portal/announcements", label: "Announcements" },
  { href: "/portal/account", label: "Account Settings" },
  { href: "/portal/security", label: "Security" },
] as const;

/** @deprecated use customerNav + admin entry */
export const portalNav = [
  ...customerNav,
  { href: "/portal/admin", label: "Admin Console" },
] as const;
