# ROLE_PERMISSION_MATRIX.md

**Phase:** 9 · Sprint 7  
**Code:** `src/server/admin/roles.ts`  
**UI:** `/portal/admin/roles`

---

## Foundation roles

| Role | Env list |
|------|----------|
| Super Administrator | `PORTAL_SUPER_ADMIN_EMAILS` / `PORTAL_ADMIN_EMAILS` |
| Commercial Manager | `PORTAL_COMMERCIAL_MANAGER_EMAILS` |
| Support Agent | `PORTAL_SUPPORT_EMAILS` |
| Finance Manager | `PORTAL_FINANCE_EMAILS` |
| QA Manager | `PORTAL_QA_EMAILS` |
| Read-only Auditor | `PORTAL_AUDITOR_EMAILS` |

Legacy aliases: `admin` → super_admin · `support` → support_agent

---

## Permission highlights

| Permission | Super | Commercial | Support | Finance | QA | Auditor |
|------------|:-----:|:----------:|:-------:|:-------:|:--:|:-------:|
| dashboard | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| customers.write | ✓ | ✓ | — | — | — | — |
| licenses.write | ✓ | ✓ | — | — | — | — |
| billing.write | ✓ | — | — | ✓ | — | — |
| support.write | ✓ | — | ✓ | — | — | — |
| releases.write | ✓ | — | — | — | ✓ | — |
| bi.read | ✓ | ✓ | — | ✓ | ✓ | ✓ |
| audit.export | ✓ | — | — | ✓ | — | ✓ |
| security.manage | ✓ | — | — | — | — | — |
| roles.manage | ✓ | — | — | — | — | — |

Full matrix rendered live on `/portal/admin/roles`.

---

*End of ROLE_PERMISSION_MATRIX.md*
