# EDITION_SEPARATION_MATRIX.md

**Phase:** 10 · Sprint 7  

| Dimension | Professional Website | MQL5 Market |
|-----------|----------------------|-------------|
| Product name | THE GOLD MIND PROFESSIONAL | THE GOLD MIND MARKET |
| Code | GM_EDITION_PROFESSIONAL | GM_EDITION_MARKET |
| Shared Core | YES (same SHA) | YES (same SHA) |
| Branding assets | Website / Professional | `Assets/Market/*` |
| Packaging | Installer/Professional + Portal releases | MarketEdition/Package + MQL5 upload |
| Licensing | Portal license · devices · subscription | MQL5 Market license only |
| Payments | PaymentPort (Paddle/PayPal/sandbox) | **None** (Market checkout) |
| Updates | Portal / Deployment channel | Market updates |
| Support | Enterprise portal support | Market comments + Market support policy |
| Trading behaviour | Core frozen | Core frozen (identical) |

**Hard rule:** Commercial packaging never changes Core trading behaviour.
