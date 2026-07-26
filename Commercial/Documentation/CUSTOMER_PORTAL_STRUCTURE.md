# CUSTOMER_PORTAL_STRUCTURE.md

**Phase 8 · Sprint 3**  
**Product:** THE GOLD MIND PROFESSIONAL  
**Brand:** Premium Black · Luxury Gold · RTAS Group of Companies  
**Rule:** Portal is commercial ops — not a trading terminal

---

## 1. Portal IA (information architecture)

```
Customer Portal
├── Dashboard
├── My Licenses
├── Downloads
├── Subscription
├── Invoices
├── Payment History
├── Device Management
├── Profile
├── Support Tickets
├── Knowledge Base
├── Announcements
└── Version History
```

*(Downloads appears once in nav; content shared with Version History where useful.)*

---

## 2. Page definitions

### Dashboard
- Entitlement summary (Active / Grace / Expired)
- Next renewal date
- Device seats used / max
- Latest announcement
- Quick actions: Activate · Download · Manage devices · Contact Support

### My Licenses
- List all licenses (Trial / Monthly / Yearly / Lifetime)
- Status badges
- Activate / copy key (masked)
- Link to devices bound to each license

### Downloads
- Latest Professional package
- Checksum / authenticity notes
- OS compatibility notes
- Link to installation guide

### Subscription
- Current plan
- Auto-renew on/off (provider-supported)
- Upgrade / Downgrade CTAs
- Cancel flow entry

### Invoices
- PDF/HTML invoices
- Tax fields as required by payment provider / region

### Payment History
- Chronological payment events
- Failed payment visibility + retry guidance

### Device Management
See `DEVICE_MANAGEMENT.md`

### Profile
- Name, email, password/SSO
- Notification preferences
- Company (optional)
- Security: sessions / sign-out all

### Support Tickets
- Create ticket (category, severity)
- History / status
- Attach logs (customer-initiated)

### Knowledge Base
- Install · Activate · Broker/MT5 · FAQ
- Links to commercial docs

### Announcements
- Product news, maintenance windows, security notices

### Version History
- Released versions / changelogs (customer language)
- Distinguish shell updates vs “Core unchanged” notes when applicable

---

## 3. Auth & session

| Topic | Spec |
|-------|------|
| Sign-in | Email/password and/or portal SSO later |
| Session | Secure HTTP-only cookies / tokens |
| MFA | Recommended for enterprise seats (phaseable) |
| Roles | Customer User · (future) Org Admin |

---

## 4. What portal never does

- No chart trading  
- No order tickets  
- No remote MT5 command execution  
- No risk parameter push into live Core  

---

## 5. Visual standard

- Premium Black backgrounds  
- Luxury Gold accents  
- Official THE GOLD MIND / RTAS marks only  

---

*End of CUSTOMER_PORTAL_STRUCTURE.md*
