/**
 * Mobile architecture catalog — Android, iOS, API, offline, push, versions.
 */
import path from "path";
import { commercialRoot } from "@/server/phase11/store";
import { readMobileStore } from "./store";
import { MOBILE_CORE_ISOLATION, MOBILE_TRADING_PROHIBITED } from "./types";
import { brand } from "@/lib/brand";

export function getMobileArchitecture() {
  const versions = readMobileStore().appVersions;
  return {
    product: `${brand.brandName} Mobile Companion`,
    purpose: "Customer management, licensing, notifications, business services",
    notATradingTerminal: true,
    tradingProhibited: MOBILE_TRADING_PROHIBITED,
    coreIsolation: MOBILE_CORE_ISOLATION,
    platforms: {
      android: {
        stack: "React Native (Expo) · Kotlin modules for biometrics/Keystore",
        minSdk: 26,
        push: "FCM",
        store: "Google Play (enterprise track)",
      },
      ios: {
        stack: "React Native (Expo) · Swift modules for Keychain/Face ID",
        minIos: "15.0",
        push: "APNs",
        store: "App Store (enterprise / public)",
      },
    },
    responsiveApiLayer: {
      basePath: "/api/mobile/*",
      versionHeader: "X-TGM-API-Version: v1",
      auth: "Bearer access token",
      gateway: "withApiGateway — rate limit · audit · TLS",
    },
    offlineCache: {
      strategy: "stale-while-revalidate for dashboard snapshot",
      encrypted: true,
      ttlDefaultSec: 3600,
      keys: ["dashboard", "licenses", "tickets", "kb"],
    },
    secureAuthentication: ["email", "google_oauth", "2fa", "biometric_unlock"],
    pushNotificationService: ["FCM", "APNs", "in-app inbox"],
    versionManagement: versions,
    companionRoot: path.join(commercialRoot(), "MobileCompanion"),
    approvedApisOnly: true,
  };
}
