import { webhookCatalog } from "@/server/api-platform/webhooks";

export default function DevelopersWebhooksPage() {
  const cat = webhookCatalog();
  return (
    <>
      <h1 className="page-title">Webhook Guide</h1>
      <p className="page-sub">{cat.signing}</p>
      <h2 style={{ fontSize: 16 }}>Events</h2>
      <ul>
        {cat.events.map((e) => (
          <li key={e}>
            <code>{e}</code>
          </li>
        ))}
      </ul>
      <h2 style={{ fontSize: 16 }}>Retry policy</h2>
      <p>
        Max attempts: {cat.retryPolicy.maxAttempts}
        <br />
        Backoff (sec): {cat.retryPolicy.backoffSec.join(", ")}
      </p>
      <p>
        Register: <code>POST /api/v1/webhooks</code> with scope <code>webhooks:manage</code>
      </p>
    </>
  );
}
