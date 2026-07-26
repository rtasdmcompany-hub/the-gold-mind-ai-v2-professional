# SUPPORT_OPERATIONS.md

**Phase 8 · Sprint 8**  
**Goal:** Predictable, professional ticket handling  
**Rule:** Agents never remotely trade or request broker passwords

---

## 1. Workflow catalog

### Bug Report
```
Intake → Repro steps + version + Diagnostics pack
  → Severity triage → Engineering queue
  → Fix / workaround → Verify → Resolve → KB if recurring
```

### Feature Request
```
Intake → Duplicate check → Feedback System (voting)
  → Product review → Roadmap / decline with reason
```

### License Issue
```
Verify identity → Check entitlement / devices / payments
  → Correct seat / reissue / portal action → Confirm activation
```

### Payment Issue
```
Never take card data in ticket → Direct to provider portal
  → Reconcile webhook / invoice → Restore entitlement if paid
```

### Technical Support
```
KB first → Guided checks (Health / Broker / Config)
  → Diagnostics pack → Escalate if Critical
```

### General Inquiry
```
Answer from FAQ/KB → Close or convert to correct category
```

### Account Recovery
```
Identity verification → Password reset / email change policy
  → Session revoke → Security log
```

### Escalation Workflow
```
L1 Support → L2 Technical → L3 Engineering / Owner (P1)
  → Status updates to customer on each hop
```

---

## 2. Priority matrix

| Priority | Definition | Examples |
|----------|------------|----------|
| P1 Critical | Cannot activate / run; data-loss risk; security | License hard-fail; updater integrity fail; portal outage |
| P2 High | Major feature broken; workaround poor | Dashboard crash loop; reports export fail |
| P3 Normal | Standard how-to / moderate bug | Widget question; filter issue |
| P4 Low | Cosmetic / nice-to-have | Label tweak; feature idea |

---

## 3. Expected response levels (SLA guidance)

| Priority | First response target | Update cadence |
|----------|----------------------|----------------|
| P1 | ≤ 4 business hours | Daily until mitigated |
| P2 | ≤ 1 business day | Every 2 business days |
| P3 | ≤ 2 business days | As needed |
| P4 | ≤ 3 business days | On resolution / batch |

Exact SLAs are commercial policy — architecture supports configuration.

Business hours published on Support Dashboard · Live Status.

---

## 4. Ticket fields (minimum)

- Category · Priority · Edition · Version · Demo/Live  
- Description · Steps · Attachments (diagnostics)  
- Correlation / error codes if known  

---

## 5. Agent rules

| Do | Don’t |
|----|-------|
| Use calm premium tone | Promise profits |
| Ask for diagnostics pack | Ask for broker password |
| Link KB | Blame customer |
| Confirm Core freeze when relevant | “We’ll patch your risk live” |

---

*End of SUPPORT_OPERATIONS.md*
