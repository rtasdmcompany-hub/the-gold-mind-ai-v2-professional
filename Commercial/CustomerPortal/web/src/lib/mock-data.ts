import type { License, Device, DownloadItem, Invoice, Order, Ticket, Announcement, ActivityItem, Subscription, KbArticle } from "./types";
import { brand } from "@/lib/brand";

export const mockCustomer = {
  name: "Alex Rivera",
  email: "alex.rivera@example.com",
  role: "customer" as const,
  edition: brand.productName,
  installedVersion: "2.0.0",
  latestVersion: "2.0.0",
  supportStatus: "Standard · First response ≤ 2 business days",
};

export const mockSubscription: Subscription = {
  plan: "Yearly",
  status: "Active",
  renewsOn: "2027-07-26",
  autoRenew: true,
};

export const mockLicenses: License[] = [
  {
    id: "lic_pro_001",
    keyMasked: "TGM-PRO-****-****-A7K2",
    edition: "Professional",
    type: "Yearly",
    activationStatus: "Activated",
    expiresOn: "2027-07-26",
    renewalStatus: "Auto-renew on",
    seatsUsed: 1,
    seatsMax: 2,
  },
  {
    id: "lic_trial_archived",
    keyMasked: "TGM-TRL-****-****-9Q1M",
    edition: "Professional",
    type: "Trial",
    activationStatus: "Expired",
    expiresOn: "2026-06-01",
    renewalStatus: "Converted",
    seatsUsed: 0,
    seatsMax: 1,
  },
];

export const mockDevices: Device[] = [
  {
    id: "dev_01",
    name: "Trading-PC-Home",
    activationDate: "2026-07-01",
    lastActive: "2026-07-25",
    status: "Active",
    licenseId: "lic_pro_001",
  },
  {
    id: "dev_02",
    name: "VPS-London (reserved UI)",
    activationDate: "—",
    lastActive: "—",
    status: "Inactive",
    licenseId: "lic_pro_001",
  },
];

export const mockDownloads: DownloadItem[] = [
  {
    id: "dl_200",
    version: "2.0.0",
    channel: "Public Stable",
    releasedOn: "2026-07-20",
    checksumSha256: "a3f1c9e8b2d4470f91c6e5a8d0b3f7e1c4a6928d5e7b1f0c3d6a9e2b5c8f1d4a",
    sizeMb: 12.4,
    notesUrl: "/portal/downloads",
    requirements: "Windows 10/11 · MetaTrader 5 · 4 GB RAM recommended",
  },
  {
    id: "dl_191",
    version: "1.9.1",
    channel: "Public Stable",
    releasedOn: "2026-05-12",
    checksumSha256: "b8e2d1a7c4f9053e62a1b9d8c7e6f5a4b3c2d1e0f9a8b7c6d5e4f3a2b1c0d9e8",
    sizeMb: 11.9,
    notesUrl: "/portal/downloads",
    requirements: "Windows 10/11 · MetaTrader 5",
  },
];

export const mockDownloadHistory = [
  { version: "2.0.0", downloadedAt: "2026-07-21 09:14", ipMasked: "203.0.113.***" },
];

export const mockInvoices: Invoice[] = [
  { id: "inv_1042", date: "2026-07-26", amount: "USD 899.00", status: "Paid", description: "Professional Yearly" },
  { id: "inv_0988", date: "2026-06-01", amount: "USD 0.00", status: "Paid", description: "Trial (no charge)" },
];

export const mockOrders: Order[] = [
  { id: "ord_7721", date: "2026-07-26", product: `${brand.productName} — Yearly`, status: "Completed" },
];

export const mockTickets: Ticket[] = [
  { id: "tkt_301", subject: "Checksum verification steps", status: "Resolved", priority: "Normal", updatedAt: "2026-07-22" },
  { id: "tkt_288", subject: "Device rename request (future)", status: "Open", priority: "Low", updatedAt: "2026-07-24" },
];

export const mockAnnouncements: Announcement[] = [
  { id: "ann_12", title: "Phase 9 Customer Portal MVP", date: "2026-07-26", body: "Portal hub is live for Professional customers. License generation remains a later sprint." },
  { id: "ann_11", title: "Core Trading Engine remains frozen", date: "2026-07-20", body: "Commercial services are isolated from live trading behaviour." },
];

export const mockActivity: ActivityItem[] = [
  { id: "act_1", at: "2026-07-25 18:02", text: "Signed in via Google / Demo" },
  { id: "act_2", at: "2026-07-21 09:14", text: "Downloaded Professional 2.0.0" },
  { id: "act_3", at: "2026-07-01 11:40", text: "Device Trading-PC-Home activated (read-only record)" },
];

export const mockKb: KbArticle[] = [
  { id: "kb_1", category: "Installation", title: `Install ${brand.productName}`, slug: "install" },
  { id: "kb_2", category: "Activation", title: "Activate your license (coming online)", slug: "activate" },
  { id: "kb_3", category: "Downloads", title: "Verify package checksum", slug: "checksum" },
  { id: "kb_4", category: "Security", title: "Portal sign-in with Google", slug: "google-oauth" },
];
