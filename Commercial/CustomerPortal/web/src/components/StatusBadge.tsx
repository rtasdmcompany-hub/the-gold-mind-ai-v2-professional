export function StatusBadge({ status }: { status: string }) {
  const s = status.toLowerCase();
  let cls = "badge-info";
  if (["active", "activated", "paid", "completed", "resolved", "ok"].some((x) => s.includes(x))) {
    cls = "badge-ok";
  } else if (["grace", "pending", "open", "warn"].some((x) => s.includes(x))) {
    cls = "badge-warn";
  } else if (["expired", "failed", "inactive", "danger"].some((x) => s.includes(x))) {
    cls = "badge-danger";
  }
  return <span className={`badge ${cls}`}>{status}</span>;
}
