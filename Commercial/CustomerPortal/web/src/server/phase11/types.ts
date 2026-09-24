export interface RevenueTrendItem {
  month: string;
  cents: number;
  formatted: string;
}

export interface BusinessKpiDashboard {
  dailyActiveUsers: number;
  weeklyActiveUsers: number;
  monthlyActiveUsers: number;
  customerGrowth: { active: number; newToday: number; retentionPct: number };
  licenseGrowth: { active: number; activationsToday: number; activationRate: number };
  subscriptionGrowth: { active: number; total: number; renewals: number };
  renewalRate: number;
  cancellationRate: number;
  trialConversionRate: number;
  customerSatisfaction: number | null; // <-- FIX: Ab ye null bhi accept karega
  revenueTrend: RevenueTrendItem[];
  measurable: boolean;
  at: string;
}

export interface WorkflowAudit {
  id: string;
  label: string;
  status: "pass" | "fail" | "partial";
  auditable: boolean;
  evidence: string;
}

export interface CommercialOperationsAudit {
  workflows: WorkflowAudit[];
  score: number;
  licensesTotal: number;
  auditTrailSample: { action: string; at: string }[];
  everyWorkflowAuditable: boolean;
  at: string;
}

export interface HealthService {
  id: string;
  label: string;
  status: string;
  latencyMs: number;
  detail: string;
}

export interface OperationalHealthSnapshot {
  overall: string;
  services: HealthService[];
  score: number;
  isolation: string | { 
    coreTradingEngine: string; 
    monitoringFailureStopsTrading: boolean; 
    statement: string; 
  };
  at: string;
}

export interface CustomerSuccessDashboard {
  newCustomers: { count: number; emails: string[] };
  trialCustomers: { count: number };
  paidCustomers: { count: number };
  renewals: { count: number; sample: { id: string; email: string; at: string }[] };
  churnRisk: { count: number; customers: { email: string; healthScore: number; openTickets: number; licenseStatus: string }[] };
  supportHistory: { id: string; email: string; subject: string; status: string; priority: string; updatedAt: string }[];
  customerSatisfaction: number | null; // <-- FIX: Ye bhi null accept karega
  avgHealthScore: number;
  atRisk: number;
  totalTracked: number;
  traceable: boolean;
  at: string;
}

export interface GlobalOperationsCenter {
  activeCustomers: number;
  activeLicenses: number;
  newRegistrations: number;
  revenue: string;
  revenueCents: number;
  subscriptionStatus: {
    active: number;
    failedPayments: number;
    billingSubs: number;
  };
  websiteHealth: string;
  apiHealth: string;
  customerPortalStatus: string;
  systemHealth: string;
  supportQueue: {
    open: number;
    total: number;
  };
  securityAlerts: {
    firing: number;
    critical: number;
    resolved: number;
  };
  globalUptime: {
    seconds: number;
    percentProxy: number;
  };
  coreIsolation: string;
  coreShaMatch: boolean;
  coreSha: string;
  at: string;
}

export interface Phase11Sprint1Dashboard {
  businessOperationsScore: number;
  commercialOperationsScore: number;
  customerSuccessScore: number;
  operationalHealthScore: number;
  executiveReadinessScore: number;
  overallPhase11Progress: number;
  ops: GlobalOperationsCenter | undefined;
  kpis: BusinessKpiDashboard | undefined;
  commercial: CommercialOperationsAudit | undefined;
  health: OperationalHealthSnapshot | undefined;
  success: CustomerSuccessDashboard | undefined;
  reports: { title: string; path: string }[];
  scorecardRows: unknown[];
  coreMatches: boolean;
  coreSha: string;
  coreIsolation: string;
  runs: { id: string; kind: string; label: string; at: string }[];
  generatedAt: string;
}