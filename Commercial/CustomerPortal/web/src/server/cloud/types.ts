/**
 * Cloud platform types — Website Edition commercial service layer.
 * NEVER imports or controls Core Trading Engine.
 */

export type CloudRole =
  | "admin"
  | "customer"
  | "support"
  | "super_admin"
  | "commercial_manager"
  | "support_agent"
  | "finance_manager"
  | "qa_manager"
  | "auditor";

export type ApiVersion = "v1";

export type AuditAction =
  | "login"
  | "logout"
  | "login_failed"
  | "license_activation"
  | "payment_event"
  | "device_registration"
  | "profile_change"
  | "admin_action"
  | "download"
  | "update"
  | "support_action"
  | "api_request"
  | "rate_limited"
  | "health_check"
  | "beta_invite"
  | "beta_update"
  | "beta_cohort_cap"
  | "incident_open"
  | "incident_update"
  | "feedback_submit"
  | "feedback_triage"
  | "beta_enrollment_step"
  | "beta_accept"
  | "issue_create"
  | "issue_update"
  | "alert_fire"
  | "alert_update"
  | "alert_rule";

export type AuditResult = "success" | "failure" | "denied" | "error";

export interface AuditEntry {
  id: string;
  at: string;
  user: string;
  action: AuditAction;
  ip: string;
  result: AuditResult;
  detail?: string;
  resource?: string;
  meta?: Record<string, string>;
}

export interface StandardApiMeta {
  version: ApiVersion;
  requestId: string;
  timestamp: string;
}

export interface StandardApiSuccess<T> {
  ok: true;
  data: T;
  meta: StandardApiMeta;
}

export interface StandardApiError {
  ok: false;
  error: {
    code: string;
    message: string;
  };
  meta: StandardApiMeta;
}

export type HealthStatus = "healthy" | "degraded" | "unhealthy";

export interface ServiceHealth {
  id: string;
  name: string;
  status: HealthStatus;
  latencyMs: number;
  detail?: string;
}

export interface SystemHealthReport {
  status: HealthStatus;
  checkedAt: string;
  services: ServiceHealth[];
  metrics: {
    uptimeSec: number;
    auditEntries: number;
    // ✅ FIX: 'supabase' ko shamil kar liya gaya hai
    cacheBackend: "upstash" | "supabase" | "memory";
    rateLimitBackend: "upstash" | "supabase" | "memory";
  };
}