import { apiEndpointCatalog } from "@/server/api-platform/catalog";

export default function DevelopersDocsPage() {
  const endpoints = apiEndpointCatalog();
  return (
    <>
      <h1 className="page-title">API Documentation</h1>
      <p className="page-sub">Versioned commercial REST API — base path /api/v1</p>
      <div className="table-wrap">
        <table className="data">
          <thead>
            <tr>
              <th>Method</th>
              <th>Path</th>
              <th>Scope</th>
              <th>Summary</th>
            </tr>
          </thead>
          <tbody>
            {endpoints.map((e) => (
              <tr key={`${e.method}${e.path}`}>
                <td>{e.method}</td>
                <td className="mono">{e.path}</td>
                <td>{e.scope}</td>
                <td>{e.summary}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </>
  );
}
