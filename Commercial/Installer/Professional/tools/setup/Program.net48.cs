using System;
using System.Diagnostics;
using System.IO;
using System.IO.Compression;
using System.Linq;
using System.Reflection;
using System.Text;
using System.Windows.Forms;
using Microsoft.Win32;

namespace TgmProfessionalSetup
{
    internal static class Program
    {
        private const string ProductName = "THE GOLD MIND PROFESSIONAL";
        private const string Version = "1.0.0";
        private const string Publisher = "RTAS Group of Companies";

        [STAThread]
        static int Main(string[] args)
        {
            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);

            try
            {
                bool silent = args.Any(a =>
                    a.Equals("/SILENT", StringComparison.OrdinalIgnoreCase) ||
                    a.Equals("/VERYSILENT", StringComparison.OrdinalIgnoreCase));

                string installRoot = Path.Combine(
                    Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
                    ProductName);

                if (!silent)
                {
                    DialogResult intro = MessageBox.Show(
                        ProductName + " Setup " + Version + "\n" +
                        Publisher + "\n\n" +
                        "This installer deploys the commercial package and optionally\n" +
                        "copies TheGoldMindAI_Professional.ex5 into MetaTrader 5.\n\n" +
                        "The Core Trading Engine is NOT modified.\n\n" +
                        "Install to:\n" + installRoot + "\n\nContinue?",
                        ProductName + " Setup",
                        MessageBoxButtons.OKCancel,
                        MessageBoxIcon.Information);
                    if (intro != DialogResult.OK) return 1;
                }

                Directory.CreateDirectory(installRoot);
                ExtractPayload(installRoot);

                // Interactive only: silent/CI installs extract files; user deploys EA from Start Menu.
                if (!silent)
                {
                    DialogResult eaAsk = MessageBox.Show(
                        "Detect MetaTrader 5 and install the Expert Advisor now?",
                        ProductName + " Setup",
                        MessageBoxButtons.YesNo,
                        MessageBoxIcon.Question);
                    if (eaAsk == DialogResult.Yes)
                    {
                        RunPs(Path.Combine(installRoot, "scripts", "Deploy-EA-To-MT5.ps1"),
                            "-InstallRoot \"" + installRoot + "\" -Silent");
                    }
                }

                if (!silent)
                {
                    DialogResult actAsk = MessageBox.Show(
                        "Activate license now?\n\n(You can also use Start Menu -> Activate License later.)",
                        ProductName + " Setup",
                        MessageBoxButtons.YesNo,
                        MessageBoxIcon.Question);
                    if (actAsk == DialogResult.Yes)
                    {
                        bool google = MessageBox.Show(
                            "Open Google login in browser first? (optional)",
                            ProductName + " Setup",
                            MessageBoxButtons.YesNo,
                            MessageBoxIcon.Question) == DialogResult.Yes;
                        string argsPs = "-InstallRoot \"" + installRoot + "\"";
                        if (google) argsPs += " -GoogleLogin";
                        RunPs(Path.Combine(installRoot, "scripts", "Activate-License.ps1"), argsPs);
                    }
                }

                CreateShortcuts(installRoot, silent);
                RegisterUninstall(installRoot);

                if (!silent)
                {
                    MessageBox.Show(
                        "Installation complete.\n\n" +
                        "Location: " + installRoot + "\n" +
                        "Open MT5 -> Navigator -> The Gold Mind -> attach EA.",
                        ProductName + " Setup",
                        MessageBoxButtons.OK,
                        MessageBoxIcon.Information);
                }

                return 0;
            }
            catch (Exception ex)
            {
                MessageBox.Show("Setup failed:\n" + ex.Message, ProductName + " Setup",
                    MessageBoxButtons.OK, MessageBoxIcon.Error);
                return 2;
            }
        }

        static void ExtractPayload(string installRoot)
        {
            Assembly asm = Assembly.GetExecutingAssembly();
            string name = asm.GetManifestResourceNames()
                .FirstOrDefault(n => n.EndsWith("payload.zip", StringComparison.OrdinalIgnoreCase));
            if (name == null)
                throw new InvalidOperationException("Embedded payload.zip not found in Setup.exe.");

            string tmpZip = Path.Combine(Path.GetTempPath(), "tgm-payload-" + Guid.NewGuid().ToString("N") + ".zip");
            using (Stream s = asm.GetManifestResourceStream(name))
            using (FileStream f = File.Create(tmpZip))
            {
                s.CopyTo(f);
            }

            string tmpDir = Path.Combine(Path.GetTempPath(), "tgm-extract-" + Guid.NewGuid().ToString("N"));
            if (Directory.Exists(tmpDir)) Directory.Delete(tmpDir, true);
            Directory.CreateDirectory(tmpDir);
            ZipFile.ExtractToDirectory(tmpZip, tmpDir);

            foreach (string dir in Directory.GetDirectories(tmpDir))
            {
                string dest = Path.Combine(installRoot, Path.GetFileName(dir));
                CopyDir(dir, dest);
            }
            foreach (string file in Directory.GetFiles(tmpDir))
            {
                File.Copy(file, Path.Combine(installRoot, Path.GetFileName(file)), true);
            }

            try { File.Delete(tmpZip); } catch { }
            try { Directory.Delete(tmpDir, true); } catch { }

            string ea = Path.Combine(installRoot, "ea", "TheGoldMindAI_Professional.ex5");
            if (!File.Exists(ea))
                throw new InvalidOperationException("EA binary missing after extract: " + ea);
        }

