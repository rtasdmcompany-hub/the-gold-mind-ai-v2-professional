import Link from "next/link";
import { fullCatalog } from "@/server/api-platform/catalog";
import { platformHealth } from "@/server/api-platform/usage";
import { API_CORE_ISOLATION } from "@/server/api-platform/types";

export default function DevelopersDashboardPage() {
  const catalog = fullCatalog();
  const health = platformHealth();

  return (
    <>
      <h1 className="page-title">Developer Dashboard</h1>
      <p className="page-sub">{API_CORE_ISOLATION}</p>

      <div className="grid grid-3" style={{ marginBottom: 20 }}>
        <div className="card">
          <h3>API version</h3>
          <div className="value">{catalog.version}</div>
        </div>
        <div className="card">
          <h3>Endpoints</h3>
          <div className="value">{catalog.endpoints.length}</div>
        </div>
        <div className="card">
          <h3>Health</h3>
          <div className="value">{health.status}</div>
        </div>
      </div>

      <div className="card" style={{ marginBottom: 16 }}>
        <h3>Quick links</h3>
        <p style={{ display: "flex", flexWrap: "wrap", gap: 8, marginTop: 12 }}>
          <Link className="btn btn-primary" href="/developers/quickstart">
            Quick Start
          </Link>
          <Link className="btn" href="/developers/docs">
            API Docs
          </Link>
          <Link className="btn" href="/developers/explorer">
            API Explorer
          </Link>
          <Link className="btn" href="/developers/sdks">
            SDKs
          </Link>
          <Link className="btn" href="/api/v1/health">
            Status JSON
          </Link>
        </p>
      </div>
    </>
  );
}
