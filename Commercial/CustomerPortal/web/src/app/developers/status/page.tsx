import { platformHealth } from "@/server/api-platform/usage";

export default function DevelopersStatusPage() {
  const health = platformHealth();
  return (
    <>
      <h1 className="page-title">API Status</h1>
      <div className="grid grid-3">
        <div className="card">
          <h3>Status</h3>
          <div className="value">{health.status}</div>
        </div>
        <div className="card">
          <h3>Version</h3>
          <div className="value">{health.version}</div>
        </div>
        <div className="card">
          <h3>Trading exposed</h3>
          <div className="value">{health.tradingExposed ? "YES" : "NO"}</div>
        </div>
        <div className="card">
          <h3>Active keys</h3>
          <div className="value">{health.keysActive}</div>
        </div>
        <div className="card">
          <h3>Active webhooks</h3>
          <div className="value">{health.webhooksActive}</div>
        </div>
        <div className="card">
          <h3>Usage events</h3>
          <div className="value">{health.usageEvents}</div>
        </div>
      </div>
      <p className="meta" style={{ marginTop: 16 }}>
        {health.coreIsolation}
      </p>
    </>
  );
}
