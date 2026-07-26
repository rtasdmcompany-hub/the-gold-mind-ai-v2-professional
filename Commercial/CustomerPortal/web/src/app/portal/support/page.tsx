import { auth } from "@/auth";
import Link from "next/link";
import { redirect } from "next/navigation";
import { StatusBadge } from "@/components/StatusBadge";
import { AiAssistantWidget } from "@/components/AiAssistantWidget";
import { listSupportTickets, ensureDemoTickets } from "@/server/admin/support-store";
import { actionSubmitSupportTicket } from "@/server/admin/actions";

export default async function SupportPage() {
  const session = await auth();
  if (!session?.user?.email) redirect("/login");
  ensureDemoTickets();
  const email = session.user.email.toLowerCase();
  const tickets = listSupportTickets().filter((t) => t.customerEmail === email);

  return (
    <>
      <header style={{ marginBottom: 20 }}>
        <h1 className="page-title">Support</h1>
        <p className="page-sub">
          Ticket intake · audited · commercial cloud. <Link href="/portal/knowledge-base">Knowledge Base</Link>
          {" · "}
          AI Assistant available via the chat button.
        </p>
      </header>

      <div className="card" style={{ marginBottom: 16 }}>
        <h3>New ticket</h3>
        <form action={actionSubmitSupportTicket} className="stack" style={{ marginTop: 12 }}>
          <div className="field">
            <label htmlFor="subject">Subject</label>
            <input id="subject" name="subject" placeholder="Brief summary" required />
          </div>
          <div className="field">
            <label htmlFor="body">Details</label>
            <textarea id="body" name="body" rows={5} placeholder="How can we help?" required />
          </div>
          <button type="submit" className="btn btn-primary">
            Submit ticket
          </button>
        </form>
      </div>

      <div className="table-wrap">
        <table className="data">
          <thead>
            <tr>
              <th>Ticket</th>
              <th>Subject</th>
              <th>Priority</th>
              <th>Status</th>
              <th>Updated</th>
            </tr>
          </thead>
          <tbody>
            {tickets.length === 0 && (
              <tr>
                <td colSpan={5}>No tickets yet.</td>
              </tr>
            )}
            {tickets.map((t) => (
              <tr key={t.id}>
                <td className="mono">{t.id}</td>
                <td>{t.subject}</td>
                <td>{t.priority}</td>
                <td>
                  <StatusBadge status={t.status} />
                </td>
                <td>{t.updatedAt.slice(0, 19).replace("T", " ")}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
      <AiAssistantWidget
        surface="support_center"
        role="customer"
        customerEmail={email}
        title="Support AI"
      />
    </>
  );
}
