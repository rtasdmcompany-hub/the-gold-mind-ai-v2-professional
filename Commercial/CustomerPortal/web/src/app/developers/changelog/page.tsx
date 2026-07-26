import { changelog, versionHistory } from "@/server/api-platform/catalog";

export default function DevelopersChangelogPage() {
  const versions = versionHistory();
  const logs = changelog();
  return (
    <>
      <h1 className="page-title">Version History & Changelog</h1>
      <h2 style={{ fontSize: 16 }}>Versions</h2>
      <div className="table-wrap" style={{ marginBottom: 16 }}>
        <table className="data">
          <thead>
            <tr>
              <th>Version</th>
              <th>Status</th>
              <th>Released</th>
              <th>Notes</th>
            </tr>
          </thead>
          <tbody>
            {versions.map((v) => (
              <tr key={v.version}>
                <td>{v.version}</td>
                <td>{v.status}</td>
                <td>{v.released}</td>
                <td>{v.notes}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
      <h2 style={{ fontSize: 16 }}>Changelog</h2>
      {logs.map((c) => (
        <div key={c.date} className="card" style={{ marginBottom: 12 }}>
          <strong>
            {c.date} · {c.version}
          </strong>
          <ul>
            {c.items.map((i) => (
              <li key={i}>{i}</li>
            ))}
          </ul>
        </div>
      ))}
    </>
  );
}
