/**
 * Independently deployable cloud service registry (logical modules).
 * Each service can later move to its own process/host; interfaces stay stable.
 * Trading Engine is NOT a member of this registry.
 */

export type CloudServiceId =
  | "portal"
  | "license"
  | "subscription"
  | "update"
  | "notification"
  | "analytics"
  | "support"
  | "gateway"
  | "audit"
  | "cache";

export interface CloudServiceDescriptor {
  id: CloudServiceId;
  name: string;
  deployable: true;
  basePath: string;
  description: string;
  dependsOn: CloudServiceId[];
  tradingEngineCoupled: false;
}

export const CLOUD_SERVICES: CloudServiceDescriptor[] = [
  {
    id: "gateway",
    name: "API Gateway",
    deployable: true,
    basePath: "/api",
    description: "Auth · rate limit · versioning · standard responses",
    dependsOn: ["cache", "audit"],
    tradingEngineCoupled: false,
  },
  {
    id: "portal",
    name: "Customer Portal",
    deployable: true,
    basePath: "/portal",
    description: "Customer & admin UI",
    dependsOn: ["gateway", "license", "subscription"],
    tradingEngineCoupled: false,
  },
  {
    id: "license",
    name: "License Service",
    deployable: true,
    basePath: "/api/licenses",
    description: "License issue · activate · validate · devices",
    dependsOn: ["audit", "cache"],
    tradingEngineCoupled: false,
  },
  {
    id: "subscription",
    name: "Subscription Service",
    deployable: true,
    basePath: "/api/billing",
    description: "Plans · payments · invoices · webhooks",
    dependsOn: ["license", "notification", "audit"],
    tradingEngineCoupled: false,
  },
  {
    id: "update",
    name: "Update Service",
    deployable: true,
    basePath: "/api/releases",
    description: "Release catalog · downloads · updater telemetry",
    dependsOn: ["audit", "cache"],
    tradingEngineCoupled: false,
  },
  {
    id: "notification",
    name: "Notification Service",
    deployable: true,
    basePath: "/api/cloud/notifications",
    description: "Transactional email outbox · commercial alerts",
    dependsOn: ["audit"],
    tradingEngineCoupled: false,
  },
  {
    id: "analytics",
    name: "Analytics Service",
    deployable: true,
    basePath: "/api/cloud/analytics",
    description: "Commercial metrics · download/update funnels",
    dependsOn: ["audit"],
    tradingEngineCoupled: false,
  },
  {
    id: "support",
    name: "Support Service",
    deployable: true,
    basePath: "/api/cloud/support",
    description: "Ticket intake · KB · support role actions",
    dependsOn: ["audit", "portal"],
    tradingEngineCoupled: false,
  },
  {
    id: "audit",
    name: "Audit Service",
    deployable: true,
    basePath: "/api/cloud/audit",
    description: "Centralized audit log",
    dependsOn: [],
    tradingEngineCoupled: false,
  },
  {
    id: "cache",
    name: "Cache Service",
    deployable: true,
    basePath: "upstash://",
    description: "Upstash Redis / memory fallback",
    dependsOn: [],
    tradingEngineCoupled: false,
  },
];

export function listCloudServices(): CloudServiceDescriptor[] {
  return CLOUD_SERVICES;
}

export function getCloudService(id: CloudServiceId): CloudServiceDescriptor | undefined {
  return CLOUD_SERVICES.find((s) => s.id === id);
}
