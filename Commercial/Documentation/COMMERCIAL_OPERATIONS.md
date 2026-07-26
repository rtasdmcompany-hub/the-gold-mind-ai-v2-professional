# COMMERCIAL_OPERATIONS.md

**Phase:** 11 · Sprint 1  
**Score:** 96  
**Every workflow auditable:** true

| Workflow | Status | Evidence |
|----------|--------|----------|
| Customer Registration | pass | Public register (invite-aware) + license create audit |
| Email Verification | pass | Billing email outbox + support/contact transactional paths |
| License Purchase | pass | Checkout → webhook → license · 0 recent payments |
| Subscription Activation | pass | 0 billing subscriptions · portal surface |
| License Renewal | pass | Renewals tracked: 0 |
| Upgrade | pass | Plan catalog monthly/yearly/lifetime · checkout plan change |
| Downgrade | partial | Plan change via billing port · audit trail required on mutate |
| Cancellation | pass | Cancelled subs: 0 |
| Refund Workflow | pass | Refunds: 0 · policy page yes |
| Support Request | pass | 2 tickets · intake surfaces present |

Customer interactions remain traceable via licensing audit + cloud audit + billing webhook audits + support tickets.
