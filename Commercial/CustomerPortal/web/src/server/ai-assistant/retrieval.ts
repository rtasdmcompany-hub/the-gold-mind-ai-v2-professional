/**
 * Semantic-lite document retrieval (token overlap + TF weighting).
 */
import { ensureKnowledgeIndexed, tokenize } from "./knowledge";
import type { RetrievalHit } from "./types";

function tf(tokens: string[]): Map<string, number> {
  const m = new Map<string, number>();
  for (const t of tokens) m.set(t, (m.get(t) || 0) + 1);
  return m;
}

function cosine(a: Map<string, number>, b: Map<string, number>): number {
  let dot = 0;
  let na = 0;
  let nb = 0;
  for (const [, v] of a) na += v * v;
  for (const [, v] of b) nb += v * v;
  for (const [k, v] of a) {
    const w = b.get(k);
    if (w) dot += v * w;
  }
  if (na === 0 || nb === 0) return 0;
  return dot / (Math.sqrt(na) * Math.sqrt(nb));
}

export function semanticRetrieve(query: string, limit = 4): RetrievalHit[] {
  const docs = ensureKnowledgeIndexed();
  const qTokens = tokenize(query);
  const qTf = tf(qTokens);
  const scored = docs.map((d) => {
    const score = cosine(qTf, tf(d.tokens));
    const snippet = d.body.slice(0, 180) + (d.body.length > 180 ? "…" : "");
    return {
      documentId: d.id,
      title: d.title,
      category: d.category,
      score: Math.round(score * 1000) / 1000,
      snippet,
    } satisfies RetrievalHit;
  });
  return scored
    .filter((h) => h.score > 0.05)
    .sort((a, b) => b.score - a.score)
    .slice(0, limit);
}
