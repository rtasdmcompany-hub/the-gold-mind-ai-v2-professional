import Link from "next/link";
import {
  KB_CATEGORY_LABELS,
  getKbArticle,
  listKbArticles,
  markKbView,
  type KbCategory,
} from "@/server/success/knowledge-base";

export default async function KnowledgeBasePage({
  searchParams,
}: {
  searchParams: Promise<{ category?: string; q?: string; slug?: string }>;
}) {
  const sp = await searchParams;
  if (sp.slug) markKbView(sp.slug);
  const article = sp.slug ? getKbArticle(sp.slug) : null;
  const articles = listKbArticles({
    category: sp.category as KbCategory | undefined,
    q: sp.q,
  });
  const categories = Object.keys(KB_CATEGORY_LABELS) as KbCategory[];

  return (
    <>
      <header style={{ marginBottom: 20 }}>
        <h1 className="page-title">Knowledge Base</h1>
        <p className="page-sub">
          Static commercial guidance (shipped with the portal build — not a live CMS). View counts are session-memory
          only and are not analytics. Installation · Activation · Licensing · Portal · Troubleshooting · Updates · FAQ ·
          MT5 · Broker
        </p>
      </header>

      <form className="card" method="get" style={{ marginBottom: 16, display: "flex", flexWrap: "wrap", gap: 12 }}>
        <div className="field">
          <label htmlFor="q">Search</label>
          <input id="q" name="q" defaultValue={sp.q || ""} />
        </div>
        <div className="field">
          <label htmlFor="category">Category</label>
          <select id="category" name="category" defaultValue={sp.category || ""}>
            <option value="">All</option>
            {categories.map((c) => (
              <option key={c} value={c}>
                {KB_CATEGORY_LABELS[c]}
              </option>
            ))}
          </select>
        </div>
        <button type="submit" className="btn btn-primary" style={{ alignSelf: "flex-end" }}>
          Filter
        </button>
      </form>

      {article && (
        <div className="card" style={{ marginBottom: 16 }}>
          <div className="meta">{KB_CATEGORY_LABELS[article.category]} · {article.views} views</div>
          <h2 style={{ fontSize: 20 }}>{article.title}</h2>
          <p>{article.body}</p>
          <div className="meta">Tags: {article.tags.join(", ")}</div>
        </div>
      )}

      <div className="grid grid-2">
        {articles.map((a) => (
          <Link key={a.id} href={`/portal/knowledge-base?slug=${a.slug}`} className="card" style={{ display: "block" }}>
            <h3>{KB_CATEGORY_LABELS[a.category]}</h3>
            <div className="value" style={{ fontSize: 16 }}>
              {a.title}
            </div>
            <div className="meta">
              {a.summary} · {a.views} views
            </div>
          </Link>
        ))}
      </div>
    </>
  );
}
