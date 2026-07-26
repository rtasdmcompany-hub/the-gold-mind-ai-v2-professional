export default function DevelopersAuthPage() {
  return (
    <>
      <h1 className="page-title">Authentication Guide</h1>
      <ul style={{ lineHeight: 1.8, maxWidth: 720 }}>
        <li>
          <strong>API Keys</strong> — header <code>Authorization: Bearer tgm_live_...</code> or{" "}
          <code>X-API-Key</code>
        </li>
        <li>
          <strong>OAuth 2.0</strong> — <code>POST /api/v1/oauth/token</code> with{" "}
          <code>grant_type=client_credentials</code>
        </li>
        <li>
          <strong>Refresh</strong> — <code>grant_type=refresh_token</code>
        </li>
        <li>
          <strong>Rotation</strong> — rotate keys via admin suite; old key revoked
        </li>
        <li>
          <strong>Scopes</strong> — each endpoint requires a commercial scope
        </li>
        <li>
          <strong>Optional IP allowlist</strong> — per API key
        </li>
      </ul>
    </>
  );
}
