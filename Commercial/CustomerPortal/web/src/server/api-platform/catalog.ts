/**
 * API catalog for Developer Portal documentation & explorer.
 */
import { ALL_COMMERCIAL_SCOPES, API_PLATFORM_VERSION, FORBIDDEN_API_TOPICS } from "./types";
import { webhookCatalog } from "./webhooks";

export function apiEndpointCatalog() {
  return [
    { method: "GET", path: "/api/v1/profile", scope: "profile:read", summary: "Customer profile" },
    { method: "GET", path: "/api/v1/licenses", scope: "licenses:read", summary: "Licenses & devices" },
    { method: "GET", path: "/api/v1/subscriptions", scope: "subscriptions:read", summary: "Subscriptions" },
    { method: "GET", path: "/api/v1/invoices", scope: "invoices:read", summary: "Invoices" },
    { method: "GET", path: "/api/v1/downloads", scope: "downloads:read", summary: "Download catalog" },
    { method: "GET", path: "/api/v1/notifications", scope: "notifications:read", summary: "Notifications" },
    { method: "GET", path: "/api/v1/support/tickets", scope: "support:read", summary: "Support tickets" },
    { method: "GET", path: "/api/v1/partners", scope: "partners:read", summary: "Partner profile" },
    { method: "GET", path: "/api/v1/organizations", scope: "organizations:read", summary: "Organizations" },
    { method: "GET", path: "/api/v1/webhooks", scope: "webhooks:manage", summary: "List webhooks" },
    { method: "POST", path: "/api/v1/webhooks", scope: "webhooks:manage", summary: "Register webhook" },
    { method: "POST", path: "/api/v1/oauth/token", scope: "—", summary: "OAuth client credentials" },
    { method: "GET", path: "/api/v1/health", scope: "public", summary: "API health" },
  ];
}

export function versionHistory() {
  return [
    {
      version: "v1",
      status: "current",
      released: "2026-07-26",
      notes: "Initial Enterprise API Platform — commercial resources only",
    },
  ];
}

export function changelog() {
  return [
    {
      date: "2026-07-26",
      version: "v1.0.0",
      items: [
        "API Gateway with versioning, auth, rate limits, usage analytics",
        "Developer Portal + SDK samples",
        "Webhook platform with signing and retries",
        "Hard isolation from Core Trading Engine",
      ],
    },
  ];
}

export function developerPortalNav() {
  return [
    { href: "/developers", label: "Dashboard" },
    { href: "/developers/docs", label: "API Documentation" },
    { href: "/developers/quickstart", label: "Quick Start" },
    { href: "/developers/sdks", label: "SDK Downloads" },
    { href: "/developers/explorer", label: "API Explorer" },
    { href: "/developers/auth", label: "Authentication" },
    { href: "/developers/webhooks", label: "Webhooks" },
    { href: "/developers/changelog", label: "Changelog" },
    { href: "/developers/status", label: "Status" },
  ];
}

export function fullCatalog() {
  return {
    version: API_PLATFORM_VERSION,
    scopes: ALL_COMMERCIAL_SCOPES,
    endpoints: apiEndpointCatalog(),
    webhooks: webhookCatalog(),
    versions: versionHistory(),
    changelog: changelog(),
    forbidden: FORBIDDEN_API_TOPICS,
    nav: developerPortalNav(),
  };
}
