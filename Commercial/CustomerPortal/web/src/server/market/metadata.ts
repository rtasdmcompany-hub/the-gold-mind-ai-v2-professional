/**
 * Task 5 — Store metadata pack.
 */
import fs from "fs";
import path from "path";
import { commercialRoot, CORE_CERT_SHA, saveMarketRun } from "./store";

export interface StoreMetadata {
  productName: string;
  shortDescription: string;
  longDescriptionPath: string;
  version: string;
  releaseNotesPath: string;
  keywords: string[];
  category: string;
  tags: string[];
  languageSupport: string[];
  minimumMt5Build: number;
  compatibility: Array<{ item: string; status: string }>;
}

export async function runStoreMetadata(): Promise<{
  metadata: StoreMetadata;
  score: number;
  at: string;
}> {
  const listing = path.join(commercialRoot(), "MarketEdition", "Listing");
  const pkg = path.join(commercialRoot(), "MarketEdition", "Package", "MANIFEST.json");
  let version = "2.0.0";
  if (fs.existsSync(pkg)) {
    try {
      const m = JSON.parse(fs.readFileSync(pkg, "utf8")) as { version?: string };
      if (m.version) version = m.version;
    } catch {
      /* ignore */
    }
  }

  const metadata: StoreMetadata = {
    productName: "THE GOLD MIND MARKET",
    shortDescription:
      "Systematic MetaTrader 5 Expert Advisor with certified Core engine. Market-compliant activation. Trading involves risk of loss.",
    longDescriptionPath: "MarketEdition/Listing/PRODUCT_DESCRIPTION.md",
    version,
    releaseNotesPath: "MarketEdition/Listing/CHANGELOG.md",
    keywords: [
      "expert advisor",
      "mt5",
      "systematic",
      "risk management",
      "goldmind",
      "rtas",
    ],
    category: "Expert Advisors · Others",
    tags: ["EA", "MT5", "Systematic", "Risk-aware", "Market"],
    languageSupport: ["English"],
    minimumMt5Build: 3800,
    compatibility: [
      { item: "MetaTrader 5 (hedging & netting per broker)", status: "supported" },
      { item: "Windows MT5 terminal", status: "supported" },
      { item: "Strategy Tester", status: "supported" },
      { item: "Website Customer Portal", status: "excluded_from_market_package" },
      { item: "External PSP checkout", status: "excluded_from_market_package" },
      { item: `Core SHA-256 ${CORE_CERT_SHA.slice(0, 16)}…`, status: "required_match" },
    ],
  };

  const score =
    fs.existsSync(path.join(listing, "PRODUCT_DESCRIPTION.md")) &&
    fs.existsSync(path.join(listing, "CHANGELOG.md"))
      ? 92
      : 60;

  const payload = { metadata, score, at: new Date().toISOString() };
  saveMarketRun("metadata", "Sprint 7 store metadata", payload);

  // Persist machine-readable metadata for package
  const outDir = path.join(commercialRoot(), "MarketEdition", "Package");
  if (!fs.existsSync(outDir)) fs.mkdirSync(outDir, { recursive: true });
  fs.writeFileSync(path.join(outDir, "STORE_METADATA.json"), JSON.stringify(metadata, null, 2), "utf8");

  return payload;
}
