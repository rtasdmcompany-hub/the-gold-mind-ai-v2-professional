"use client";

import { useState } from "react";

const PATHS = [
  "/api/v1/health",
  "/api/v1/profile",
  "/api/v1/licenses",
  "/api/v1/subscriptions",
  "/api/v1/downloads",
];

export default function DevelopersExplorerPage() {
  const [path, setPath] = useState(PATHS[0]);
  const [token, setToken] = useState("");
  const [out, setOut] = useState("");
  const [busy, setBusy] = useState(false);

  async function run() {
    setBusy(true);
    try {
      const res = await fetch(path, {
        headers: token ? { Authorization: `Bearer ${token}` } : {},
      });
      const text = await res.text();
      setOut(`${res.status}\n${text}`);
    } catch (e) {
      setOut(e instanceof Error ? e.message : "ERROR");
    } finally {
      setBusy(false);
    }
  }

  return (
    <>
      <h1 className="page-title">API Explorer</h1>
      <p className="page-sub">Try commercial endpoints (health is public; others need a key/token)</p>
      <div className="card stack" style={{ maxWidth: 640 }}>
        <div className="field">
          <label htmlFor="path">Path</label>
          <select id="path" value={path} onChange={(e) => setPath(e.target.value)}>
            {PATHS.map((p) => (
              <option key={p} value={p}>
                {p}
              </option>
            ))}
          </select>
        </div>
        <div className="field">
          <label htmlFor="token">Bearer token / API key</label>
          <input
            id="token"
            value={token}
            onChange={(e) => setToken(e.target.value)}
            placeholder="tgm_live_... or tgm_atk_..."
          />
        </div>
        <button type="button" className="btn btn-primary" disabled={busy} onClick={run}>
          Send request
        </button>
        <pre className="mono" style={{ whiteSpace: "pre-wrap", maxHeight: 320, overflow: "auto" }}>
          {out || "Response will appear here"}
        </pre>
      </div>
    </>
  );
}
