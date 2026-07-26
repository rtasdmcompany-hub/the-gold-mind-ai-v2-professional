/**
 * Task 1 — Edition verification matrix.
 */
import fs from "fs";
import path from "path";
import { createHash } from "crypto";
import {
  commercialRoot,
  workspaceRoot,
  CORE_CERT_SHA,
  CORE_REL_PATH,
  saveMarketRun,
} from "./store";

export interface EditionCheck {
  id: string;
  label: string;
  status: "pass" | "partial" | "fail";
  detail: string;
}

function sha256File(filePath: string): string | null {
  if (!fs.existsSync(filePath)) return null;
  return createHash("sha256").update(fs.readFileSync(filePath)).digest("hex");
}

export async function runEditionVerification(): Promise<{
  checks: EditionCheck[];
  coreSha: string | null;
  coreMatchesCert: boolean;
  score: number;
  at: string;
}> {
  const root = workspaceRoot();
  const commercial = commercialRoot();
  const corePath = path.join(root, CORE_REL_PATH);
  const coreSha = sha256File(corePath);
  const coreMatchesCert = coreSha === CORE_CERT_SHA;

  const checks: EditionCheck[] = [
    {
      id: "professional_website",
      label: "Professional Website Edition",
      status: fs.existsSync(path.join(commercial, "ProfessionalEdition")) ? "pass" : "fail",
      detail: "GM_EDITION_PROFESSIONAL · website installer · portal · PaymentPort",
    },
    {
      id: "mql5_market",
      label: "MQL5 Market Edition",
      status: fs.existsSync(path.join(commercial, "MarketEdition", "Package")) ? "pass" : "fail",
      detail: "GM_EDITION_MARKET · Market listing pack · no Website licensing in package",
    },
    {
      id: "shared_core",
      label: "Shared Certified Core",
      status: coreMatchesCert ? "pass" : coreSha ? "fail" : "fail",
      detail: coreSha
        ? `SHA-256 ${coreSha}${coreMatchesCert ? " · matches RC2 cert" : " · MISMATCH vs cert"}`
        : `Missing ${CORE_REL_PATH}`,
    },
    {
      id: "independent_branding",
      label: "Independent Branding",
      status: fs.existsSync(path.join(commercial, "Assets", "Market")) ? "pass" : "partial",
      detail: "Market Assets under Commercial/Assets/Market · Professional uses Website brand path",
    },
    {
      id: "independent_packaging",
      label: "Independent Packaging",
      status: fs.existsSync(path.join(commercial, "MarketEdition", "Package", "MANIFEST.json"))
        ? "pass"
        : "partial",
      detail: "Market Package/ separate from Installer/Professional",
    },
    {
      id: "independent_licensing",
      label: "Independent Licensing",
      status: fs.existsSync(path.join(commercial, "Licensing", "Market")) ? "pass" : "partial",
      detail: "Market = MQL5 Market license API only · Website license server excluded from Market package",
    },
    {
      id: "separation_matrix",
      label: "Edition Separation Matrix",
      status: fs.existsSync(path.join(commercial, "Documentation", "PRODUCT_EDITIONS.md"))
        ? "pass"
        : "fail",
      detail: "PRODUCT_EDITIONS.md · EDITION_COMPARISON.md",
    },
  ];

  const score = Math.round(
    (checks.reduce((a, c) => a + (c.status === "pass" ? 1 : c.status === "partial" ? 0.55 : 0), 0) /
      checks.length) *
      100
  );

  const payload = { checks, coreSha, coreMatchesCert, score, at: new Date().toISOString() };
  saveMarketRun("edition", "Sprint 7 edition verification", payload);
  return payload;
}
