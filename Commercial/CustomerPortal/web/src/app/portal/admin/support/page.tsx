import { auth } from "@/auth";
import { redirect } from "next/navigation";
import { StatusBadge } from "@/components/StatusBadge";
import { hasPermission } from "@/server/admin/roles";
import { ensureDemoTickets, listSupportTickets } from "@/server/admin/support-store";
import {
  actionCreateAdminSupportTicket,
  actionUpdateSupportTicket,
} from "@/server/admin/actions";

export default async function AdminSupportConsolePage({
  searchParams,
}: {
  searchParams: Promise<{ status?: string; q?: string }>;
}) {
  const session = await auth();
  const role = (session?.user as { role?: string } | undefined)?.role;
  const actor = session?.user?.email?.toLowerCase() || "";
  if (!hasPermission(role, "admin.support.read")) redirect("/portal");

  ensureDemoTickets();
  const sp = await searchParams;
  const tickets = listSupportTickets({
    status: sp.status as "open" | "pending" | "resolved" | "closed" | undefined,
    q: sp.q,
  });
  const canWrite = hasPermission(role, "admin.support.write");

  return (
    <>
      <header style={{ marginBottom: 20 }}>
        <h1 className="page-title">Support Console</h1>
        <p className="page-sub">
          Ticket queue · assignment · priority · response/resolution status · KB links · internal notes
        </p>
      </header>

      <form className="card" method="get" style={{ marginBottom: 16, display: "flex", flexWrap: "wrap", gap: 12 }}>
        <div className="field">
          <label htmlFor="q">Search</label>
          <input id="q" name="q" defaultValue={sp.q || ""} placeholder="email, subject, id" />
        </div>
        <div className="field">
          <label htmlFor="status">Status</label>
          <select id="status" name="status" defaultValue={sp.status || ""}>
            <option value="">All</option>
            <option value="open">Open</option>
            <option value="pending">Pending</option>
            <option value="resolved">Resolved</option>
            <option value="closed">Closed</option>
          </select>
        </div>
        <button type="submit" className="btn btn-primary" style={{ alignSelf: "flex-end" }}>
          Filter
        </button>
      </form>

      {canWrite && (
        <form action={actionCreateAdminSupportTicket} className="card" style={{ marginBottom: 16 }}>
          <h3>Create ticket</h3>
          <div className="stack" style={{ marginTop: 8 }}>
            <div className="field">
              <label htmlFor="customerEmail">Customer email</label>
              <input id="customerEmail" name="customerEmail" required />
            </div>
            <div className="field">
              <label htmlFor="subject">Subject</label>
              <input id="subject" name="subject" required />
            </div>
            <div className="field">
              <label htmlFor="body">Body</label>
              <textarea id="body" name="body" rows={3} required />
            </div>
            <div className="field">
              <label htmlFor="priority">Priority</label>
              <select id="priority" name="priority" defaultValue="normal">
                <option value="low">Low</option>
                <option value="normal">Normal</option>
                <option value="high">High</option>
                <option value="urgent">Urgent</option>
              </select>
            </div>
            <button type="submit" className="btn btn-primary">
              Create
            </button>
          </div>
        </form>
      )}

      <div className="grid" style={{ gap: 16 }}>
        {tickets.map((t) => (
          <div className="card" key={t.id}>
            <div className="grid grid-3">
              <div>
                <h3 style={{ textTransform: "none" }}>{t.subject}</h3>
                <div className="meta mono">{t.id}</div>
                <div className="meta">{t.customerEmail}</div>
              </div>
              <div>
                <div className="meta">
                  Status: <StatusBadge status={t.status} />
                </div>
                <div className="meta">Priority: {t.priority}</div>
                <div className="meta">Assignee: {t.assignee || "unassigned"}</div>
              </div>
              <div>
                <div className="meta">Created: {t.createdAt.slice(0, 16).replace("T", " ")}</div>
                <div className="meta">KB: {t.kbLinks.join(", ")}</div>
              </div>
            </div>
            <p style={{ marginTop: 8 }}>{t.body}</p>
            {t.internalNotes[0] && (
              <p className="meta">
                Latest note ({t.internalNotes[0].by}): {t.internalNotes[0].note}
              </p>
            )}
            {canWrite && (
              <form action={actionUpdateSupportTicket} style={{ marginTop: 12, display: "flex", flexWrap: "wrap", gap: 8 }}>
                <input type="hidden" name="ticketId" value={t.id} />
                <select name="status" defaultValue={t.status}>
                  <option value="open">Open</option>
                  <option value="pending">Pending</option>
                  <option value="resolved">Resolved</option>
                  <option value="closed">Closed</option>
                </select>
                <select name="priority" defaultValue={t.priority}>
                  <option value="low">Low</option>
                  <option value="normal">Normal</option>
                  <option value="high">High</option>
                  <option value="urgent">Urgent</option>
                </select>
                <input name="assignee" defaultValue={t.assignee || actor} placeholder="Assignee" />
                <input name="note" placeholder="Internal note" />
                <input name="resolution" placeholder="Resolution" defaultValue={t.resolution || ""} />
                <button type="submit" className="btn btn-primary">
                  Update
                </button>
              </form>
            )}
          </div>
        ))}
      </div>
    </>
  );
}
