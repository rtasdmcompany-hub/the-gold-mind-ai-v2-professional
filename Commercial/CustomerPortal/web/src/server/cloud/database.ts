/**
 * Database / persistence security policy helpers.
 * Current engine: encrypted file stores (AES-256-GCM) with logical pooling & soft-delete conventions.
 * Ready for future Postgres/SQL behind the same policy surface.
 */

export interface SoftDeleteRecord {
  deletedAt?: string | null;
  deletedBy?: string | null;
}

export function softDelete<T extends SoftDeleteRecord>(row: T, actor: string): T {
  return { ...row, deletedAt: new Date().toISOString(), deletedBy: actor };
}

export function isSoftDeleted(row: SoftDeleteRecord): boolean {
  return !!row.deletedAt;
}

export function activeOnly<T extends SoftDeleteRecord>(rows: T[]): T[] {
  return rows.filter((r) => !isSoftDeleted(r));
}

/** Logical connection pool for file-backed stores (limits concurrent mutate ops). */
class FileStorePool {
  private active = 0;
  constructor(private readonly max = Number(process.env.STORE_POOL_SIZE || 8)) {}

  async run<T>(fn: () => Promise<T> | T): Promise<T> {
    while (this.active >= this.max) {
      await new Promise((r) => setTimeout(r, 5));
    }
    this.active += 1;
    try {
      return await fn();
    } finally {
      this.active -= 1;
    }
  }

  stats() {
    return { active: this.active, max: this.max };
  }
}

export const storePool = new FileStorePool();

export interface BackupPolicy {
  frequency: string;
  retentionDays: number;
  targets: string[];
  encryption: "AES-256-GCM";
}

export function getBackupPolicy(): BackupPolicy {
  return {
    frequency: process.env.DB_BACKUP_FREQUENCY || "daily",
    retentionDays: Number(process.env.DB_BACKUP_RETENTION_DAYS || 30),
    targets: [".data/licensing", ".data/billing", ".data/releases", ".data/audit"],
    encryption: "AES-256-GCM",
  };
}

export interface MigrationPolicy {
  strategy: "expand-contract";
  requireBackupBeforeMigrate: true;
  freezeTradingEngine: true;
  note: string;
}

export function getMigrationPolicy(): MigrationPolicy {
  return {
    strategy: "expand-contract",
    requireBackupBeforeMigrate: true,
    freezeTradingEngine: true,
    note: "Commercial schema migrations never alter Core Trading Engine binaries or MQL5 Market packages.",
  };
}

export function listRequiredSecrets(): string[] {
  return [
    "NEXTAUTH_SECRET",
    "LICENSE_STORE_SECRET",
    "BILLING_STORE_SECRET",
    "AUDIT_STORE_SECRET",
    "UPDATE_REPORT_SECRET",
  ];
}

/**
 * Secret rotation strategy (operational):
 * 1. Generate new secret offline
 * 2. Dual-read old+new during window (env *_PREVIOUS)
 * 3. Re-encrypt stores with new key
 * 4. Drop previous after verification
 */
export function getSecretRotationStrategy() {
  return {
    dualReadEnvSuffix: "_PREVIOUS",
    maxOverlapHours: 48,
    stores: ["licensing", "billing", "audit"],
    neverCommitSecrets: true,
  };
}
