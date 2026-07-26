/**
 * Release / Update delivery — Website Professional only.
 * Independent of Core Trading Engine execution.
 */

export type ReleaseChannel = "stable" | "rc" | "development";

export type ReleaseStatus = "draft" | "published" | "yanked" | "superseded";

export interface ReleasePackage {
  id: string;
  product: "THE GOLD MIND PROFESSIONAL";
  version: string;
  buildNumber: string;
  channel: ReleaseChannel;
  status: ReleaseStatus;
  releasedAt: string;
  packageFile: string;
  packageUrl: string;
  packageSizeBytes: number;
  sha256: string;
  signatureRequired: boolean;
  signatureSubject: string;
  signatureStatus: "valid" | "pending_code_sign" | "none";
  releaseNotes: string;
  compatibility: {
    os: string[];
    mt5: string;
    coreTag: string;
    coreFrozen: boolean;
  };
  downloadCount: number;
  updateSuccessCount: number;
  updateFailCount: number;
  rollbackEvents: number;
}

export interface ReleaseStoreData {
  version: 1;
  packages: ReleasePackage[];
  updateEvents: Array<{
    id: string;
    at: string;
    email?: string;
    fromVersion: string;
    toVersion: string;
    channel: ReleaseChannel;
    result: "success" | "fail" | "rollback" | "check";
    detail: string;
  }>;
  downloadEvents: Array<{
    id: string;
    at: string;
    email?: string;
    packageId: string;
    version: string;
    ipMasked: string;
  }>;
}

export interface ClientVersionReport {
  installedVersion: string;
  channel: ReleaseChannel;
  email?: string;
}
