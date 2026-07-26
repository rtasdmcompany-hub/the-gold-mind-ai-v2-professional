# AI_ASSISTANT_ARCHITECTURE.md

**Phase:** 11 · Sprint 7  
**Isolation:** AI Assistant never accesses Core Trading Engine, never generates signals, never recommends buy/sell, never modifies trading parameters.

## Components

| Component | Module |
|-----------|--------|
| AI Gateway | `gateway.ts` |
| Conversation Engine | `conversation.ts` |
| Knowledge Base | `knowledge.ts` |
| Document Retrieval | `retrieval.ts` (semantic-lite) |
| Context / History | encrypted conversation store |
| Feedback | ratings + comments |
| Human Escalation | `escalation.ts` |

## Surfaces

- website
- customer_portal
- partner_portal
- admin_portal
- mobile
- support_center

## Hard rule

Trading prohibited: **true**
