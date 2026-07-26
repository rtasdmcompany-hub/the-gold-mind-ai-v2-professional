# FORECASTING_MODEL.md

**Phase:** 11 · Sprint 2  
**Kind:** FORECAST only  

## Disclaimer

All values below are FORECAST. They must never be presented as ACTUAL revenue or customer activity.

## Method

Ordinary least squares linear trend on ACTUAL monthly series (flat-hold when history < 2).

## Horizon

2026-08, 2026-09, 2026-10

## Confidence

| Series | Confidence | Method |
|--------|------------|--------|
| Revenue | low | flat-hold (insufficient history) |
| Subscriptions | low | flat-hold (insufficient history) |
| Customer growth | low | flat-hold (insufficient history) |
| Renewals | low | flat-hold (insufficient history) |
| Infrastructure | low | ordinary-least-squares linear trend |
| Support demand | low | ordinary-least-squares linear trend |

## Assumptions (revenue)

- Fewer than 2 historical points — forecast holds last known value
- NOT ACTUAL revenue or customers

## Forecast accuracy readiness

**Score:** 35  
Readiness to trust forecasts — improves with longer ACTUAL history
