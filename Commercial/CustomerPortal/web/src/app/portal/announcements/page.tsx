import { auth } from "@/auth";
import { listPublishedAnnouncements, ensureAnnouncementsLoaded } from "@/server/announcements/store";
import { redirect } from "next/navigation";
import { brand } from "@/lib/brand";

export default async function AnnouncementsPage() {
  const session = await auth();
  if (!session?.user?.email) redirect("/login");
  await ensureAnnouncementsLoaded();

  const announcements = listPublishedAnnouncements();

  return (
    <>
      <header style={{ marginBottom: 20 }}>
        <h1 className="page-title">Announcements</h1>
        <p className="page-sub">
          Product and commercial notices for {brand.productName}. Empty until an admin publishes.
        </p>
      </header>
      {announcements.length === 0 ? (
        <div className="portal-empty">No announcements published yet.</div>
      ) : (
        <ul className="list-plain">
          {announcements.map((a) => (
            <li key={a.id} className="card" style={{ marginBottom: 12 }}>
              <h3 style={{ textTransform: "none", letterSpacing: 0, fontSize: 15, color: "var(--gm-ivory-100)" }}>
                {a.pinned ? "★ " : ""}
                {a.title}
              </h3>
              <div className="meta">{a.date}</div>
              <p style={{ margin: "8px 0 0" }}>{a.body}</p>
            </li>
          ))}
        </ul>
      )}
    </>
  );
}
