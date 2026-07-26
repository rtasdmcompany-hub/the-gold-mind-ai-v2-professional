# API_ARCHITECTURE.md

**Phase:** 11 · Sprint 8  
**Version:** v1  
**Isolation:** Public API never exposes trading execution, strategy, risk engine, order management, trading calculations, or internal Core services.

## Gateway

- Central public gateway: `withPublicApi` for `/api/v1/*`
- Versioning via path + `X-TGM-API-Version`
- Authentication: API keys · OAuth bearer
- Authorization: scope checks
- Rate limiting · usage analytics · request logging · error tracking · health monitoring

## Forbidden

- `trading`
- `orders`
- `signals`
- `strategy`
- `risk-engine`
- `magic-number`
- `recovery`
- `core-engine`
- `execute-trade`
