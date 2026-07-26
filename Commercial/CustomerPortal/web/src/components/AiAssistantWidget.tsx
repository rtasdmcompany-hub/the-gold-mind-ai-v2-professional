"use client";

import { useState } from "react";

type AiSurface =
  | "website"
  | "customer_portal"
  | "partner_portal"
  | "admin_portal"
  | "mobile"
  | "support_center";

type Msg = { role: string; content: string };

export function AiAssistantWidget({
  surface = "customer_portal",
  role = "customer",
  customerEmail,
  title = "AI Assistant",
}: {
  surface?: AiSurface;
  role?: "anonymous" | "customer" | "partner" | "admin" | "support";
  customerEmail?: string;
  title?: string;
}) {
  const [open, setOpen] = useState(false);
  const [conversationId, setConversationId] = useState<string | null>(null);
  const [input, setInput] = useState("");
  const [msgs, setMsgs] = useState<Msg[]>([]);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function ensureStarted() {
    if (conversationId) return conversationId;
    const res = await fetch("/api/ai/chat", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ action: "start", surface, role, customerEmail }),
    });
    const json = await res.json();
    if (!json.ok) throw new Error(json.error?.message || "START_FAILED");
    const id = json.data.conversation.id as string;
    setConversationId(id);
    const welcome = json.data.conversation.messages?.[0];
    if (welcome) setMsgs([{ role: welcome.role, content: welcome.content }]);
    return id;
  }

  async function send() {
    if (!input.trim() || busy) return;
    setBusy(true);
    setError(null);
    const text = input.trim();
    setInput("");
    setMsgs((m) => [...m, { role: "user", content: text }]);
    try {
      const id = await ensureStarted();
      const res = await fetch("/api/ai/chat", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ action: "ask", conversationId: id, message: text }),
      });
      const json = await res.json();
      if (!json.ok) throw new Error(json.error?.message || "ASK_FAILED");
      setMsgs((m) => [...m, { role: "assistant", content: json.data.reply.content }]);
    } catch (e) {
      setError(e instanceof Error ? e.message : "ERROR");
    } finally {
      setBusy(false);
    }
  }

  async function escalate() {
    if (!conversationId) return;
    setBusy(true);
    try {
      await fetch("/api/ai/chat", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          action: "escalate",
          conversationId,
          note: "User requested human agent from widget",
        }),
      });
      setMsgs((m) => [
        ...m,
        { role: "system", content: "Escalated to human support. A ticket has been created." },
      ]);
    } finally {
      setBusy(false);
    }
  }

  return (
    <div style={{ position: "fixed", right: 16, bottom: 16, zIndex: 50 }}>
      {!open && (
        <button type="button" className="btn btn-primary" onClick={() => setOpen(true)}>
          {title}
        </button>
      )}
      {open && (
        <div
          className="card"
          style={{
            width: 340,
            maxWidth: "92vw",
            height: 420,
            display: "flex",
            flexDirection: "column",
            boxShadow: "0 8px 28px rgba(0,0,0,0.18)",
          }}
        >
          <div style={{ display: "flex", justifyContent: "space-between", marginBottom: 8 }}>
            <strong>{title}</strong>
            <button type="button" className="btn" onClick={() => setOpen(false)}>
              Close
            </button>
          </div>
          <p style={{ fontSize: 11, margin: "0 0 8px", opacity: 0.75 }}>
            Commercial support only — no trading advice.
          </p>
          <div style={{ flex: 1, overflow: "auto", fontSize: 13, marginBottom: 8 }}>
            {msgs.map((m, i) => (
              <div key={i} style={{ marginBottom: 8 }}>
                <div style={{ fontWeight: 600, fontSize: 11 }}>{m.role}</div>
                <div style={{ whiteSpace: "pre-wrap" }}>{m.content}</div>
              </div>
            ))}
          </div>
          {error && <p style={{ color: "#b91c1c", fontSize: 12 }}>{error}</p>}
          <div style={{ display: "flex", gap: 6 }}>
            <input
              value={input}
              onChange={(e) => setInput(e.target.value)}
              onKeyDown={(e) => e.key === "Enter" && send()}
              placeholder="Ask about licenses, billing…"
              style={{ flex: 1, padding: "6px 8px" }}
              aria-label="AI message"
            />
            <button type="button" className="btn btn-primary" disabled={busy} onClick={send}>
              Send
            </button>
          </div>
          <button type="button" className="btn" style={{ marginTop: 6 }} disabled={busy} onClick={escalate}>
            Talk to human
          </button>
        </div>
      )}
    </div>
  );
}
