/**
 * LTS policy + 12/24/36 month business growth roadmap.
 */
export function getLtsPolicy() {
  return {
    versioning: {
      commercial: "SemVer MAJOR.MINOR.PATCH for portal/API; language packs independent",
      core: "Frozen certified tag — no commercial release may alter Core SHA",
    },
    securityPatch: {
      critical: "≤ 7 calendar days",
      high: "≤ 30 calendar days",
      medium: "Next monthly train",
      low: "Backlog / quarterly",
    },
    releaseCadence: {
      commercialMonthly: "Feature/fix monthly",
      ltsQuarterly: "LTS train every quarter",
      hotfixes: "As required under security policy",
    },
    maintenanceWindows: {
      primary: "Sunday 02:00–04:00 UTC",
      notice: "≥ 72 hours for planned; best-effort for emergency",
    },
    endOfLife: {
      supportWindow: "Current + previous minor (N and N-1)",
      noticePeriodMonths: 12,
    },
    supportMatrix: [
      "Customer Portal",
      "Email / tickets",
      "AI Assistant (commercial only)",
      "Mobile Companion",
      "Partner Portal",
      "Public API v1",
    ],
    compatibility: {
      api: "v1 stable; breaking changes require v2 with deprecation window",
      mt5: "Certified Core tag only; no engine changes via commercial releases",
      browsers: "Latest 2 Chrome/Edge/Firefox/Safari",
    },
  };
}

export function getBusinessGrowthRoadmap() {
  return {
    months12: {
      customerGrowth: "Grow active licensed customers; deepen portal adoption",
      revenueGoals: "Stabilize recurring revenue; improve renewal rate",
      regionalExpansion: "Prioritize PK · AE · EU · US support coverage",
      enterpriseSales: "Convert CRM pipeline; seat expansions",
      partnerExpansion: "Scale verified affiliates; tighten attribution",
      productEvolution: "Mobile polish · API partner integrations · AI KB growth",
      technologyInvestments: "HA dual-region hardening · observability maturity",
    },
    months24: {
      customerGrowth: "Expand mid-market enterprise accounts",
      revenueGoals: "Diversify regions; increase ACV via seats",
      regionalExpansion: "APAC + additional EU markets",
      enterpriseSales: "Dedicated enterprise motion · PO billing scale",
      partnerExpansion: "Reseller / white-label pilots (commercial only)",
      productEvolution: "API ecosystem · webhook marketplace · LTS trains",
      technologyInvestments: "Cell-based tenancy prep · analytics warehouse",
    },
    months36: {
      customerGrowth: "Global brand presence with measured regional cells",
      revenueGoals: "Predictable multi-region ARR",
      regionalExpansion: "Full regional routing + localized support SLAs",
      enterpriseSales: "Strategic accounts program",
      partnerExpansion: "Mature partner tiers worldwide",
      productEvolution: "Phase 12 continuous innovation backlog execution",
      technologyInvestments: "1M-user architecture elements as demand warrants",
    },
  };
}
