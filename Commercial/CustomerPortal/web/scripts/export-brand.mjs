#!/usr/bin/env node
/**
 * Export central brand config for non-TS consumers (Inno Setup, docs, MobileCompanion).
 * Source of truth: src/lib/brand.ts (+ env overrides at runtime).
 *
 * Usage: node --import tsx scripts/export-brand.mjs
 *    or: npx tsx scripts/export-brand.mjs
 */
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";
import { brand, brandExport } from "../src/lib/brand.ts";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const webRoot = path.resolve(__dirname, "..");
const repoCommercial = path.resolve(webRoot, "../..");

const snapshot = brandExport();
const outJson = path.join(webRoot, "brand.generated.json");
fs.writeFileSync(outJson, JSON.stringify(snapshot, null, 2) + "\n", "utf8");

const iss = `; Auto-generated from src/lib/brand.ts — do not edit by hand.
; Regenerate: npx tsx scripts/export-brand.mjs

#define MyAppName "${brand.productName}"
#define MyAppVersion "${brand.version}"
#define MyAppPublisher "${brand.companyName}"
#define MyAppURL "${brand.website}"
#define MyAppSupportEmail "${brand.emails.support}"
#define MyAppBillingEmail "${brand.emails.billing}"
#define MyAppLicenseEmail "${brand.emails.license}"
#define MyAppCopyright "${brand.copyrightNotice}"
`;

const issPath = path.join(repoCommercial, "Installer/Professional/inno/brand-defines.iss");
fs.writeFileSync(issPath, iss, "utf8");

const eula = `END-USER LICENSE AGREEMENT (SUMMARY)
${brand.companyName} - ${brand.productName}

By installing you agree to the Terms published on the Customer Portal.
Trading involves risk of loss. Past performance is not indicative of future results.
The Core Trading Engine binary is licensed for authorized use only.
Support: ${brand.emails.support}
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
  expo.version = brand.version;
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
console.log(" -", outJson);
console.log(" -", issPath);
console.log(" - EULA.txt + MobileCompanion/app.json");
