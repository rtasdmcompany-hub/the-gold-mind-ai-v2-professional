# API_SECURITY.md

| Control | Detail |
|---------|--------|
| OAuth 2.0 | client_credentials + refresh |
| API Keys | tgm_live_* hashed at rest |
| Token rotation | true |
| Request signing | HMAC-SHA256 timestamp.body |
| TLS | true |
| Rate limits | true |
| IP restrictions | optional per key |
| Audit | true |
| Monitoring | true |
| Abuse detection | true |

Public API never exposes trading execution, strategy, risk engine, order management, trading calculations, or internal Core services.
