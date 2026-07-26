export default function DevelopersQuickStartPage() {
  return (
    <>
      <h1 className="page-title">Quick Start</h1>
      <ol style={{ lineHeight: 1.7, maxWidth: 720 }}>
        <li>Create an API key from Admin → API Platform (or request one from support).</li>
        <li>
          Exchange the key for an access token:
          <pre className="mono" style={{ padding: 12, overflow: "auto" }}>
            {`POST /api/v1/oauth/token
{ "grant_type": "client_credentials", "api_key": "tgm_live_..." }`}
          </pre>
        </li>
        <li>
          Call a commercial endpoint:
          <pre className="mono" style={{ padding: 12, overflow: "auto" }}>
            {`GET /api/v1/profile
Authorization: Bearer tgm_atk_...`}
          </pre>
        </li>
        <li>Register webhooks for license and payment events.</li>
        <li>Never request trading, orders, or Core endpoints — they are not available.</li>
      </ol>
    </>
  );
}
