# OWASP_REVIEW.md

**Phase:** 10 · Sprint 6  
**UI:** `/portal/admin/owasp`  
**Score:** see suite (typically mid–high 80s)

---

| ID | Category | Risk | Mitigation | Verification |
|----|----------|------|------------|--------------|
| A01 | Broken Access Control | Admin API escalation | RBAC · gateway · prod bypass off | pass |
| A02 | Cryptographic Failures | Weak store crypto | AES-256-GCM · HMAC · env secrets | pass / partial if secrets thin |
| A03 | Injection | Malicious API input | No raw SQL · validateFields · encodeOutput | pass |
| A04 | Insecure Design | Demo auth / public downloads | Production gates | pass |
| A05 | Security Misconfiguration | Headers / CORS / defaults | security-headers · HSTS · allowlist | pass |
| A06 | Vulnerable Components | Dependency CVEs | Pin Next/Auth · npm audit in release | partial |
| A07 | Auth Failures | Brute force / MFA | Lockout · idle · 2FA architecture pending enrollment | partial |
| A08 | Integrity Failures | Tampered store / webhooks | MAC · HMAC · package SHA-256 | pass |
| A09 | Logging Failures | Missing audit | writeAudit · admin security events | pass |
| A10 | SSRF | User-driven server fetch | Not applicable to portal APIs | n/a |
