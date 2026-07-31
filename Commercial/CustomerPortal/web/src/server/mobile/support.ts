/**
 * Mobile support center — KB, FAQs, tickets, chat/AI placeholders, diagnostics.
 */
import { newMobileId, readMobileStore, writeMobileStore } from "./store";
import type { DiagnosticReport, MobilePlatform, SupportTicketMobile } from "./types";
import { brand } from "@/lib/brand";

const KB = [
  { id: "kb1", title: "Getting started with the Customer Portal", tags: ["onboarding"] },
  { id: "kb2", title: "How to activate a license on MT5", tags: ["licensing"] },
  { id: "kb3", title: "Managing devices and transfers", tags: ["devices"] },
  { id: "kb4", title: "Billing and invoices", tags: ["billing"] },
  { id: "kb5", title: "Mobile Companion overview", tags: ["mobile"] },
  { id: "kb6", title: "Why the app cannot place trades", tags: ["security", "core"] },
];

const FAQS = [
  {
    id: "faq1",
    q: "Can I trade from the mobile app?",
    a: `No. ${brand.brandName} Mobile Companion is a business app only. All trading stays in certified MT5 Professional.`,
  },
  {
    id: "faq2",
    q: "How do I transfer a license to a new PC?",
    a: "Open License Management → select the old device → Request Transfer, then activate on the new machine.",
  },
  {
    id: "faq3",
    q: "How do I enable marketing notifications?",
    a: "Marketing pushes are off by default. Enable them under Notification Preferences (opt-in).",
  },
  {
    id: "faq4",
    q: "What is biometric login?",
    a: "On supported devices you can unlock the app with fingerprint or Face ID after the first secure login.",
  },
];

export function listKnowledgeArticles() {
  return KB;
}

export function listFaqs() {
  return FAQS;
}

export function listTicketsForCustomer(email: string): SupportTicketMobile[] {
  return readMobileStore().tickets.filter((t) => t.customerEmail === email.toLowerCase());
}

export function createSupportTicket(input: {
  email: string;
  subject: string;
  channel?: SupportTicketMobile["channel"];
}): SupportTicketMobile {
  const store = readMobileStore();
  const now = new Date().toISOString();
  const ticket: SupportTicketMobile = {
    id: newMobileId("mtkt"),
    customerEmail: input.email.toLowerCase(),
    subject: input.subject,
    status: "open",
    channel: input.channel || "ticket",
    createdAt: now,
    updatedAt: now,
  };
  store.tickets.unshift(ticket);
  writeMobileStore(store);
  return ticket;
}

export function liveChatPlaceholder() {
  return {
    status: "placeholder",
    message: "Live chat will connect to the commercial support queue in a future release.",
    hours: "Mon–Fri 09:00–18:00 UTC",
  };
}

export function aiSupportEntryPoint() {
  return {
    status: "available",
    entry: "/api/ai/chat",
    search: "/api/ai/search",
    disclaimer: "AI assistant answers commercial/account questions only — never executes trades.",
  };
}

export function submitDiagnosticReport(input: {
  email: string;
  deviceId: string;
  appVersion: string;
  platform: MobilePlatform;
  summary: string;
}): DiagnosticReport {
  const store = readMobileStore();
  const report: DiagnosticReport = {
    id: newMobileId("diag"),
    customerEmail: input.email.toLowerCase(),
    deviceId: input.deviceId,
    appVersion: input.appVersion,
    platform: input.platform,
    payloadSummary: input.summary.slice(0, 2000),
    submittedAt: new Date().toISOString(),
  };
  store.diagnostics.unshift(report);
  writeMobileStore(store);
  return report;
}

export function supportCenterOverview() {
  const store = readMobileStore();
  return {
    kbArticles: KB.length,
    faqs: FAQS.length,
    openTickets: store.tickets.filter((t) => t.status === "open").length,
    diagnostics: store.diagnostics.length,
    liveChat: liveChatPlaceholder(),
    ai: aiSupportEntryPoint(),
  };
}
