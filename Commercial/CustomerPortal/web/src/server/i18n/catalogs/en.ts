/**
 * English master catalog — all user-facing keys live here (no hardcoded UI strings).
 * Other packs may omit keys and fall back to en.
 */
import type { TranslationCatalog } from "../types";

export const EN_CATALOG: TranslationCatalog = {
  // common
  "common.appName": "THE GOLD MIND PROFESSIONAL",
  "common.brand": "RTAS",
  "common.loading": "Loading…",
  "common.save": "Save",
  "common.cancel": "Cancel",
  "common.continue": "Continue",
  "common.back": "Back",
  "common.search": "Search",
  "common.language": "Language",
  "common.timezone": "Timezone",
  "common.currency": "Currency",
  "common.yes": "Yes",
  "common.no": "No",
  "common.items_one": "{count} item",
  "common.items_other": "{count} items",
  "common.coreIsolation": "Core Trading Engine is not connected to this application.",

  // website
  "website.hero.tagline": "Automated Trading Software",
  "website.hero.cta": "View pricing",
  "website.nav.home": "Home",
  "website.nav.pricing": "Pricing",
  "website.nav.docs": "Docs",
  "website.nav.contact": "Contact",
  "website.nav.register": "Register",
  "website.pricing.title": "Pricing",
  "website.contact.title": "Contact us",

  // portal
  "portal.nav.dashboard": "Dashboard",
  "portal.nav.licenses": "My Licenses",
  "portal.nav.downloads": "Downloads",
  "portal.nav.billing": "Billing",
  "portal.nav.support": "Support",
  "portal.nav.partner": "Partner Portal",
  "portal.dashboard.welcome": "Welcome to your customer portal",
  "portal.account.settings": "Account Settings",

  // admin
  "admin.nav.console": "Admin Console",
  "admin.nav.customers": "Customers",
  "admin.nav.localization": "Localization",
  "admin.ops.title": "Operations Hub",

  // partner
  "partner.dashboard.title": "Partner Dashboard",
  "partner.referral.code": "Referral Code",
  "partner.commissions": "Commissions",
  "partner.apply": "Apply to become a partner",

  // installer / updater
  "installer.welcome": "Welcome to THE GOLD MIND PROFESSIONAL Setup",
  "installer.next": "Next",
  "installer.finish": "Finish",
  "updater.checking": "Checking for updates…",
  "updater.available": "An update is available",
  "updater.uptodate": "You are up to date",

  // emails
  "emails.welcome.subject": "Welcome to THE GOLD MIND PROFESSIONAL",
  "emails.license.subject": "Your license key",
  "emails.renewal.subject": "Subscription renewal reminder",
  "emails.footer": "This message was sent by THE GOLD MIND commercial services.",

  // knowledge / support
  "knowledge.title": "Knowledge Base",
  "knowledge.search": "Search articles",
  "support.title": "Support Center",
  "support.newTicket": "New support request",
  "support.status.open": "Open",
  "support.status.closed": "Closed",

  // errors / notifications
  "errors.generic": "Something went wrong. Please try again.",
  "errors.unauthorized": "You are not authorized to perform this action.",
  "errors.notFound": "The requested resource was not found.",
  "errors.validation": "Please check the highlighted fields.",
  "notifications.saved": "Changes saved.",
  "notifications.sent": "Message sent.",

  // docs
  "docs.title": "Documentation",
  "docs.gettingStarted": "Getting started",

  // legal
  "legal.privacy.title": "Privacy Policy",
  "legal.terms.title": "Terms of Service",
  "legal.cookies.title": "Cookie Notice",
  "legal.refund.title": "Refund Policy",
  "legal.risk.title": "Risk Disclosure",
  "legal.cookies.banner": "We use cookies to operate the commercial portal and improve your experience.",
  "legal.accept": "Accept",

  // regional
  "regional.support.contact": "partners@rtas.group · support@rtas.group",
  "regional.legal.notice": "Trading involves risk. Past performance does not guarantee future results.",
  "regional.measurement.metric": "Metric",
  "regional.measurement.imperial": "Imperial",
};
