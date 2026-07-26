# LICENSE_SECURITY_MODEL.md

**Phase:** 9 · Sprint 3  
**Applies to:** Licensing Engine inside Customer Portal commercial stack

---

## Controls

| Control | Implementation |
|---------|----------------|
| Encrypted license storage | AES-256-GCM file store (`.data/licensing/store.enc`) |
| Secure tokens | Base64url validation tokens (license·device·email·exp·sig) |
| Session validation | NextAuth session required for all license APIs |
| Device fingerprint | SHA-256 hash; compare on validate |
| Tamper detection | Per-license HMAC integrity MAC; audit `tamper.detected` |
| Audit logging | Append-only ring (cap 2000) |
| Secret exposure | Full keys never in list APIs; one-time return on create only |

## Secrets

`LICENSE_STORE_SECRET` (preferred) or fallback `NEXTAUTH_SECRET`.

## Client rule

Never ship `keyHash`, raw fingerprints, or plaintext keys in list/detail DTOs.

---

*End of LICENSE_SECURITY_MODEL.md*
