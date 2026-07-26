export type Role = "customer" | "admin";

export type License = {
  id: string;
  keyMasked: string;
  edition: string;
  type: "Trial" | "Monthly" | "Yearly" | "Lifetime";
  activationStatus: "Pending" | "Activated" | "Grace" | "Expired";
  expiresOn: string;
  renewalStatus: string;
  seatsUsed: number;
  seatsMax: number;
};

export type Device = {
  id: string;
  name: string;
  activationDate: string;
  lastActive: string;
  status: "Active" | "Inactive" | "Pending";
  licenseId: string;
};

export type DownloadItem = {
  id: string;
  version: string;
  channel: string;
  releasedOn: string;
  checksumSha256: string;
  sizeMb: number;
  notesUrl: string;
  requirements: string;
};

export type Invoice = {
  id: string;
  date: string;
  amount: string;
  status: string;
  description: string;
};

export type Order = {
  id: string;
  date: string;
  product: string;
  status: string;
};

export type Ticket = {
  id: string;
  subject: string;
  status: string;
  priority: string;
  updatedAt: string;
};

export type Announcement = {
  id: string;
  title: string;
  date: string;
  body: string;
};

export type ActivityItem = {
  id: string;
  at: string;
  text: string;
};

export type Subscription = {
  plan: string;
  status: string;
  renewsOn: string;
  autoRenew: boolean;
};

export type KbArticle = {
  id: string;
  category: string;
  title: string;
  slug: string;
};
