import { mockAnnouncements } from "@/lib/mock-data";

export default function AnnouncementsPage() {
  return (
    <>
      <header style={{ marginBottom: 20 }}>
        <h1 className="page-title">Announcements</h1>
        <p className="page-sub">Product and commercial notices.</p>
      </header>
      <ul className="list-plain">
        {mockAnnouncements.map((a) => (
          <li key={a.id} className="card" style={{ marginBottom: 12 }}>
            <h3 style={{ textTransform: "none", letterSpacing: 0, fontSize: 15, color: "var(--gm-ivory-100)" }}>
              {a.title}
            </h3>
            <div className="meta">{a.date}</div>
            <p style={{ margin: "8px 0 0" }}>{a.body}</p>
          </li>
        ))}
      </ul>
    </>
  );
}