        static void CopyDir(string src, string dest)
        {
            Directory.CreateDirectory(dest);
            foreach (string file in Directory.GetFiles(src))
                File.Copy(file, Path.Combine(dest, Path.GetFileName(file)), true);
            foreach (string dir in Directory.GetDirectories(src))
                CopyDir(dir, Path.Combine(dest, Path.GetFileName(dir)));
        }

        static void RunPs(string script, string args)
        {
            if (!File.Exists(script)) return;
            ProcessStartInfo psi = new ProcessStartInfo
            {
                FileName = "powershell.exe",
                Arguments = "-NoProfile -ExecutionPolicy Bypass -File \"" + script + "\" " + args,
                UseShellExecute = false,
                CreateNoWindow = false
            };
            using (Process p = Process.Start(psi))
            {
                if (p != null) p.WaitForExit();
            }
        }

        static void CreateShortcuts(string installRoot, bool silent)
        {
            string launcher = Path.Combine(installRoot, "bin", "TGM-Professional-Launcher.exe");
            if (!File.Exists(launcher))
                launcher = Path.Combine(installRoot, "bin", "TGM-Professional-Launcher.cmd");

            string startDir = Path.Combine(
                Environment.GetFolderPath(Environment.SpecialFolder.StartMenu),
                "Programs", ProductName);
            Directory.CreateDirectory(startDir);

            WriteShortcut(Path.Combine(startDir, ProductName + ".lnk"), launcher, installRoot, null);
            WriteShortcut(
                Path.Combine(startDir, "Activate License.lnk"),
                "powershell.exe",
                installRoot,
                "-NoProfile -ExecutionPolicy Bypass -File \"" + Path.Combine(installRoot, "scripts", "Activate-License.ps1") + "\" -InstallRoot \"" + installRoot + "\"");
            WriteShortcut(
                Path.Combine(startDir, "Deploy EA to MT5.lnk"),
                "powershell.exe",
                installRoot,
                "-NoProfile -ExecutionPolicy Bypass -File \"" + Path.Combine(installRoot, "scripts", "Deploy-EA-To-MT5.ps1") + "\" -InstallRoot \"" + installRoot + "\"");

            bool createDesktop = false;
            if (!silent)
            {
                createDesktop = MessageBox.Show(
                    "Create Desktop shortcut?",
                    ProductName + " Setup",
                    MessageBoxButtons.YesNo,
                    MessageBoxIcon.Question) == DialogResult.Yes;
            }
            if (createDesktop)
            {
                string desk = Path.Combine(
                    Environment.GetFolderPath(Environment.SpecialFolder.DesktopDirectory),
                    ProductName + ".lnk");
                WriteShortcut(desk, launcher, installRoot, null);
            }
        }

        static void WriteShortcut(string lnkPath, string target, string workDir, string args)
        {
            StringBuilder ps = new StringBuilder();
            ps.AppendLine("$w = New-Object -ComObject WScript.Shell");
            ps.AppendLine("$s = $w.CreateShortcut('" + lnkPath.Replace("'", "''") + "')");
            ps.AppendLine("$s.TargetPath = '" + target.Replace("'", "''") + "'");
            if (!string.IsNullOrEmpty(args))
                ps.AppendLine("$s.Arguments = '" + args.Replace("'", "''") + "'");
            ps.AppendLine("$s.WorkingDirectory = '" + workDir.Replace("'", "''") + "'");
            ps.AppendLine("$s.Description = '" + ProductName.Replace("'", "''") + "'");
            ps.AppendLine("$s.Save()");
            string tmp = Path.Combine(Path.GetTempPath(), "tgm-lnk-" + Guid.NewGuid().ToString("N") + ".ps1");
            File.WriteAllText(tmp, ps.ToString(), Encoding.UTF8);
            RunPs(tmp, "");
            try { File.Delete(tmp); } catch { }
        }

        static void RegisterUninstall(string installRoot)
        {
            string keyPath = @"Software\Microsoft\Windows\CurrentVersion\Uninstall\TheGoldMindProfessional";
            using (RegistryKey key = Registry.CurrentUser.CreateSubKey(keyPath))
            {
                if (key == null) return;
                key.SetValue("DisplayName", ProductName);
                key.SetValue("Publisher", Publisher);
                key.SetValue("DisplayVersion", Version);
                key.SetValue("InstallLocation", installRoot);
                key.SetValue("InstallDate", DateTime.Now.ToString("yyyyMMdd"));
                key.SetValue("EstimatedSize", 4096);
                string uninst = "powershell.exe -NoProfile -ExecutionPolicy Bypass -Command \"Remove-Item -LiteralPath '" +
                                installRoot.Replace("'", "''") +
                                "' -Recurse -Force; Remove-Item -Path 'HKCU:\\" + keyPath.Replace("'", "''") + "' -Recurse -Force\"";
                key.SetValue("UninstallString", uninst);
                key.SetValue("NoModify", 1, RegistryValueKind.DWord);
                key.SetValue("NoRepair", 1, RegistryValueKind.DWord);
            }
        }
    }
}
