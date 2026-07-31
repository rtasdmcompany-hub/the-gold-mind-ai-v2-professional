# PRODUCT_CONFIGURATION_REPORT.md

**Product:** THE GOLD MIND PROFESSIONAL  
**Date:** 2026-07-31  
**Goal:** One central product configuration drives packaging, licensing, plans, URLs, and feature flags.

---

## Verdict

**PASS — central product configuration is live.**

Canonical module: `Commercial/CustomerPortal/web/src/lib/product.ts`

All listed product fields resolve from `{ product }` (with env overrides). Brand identity remains in `src/lib/brand.ts`; product config owns commercial/packaging/behavior values.

---

## Fields in `product.ts`

| Field | Path | Default / notes |
|-------|------|-----------------|
| Application Name | `product.applicationName` | From brand full name / `NEXT_PUBLIC_PRODUCT_APPLICATION_NAME` |
| Product Edition | `product.edition` | `Professional` |
| Product Version | `product.version` | `1.0.0` |
| Build Number | `product.buildNumber` | `26211` |
| License Name | `product.licenseName` | `{brand.productName} License` |
| License Types | `product.licenseTypes` / `planOrder` | trial · monthly · yearly · lifetime |
| Trial Days | `product.trialDays` | `14` |
| Subscription Plans | `product.plans` | labels, cents, seats, durationDays |
| Payment Provider | `product.paymentProvider` | `paddle` |
| Support URL | `product.urls.support` | `{portal}/contact` |
| Documentation URL | `product.urls.documentation` | `{portal}/docs` |
| Update URL | `product.urls.update` | `{portal}/portal/downloads` |
| API Base URL | `product.urls.apiBase` | `{portal}/api` |
| Portal URL | `product.urls.portal` | brand website / app URL |
| MT5 Product Name | `product.mt5.productName` | `TheGoldMindAI_Professional` |
| Installer Name | `product.installer.name` | `Setup.exe` |
| Executable Name | `product.executableName` | `TGM-Professional-Launcher.exe` |
| Default Language | `product.defaultLanguage` | `en` |
| Default Currency | `product.defaultCurrency` | `USD` |
| Timezone | `product.timezone` | `UTC` |
| Feature Flags | `product.featureFlags.*` | paddle, trial, lifetime, auto-update, AI, mobile, partners, beta, market, Google OAuth, email |

Helpers: `productPlanCatalog()`, `productSeatsForType()`, `productTrialDays()`, `productGraceDays()`, `productDurationDays()`, `productPackageLabel()`, `isProductFeatureEnabled()`, `productExport()`.

---

## Modules wired

| Module | Uses |
|--------|------|
| `server/billing/util.ts` | `PLAN_CATALOG` ← `productPlanCatalog()`; currency; website edition label |
| `server/billing/config.ts` | Default payment provider ← `product.paymentProvider` |
| `server/billing/actions.ts` | Default plan / provider / currency |
| `server/billing/base-url.ts` | Portal URL fallback |
| `server/licensing/crypto.ts` | Grace days + seats |
| `server/licensing/license-service.ts` | Duration days + edition |
| `server/accounts/mailer.ts` | Package labels (trial days) |
| `server/releases/commercial-source.ts` | Version, build, zip name, portal URL, installer name |
| `server/releases/package-artifact.ts` | Executable name |
| `server/i18n/runtime.ts` | Default language / currency / timezone |
| `app/pricing/page.tsx` | `product.planOrder` |
| Portal / docs / license UI | `product.installer.name` instead of hardcoded Setup.exe |
| `lib/product-identity.ts` | Re-exports `product` |

---

## Environment overrides (selected)

```env
NEXT_PUBLIC_PRODUCT_VERSION=1.0.0
NEXT_PUBLIC_PRODUCT_BUILD_NUMBER=26211
NEXT_PUBLIC_PRODUCT_EDITION=Professional
NEXT_PUBLIC_PRODUCT_TRIAL_DAYS=14
NEXT_PUBLIC_PRODUCT_PAYMENT_PROVIDER=paddle
NEXT_PUBLIC_PRODUCT_PORTAL_URL=https://your-domain
NEXT_PUBLIC_PRODUCT_CURRENCY=USD
NEXT_PUBLIC_PRODUCT_DEFAULT_LANGUAGE=en
NEXT_PUBLIC_PRODUCT_TIMEZONE=UTC
NEXT_PUBLIC_PRODUCT_INSTALLER_NAME=Setup.exe
NEXT_PUBLIC_PRODUCT_EXECUTABLE_NAME=TGM-Professional-Launcher.exe
NEXT_PUBLIC_PRODUCT_MT5_NAME=TheGoldMindAI_Professional
PRODUCT_PLAN_MONTHLY_CENTS=9900
PRODUCT_PLAN_YEARLY_CENTS=89900
PRODUCT_PLAN_LIFETIME_CENTS=249900
LICENSE_GRACE_DAYS=7
PRODUCT_FF_AI_ASSISTANT=true
```

Full list: see comments in `src/lib/product.ts` and `.env.production.example`.

---

## Export for installer / mobile

```bash
cd Commercial/CustomerPortal/web
npx tsx scripts/export-brand.mjs
```

Writes:

- `product.generated.json`
- `brand.generated.json`
- `Commercial/Installer/Professional/inno/brand-defines.iss` (includes product version, build, exe, MT5 name, URLs, trial days, currency, payment provider)
- Installer EULA + MobileCompanion version

---

## Separation of concerns

| Module | Owns |
|--------|------|
| `brand.ts` | Customer-facing identity: names, emails, copyright, social |
| `product.ts` | Commercial product: edition, version, build, plans, URLs, MT5/installer, locale defaults, feature flags |

Changing plans, trial length, payment provider, or installer names requires editing **only** `product.ts` (or env) — then re-export before rebuilding the installer.

---

## Residual notes

| Item | Note |
|------|------|
| Release ZIP SHA-256 / byte size | Artifact fingerprints remain in `commercial-source.ts` (build output, not product policy) |
| Windows Inno `AppId` | Upgrade-continuity string; not product marketing config |
| Demo `@thegoldmind.local` seeds | Dev-only fixtures |

---

## Summary

`src/lib/product.ts` is the single product configuration for application name, edition, version, build, licenses, trial days, subscription plans, payment provider, product URLs, MT5/installer/executable names, locale defaults, and feature flags. Runtime modules and the installer export path read from this module only.
