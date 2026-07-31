/**
 * Lightweight AI Command Center preview — UI polish only.
 * Static agent statuses; no APIs, no Trading Engine coupling.
 */
const AGENTS = [
  { name: "Market Agent", status: "Active", tone: "green" as const },
  { name: "Risk Agent", status: "Active", tone: "green" as const },
  { name: "Strategy Agent", status: "Monitoring", tone: "yellow" as const },
  { name: "Execution Agent", status: "Ready", tone: "green" as const },
];

export function AiCommandCenterPreview() {
  return (
    <section className="card ai-cc-preview" aria-label="AI Command Center preview">
      <div className="ai-cc-preview-head">
        <h3>AI Command Center</h3>
        <span className="ai-cc-preview-badge">Preview</span>
      </div>
      <ul className="ai-cc-list">
        {AGENTS.map((agent) => (
          <li key={agent.name} className="ai-cc-row">
            <span className={`ai-cc-dot ai-cc-dot--${agent.tone}`} aria-hidden="true" />
            <span className="ai-cc-name">{agent.name}</span>
            <span className={`ai-cc-status ai-cc-status--${agent.tone}`}>{agent.status}</span>
          </li>
        ))}
      </ul>
      <p className="meta ai-cc-preview-meta">Preview · V2.0 full center coming later</p>
    </section>
  );
}
