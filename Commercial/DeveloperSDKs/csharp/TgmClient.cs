// THE GOLD MIND API — C# sample (commercial only)
using System.Net.Http;
using System.Net.Http.Headers;

public class TgmClient {
  private readonly HttpClient _http = new HttpClient();
  public TgmClient(string baseUrl, string apiKey) {
    _http.BaseAddress = new System.Uri(baseUrl);
    _http.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", apiKey);
  }
  public async System.Threading.Tasks.Task<string> GetAsync(string path) {
    var res = await _http.GetAsync(path);
    res.EnsureSuccessStatusCode();
    return await res.Content.ReadAsStringAsync();
  }
}
