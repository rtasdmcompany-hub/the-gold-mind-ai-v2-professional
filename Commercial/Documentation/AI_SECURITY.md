# AI_SECURITY.md

| Control | Detail |
|---------|--------|
| Authenticated access | Surface + role checks |
| RBAC | anonymous / customer / partner / admin / support |
| Conversation encryption | AES-256-GCM at rest |
| Audit logs | true |
| PII protection | true |
| Rate limiting | 40/min per bucket |
| Prompt injection mitigation | true |
| Prompt logging | Store redacted audit excerpts only — never raw secrets |
| Trading prohibition | true |

AI Assistant never accesses Core Trading Engine, never generates signals, never recommends buy/sell, never modifies trading parameters.
