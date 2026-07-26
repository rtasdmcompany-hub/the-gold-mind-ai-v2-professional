/**
 * Core SHA gate for every Phase 12 run.
 */
import path from "path";
import { CORE_CERT_SHA, sha256File, workspaceRoot } from "./store";
import { PHASE12_CORE_ISOLATION } from "./types";

export function verifyCoreSha(): { matches: boolean; actual: string | null; expected: string; isolation: string } {
  const corePath = path.join(workspaceRoot(), "Experts", "TheGoldMindAI_Professional.mq5");
  const actual = sha256File(corePath);
  return {
    matches: actual === CORE_CERT_SHA,
    actual,
    expected: CORE_CERT_SHA,
    isolation: PHASE12_CORE_ISOLATION,
  };
}
