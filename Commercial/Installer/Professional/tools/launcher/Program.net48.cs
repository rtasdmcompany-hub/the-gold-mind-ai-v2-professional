using System;
using System.Diagnostics;
using System.IO;
using System.Windows.Forms;

namespace TgmProfessionalLauncher
{
    internal static class Program
    {
        [STAThread]
        static void Main()
        {
            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);

            string appDir = AppDomain.CurrentDomain.BaseDirectory;
            string root = Path.GetFullPath(Path.Combine(appDir, ".."));
            string versionFile = Path.Combine(root, "config", "version.json");
            string version = "1.0.0";
            if (File.Exists(versionFile))
            {
                try
                {
                    string txt = File.ReadAllText(versionFile);
                    int idx = txt.IndexOf("\"version\"", StringComparison.OrdinalIgnoreCase);
                    if (idx >= 0)
                    {
                        int colon = txt.IndexOf(':', idx);
                        int q1 = txt.IndexOf('"', colon + 1);
                        int q2 = txt.IndexOf('"', q1 + 1);
                        if (q1 > 0 && q2 > q1) version = txt.Substring(q1 + 1, q2 - q1 - 1);
                    }
                }
                catch { }
            }

            string msg =
                "THE GOLD MIND PROFESSIONAL\n" +
                "Version " + version + "\n\n" +
                "Commercial shell ready.\n\n" +
                "Next steps:\n" +
                "1. Activate license (Start Menu -> Activate License)\n" +
                "2. Ensure EA is deployed to MT5 (Deploy EA to MT5)\n" +
                "3. Open MetaTrader 5 -> Navigator -> The Gold Mind\n" +
                "4. Attach TheGoldMindAI_Professional to a chart\n\n" +
                "Core Trading Engine is certified and unchanged.";

            DialogResult result = MessageBox.Show(
                msg + "\n\nOpen MetaTrader 5 now?",
                "THE GOLD MIND PROFESSIONAL",
                MessageBoxButtons.YesNo,
                MessageBoxIcon.Information);

            if (result == DialogResult.Yes)
            {
                string[] candidates = new string[]
                {
                    Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ProgramFiles), "MetaTrader 5", "terminal64.exe"),
                    Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ProgramFilesX86), "MetaTrader 5", "terminal64.exe"),
                    Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ProgramFiles), "MetaTrader 5", "terminal.exe"),
                };
                foreach (string c in candidates)
                {
                    if (File.Exists(c))
                    {
                        Process.Start(new ProcessStartInfo(c) { UseShellExecute = true });
                        return;
                    }
                }
                MessageBox.Show(
                    "MetaTrader 5 executable was not found in Program Files.\nOpen MT5 manually from your desktop.",
                    "THE GOLD MIND PROFESSIONAL",
                    MessageBoxButtons.OK,
                    MessageBoxIcon.Warning);
            }
        }
    }
}
