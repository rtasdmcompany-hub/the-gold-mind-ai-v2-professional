/**
 * Global infrastructure inventory — review + optimization notes.
 */
import type { InfraComponent, RegionCode } from "./types";

const REGIONS: RegionCode[] = ["us-east", "eu-west", "ap-south", "me-central"];

export function getInfrastructureInventory(): InfraComponent[] {
  return [
    {
      id: "cloudflare",
      name: "Cloudflare",
      role: "DNS · CDN · WAF · SSL edge · regional routing",
      regions: REGIONS,
      status: "healthy",
      haEnabled: true,
      notes: "Primary edge for website, portal, and API.",
      optimization: [
        "Enable Argo Smart Routing for API paths under load",
        "Tighten WAF managed rules for /api/v1/*",
        "Cache static marketing assets aggressively; bypass portal cookies",
      ],
    },
    {
      id: "vercel",
      name: "Vercel",
      role: "Next.js portal · serverless API routes · edge middleware",
      regions: ["us-east", "eu-west"],
      status: "healthy",
      haEnabled: true,
      notes: "Customer Portal + Developer Portal + commercial APIs.",
      optimization: [
        "Pin production to dual regions with automatic failover",
        "Split long-running jobs off serverless to workers",
        "Use ISR/static where safe for marketing pages",
      ],
    },
    {
      id: "supabase",
      name: "Supabase",
      role: "Managed Postgres · auth adjunct · backups",
      regions: ["us-east", "eu-west"],
      status: "healthy",
      haEnabled: true,
      notes: "Commercial data plane (licenses/billing metadata) — not Core.",
      optimization: [
        "Enable PITR and cross-region read replica for DR",
        "Connection pooling via PgBouncer / Supavisor",
        "Index hot paths: licenses by email, audit by created_at",
      ],
    },
    {
      id: "runpod",
      name: "RunPod",
      role: "Optional GPU / batch workers (non-trading compute)",
      regions: ["us-east", "eu-west"],
      status: "planned",
      haEnabled: false,
      notes: "Reserved for future media/ML support jobs — never trading.",
      optimization: [
        "Keep idle pods scaled to zero",
        "Use spot where interruption-tolerant",
        "Isolate network from Core and trading brokers",
      ],
    },
    {
      id: "upstash_redis",
      name: "Upstash Redis",
      role: "Rate limits · session cache · queue coordination · feature flags",
      regions: ["us-east", "eu-west"],
      status: "healthy",
      haEnabled: true,
      notes: "Global Redis for API gateway and ops caches.",
      optimization: [
        "Multi-region active-passive with TTL-safe keys",
        "Separate DB indexes for rate-limit vs session",
        "Evict analytics keys aggressively",
      ],
    },
    {
      id: "object_storage",
      name: "Object Storage",
      role: "Installers · docs · SDK artifacts · backups",
      regions: REGIONS,
      status: "healthy",
      haEnabled: true,
      notes: "S3-compatible buckets fronted by CDN.",
      optimization: [
        "Lifecycle policies for old release artifacts",
        "Checksum + signed URLs for downloads",
        "Cross-region replication for disaster recovery",
      ],
    },
    {
      id: "dns",
      name: "DNS",
      role: "Authoritative DNS via Cloudflare",
      regions: REGIONS,
      status: "healthy",
      haEnabled: true,
      notes: "Low TTL on API failover records; higher TTL on marketing.",
      optimization: ["Health-check steered failover records", "CAA records for SSL issuance"],
    },
    {
      id: "ssl",
      name: "SSL Certificates",
      role: "TLS 1.2+ edge certificates",
      regions: REGIONS,
      status: "healthy",
      haEnabled: true,
      notes: "Universal SSL + custom hostnames for portal/API.",
      optimization: ["Enforce HSTS", "Disable legacy TLS", "Monitor expiry automation"],
    },
    {
      id: "cdn",
      name: "CDN Configuration",
      role: "Static + API edge caching policy",
      regions: REGIONS,
      status: "healthy",
      haEnabled: true,
      notes: "Portal HTML largely uncached; assets cached.",
      optimization: ["Cache /developers static docs", "Vary on Accept-Encoding only where safe"],
    },
    {
      id: "regional_routing",
      name: "Regional Routing",
      role: "Steer users to nearest healthy region",
      regions: REGIONS,
      status: "healthy",
      haEnabled: true,
      notes: "Latency-based routing with failover to us-east.",
      optimization: ["Publish regional status page targets", "Synthetic checks from each region"],
    },
  ];
}

export function infrastructureSummary() {
  const items = getInfrastructureInventory();
  return {
    total: items.length,
    healthy: items.filter((i) => i.status === "healthy").length,
    degraded: items.filter((i) => i.status === "degraded").length,
    planned: items.filter((i) => i.status === "planned").length,
    haEnabled: items.filter((i) => i.haEnabled).length,
    regions: REGIONS,
    items,
  };
}
