# DATABASE_SECURITY.md

**Phase:** 9 · Sprint 6  
**Module:** `server/cloud/database.ts`  
**Engine (current):** Encrypted file stores (AES-256-GCM) under `.data/*`

---

## Controls

| Control | Implementation |
|---------|----------------|
| Connection pooling | Logical `storePool` (`STORE_POOL_SIZE`) |
| Encrypted secrets | Env secrets · never committed |
| Secure env vars | `.env.local` · example without values |
| Backup strategy | Daily · 30d retention · targets listed |
| Migration policy | Expand-contract · backup required · TE freeze |
| Audit tables | Central `.data/audit/audit.enc` |
| Soft delete policy | `softDelete` / `activeOnly` helpers |

---

## Stores

| Store | Path | Encryption |
|-------|------|------------|
| Licensing | `.data/licensing/` | AES-256-GCM |
| Billing | `.data/billing/` | AES-256-GCM |
| Audit | `.data/audit/` | AES-256-GCM |
| Releases | `.data/releases/` | JSON + artifact ZIPs |

---

## Secret rotation

1. Issue new secret  
2. Dual-read `*_PREVIOUS` window (≤48h)  
3. Re-encrypt stores  
4. Drop previous after verification  

Never rotate by editing Core Trading Engine artifacts.

---

## Future SQL

Postgres/SQL can replace file stores behind the same policy helpers without coupling to Trading Engine.

---

*End of DATABASE_SECURITY.md*
