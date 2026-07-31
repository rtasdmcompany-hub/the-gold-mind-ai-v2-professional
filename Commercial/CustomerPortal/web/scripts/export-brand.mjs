#!/usr/bin/env node
/**
 * Export central brand + product config for non-TS consumers
 * (Inno Setup, docs, MobileCompanion).
 *
 * Sources of truth:
 *   src/lib/brand.ts
 *   src/lib/product.ts
 *
 * Usage: npx tsx scripts/export-brand.mjs
 */
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";
import { brand, brandExport } from "../src/lib/brand.ts";
import { product, productExport } from "../src/lib/product.ts";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const webRoot = path.resolve(__dirname, "..");
const repoCommercial = path.resolve(webRoot, "../..");

const brandSnapshot = brandExport();
const productSnapshot = productExport();

fs.writeFileSync(
  path.join(webRoot, "brand.generated.json"),
  JSON.stringify(brandSnapshot, null, 2) + "\n",
  "utf8"
);
fs.writeFileSync(
  path.join(webRoot, "product.generated.json"),
  JSON.stringify(productSnapshot, null, 2) + "\n",
  "utf8"
);

const iss = `; Auto-generated from src/lib/brand.ts + src/lib/product.ts — do not edit by hand.
; Regenerate: npx tsx scripts/export-brand.mjs

#define MyAppName "${product.applicationName.includes(product.edition) ? brand.productName : brand.productName}"
#define MyAppVersion "${product.version}"
#define MyAppBuild "${product.buildNumber}"
#define MyAppPublisher "${brand.companyName}"
#define MyAppURL "${product.urls.portal}"
#define MyAppSupportURL "${product.urls.support}"
#define MyAppDocsURL "${product.urls.documentation}"
#define MyAppUpdateURL "${product.urls.update}"
#define MyAppApiBaseURL "${product.urls.apiBase}"
#define MyAppSupportEmail "${brand.emails.support}"
#define MyAppBillingEmail "${brand.emails.billing}"
#define MyAppLicenseEmail "${brand.emails.license}"
#define MyAppCopyright "${brand.copyrightNotice}"
#define MyAppExeName "${product.executableName}"
#define MyAppInstallerName "${product.installer.name}"
#define MyAppMt5Name "${product.mt5.productName}"
#define MyAppEdition "${product.edition}"
#define MyAppLicenseName "${product.licenseName}"
#define MyAppTrialDays "${product.trialDays}"
#define MyAppCurrency "${product.defaultCurrency}"
#define MyAppLanguage "${product.defaultLanguage}"
#define MyAppTimezone "${product.timezone}"
#define MyAppPaymentProvider "${product.paymentProvider}"
`;

const issPath = path.join(repoCommercial, "Installer/Professional/inno/brand-defines.iss");
fs.writeFileSync(issPath, iss, "utf8");

const eula = `END-USER LICENSE AGREEMENT (SUMMARY)
${brand.companyName} - ${brand.productName} (${product.edition})

By installing you agree to the Terms published on the Customer Portal.
Trading involves risk of loss. Past performance is not indicative of future results.
The Core Trading Engine binary is licensed for authorized use only.
Support: ${brand.emails.support} · ${product.urls.support}
Full legal text: Portal -> Terms / EULA / Risk Disclosure.
`;
fs.writeFileSync(
  path.join(repoCommercial, "Installer/Professional/inno/payload/EULA.txt"),
  eula,
  "utf8"
);

const mobilePath = path.join(repoCommercial, "MobileCompanion/app.json");
if (fs.existsSync(mobilePath)) {
  const app = JSON.parse(fs.readFileSync(mobilePath, "utf8"));
  const expo = app.expo || app;
  expo.name = brand.productName;
  expo.slug = brand.productId;
  expo.version = product.version;
  if (!expo.ios) expo.ios = {};
  if (!expo.android) expo.android = {};
  expo.ios.bundleIdentifier = brand.mobile.bundleId;
  expo.android.package = brand.mobile.androidPackage;
  if (app.expo) {
    app.expo = expo;
    delete app.name;
    delete app.slug;
    delete app.version;
    delete app.ios;
    delete app.android;
  }
  fs.writeFileSync(mobilePath, JSON.stringify(app, null, 2) + "\n", "utf8");
}

console.log("Exported:");
console.log(" - brand.generated.json");
console.log(" - product.generated.json");
console.log(" -", issPath);
console.log(" - EULA.txt + MobileCompanion/app.json");
