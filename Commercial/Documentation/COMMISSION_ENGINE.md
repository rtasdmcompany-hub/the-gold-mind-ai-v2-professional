# COMMISSION_ENGINE.md

**Config-driven** — update `PartnerProgramConfig` / store config; do not hardcode Core changes.

## Rules

- **rule_pct_standard** (percentage): value=1500 · active=true · approval=true — 15% of verified first sale payment
- **rule_fixed_trial** (fixed): value=500 · active=true · approval=true — USD 5.00 fixed on verified trial attribution
- **rule_recurring_monthly** (recurring): value=500 · active=true · approval=true — 5% residual up to 12 months on verified renewals
- **rule_one_time_lifetime** (one_time): value=2000 · active=true · approval=true — 20% one-time on lifetime plan
- **rule_bonus_launch** (bonus): value=1000 · active=false · approval=true — USD 10 bonus when campaign active — enable via config/campaign

## Approval workflow

1. verified_attribution
2. commission_created_pending_approval
3. finance_or_commercial_approve
4. payout_request
5. payout_paid

## Types supported

Fixed · Percentage · Recurring · One-Time · Bonus / Promotional (campaign-gated)

Min payout: 5000 cents.
