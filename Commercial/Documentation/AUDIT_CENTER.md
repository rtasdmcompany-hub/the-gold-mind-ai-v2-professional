# AUDIT_CENTER.md

**Phase:** 9 · Sprint 7  
**Route:** `/portal/admin/audit`  
**Store:** cloud audit (AES-256-GCM)

---

## Tracked categories

Login Events · License Events · Payment Events · Admin Actions · Support Actions · Downloads · Updates · Customer Changes (profile/support)

## Filtering

- Action dropdown  
- User email  

## Export

Permission `admin.audit.export` → CSV textarea export (audited when prepared).

Every entry includes: Timestamp · User · Action · IP · Result.

---

*End of AUDIT_CENTER.md*
