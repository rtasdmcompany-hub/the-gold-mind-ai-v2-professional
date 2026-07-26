using System;
using System.Diagnostics;
using System.IO;
using System.IO.Compression;
using System.Linq;
using System.Reflection;
using System.Security.Cryptography;
using System.Text;
using System.Windows.Forms;

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
                var silent = args.Any(a => a.Equals("/SILENT", StringComparison.OrdinalIgnoreCase)
                    || a.Equals("/VERYSILENT", StringComparison.OrdinalIgnoreCase));
                var installRoot = Path.Combine(
                    Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
                    ProductName);

                if (!silent)
                {
                    var intro = MessageBox.Show(
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

                var deployEa = true;
                if (!silent)
                {
                    var eaAsk = MessageBox.Show(
                        "Detect MetaTrader 5 and install the Expert Advisor now?",
                        ProductName + " Setup",
                        MessageBoxButtons.YesNo,
                        MessageBoxIcon.Question);
                    deployEa = eaAsk == DialogResult.Yes;
                }

                if (deployEa)
                {
                    RunPs(Path.Combine(installRoot, "scripts", "Deploy-EA-To-MT5.ps1"),
                        "-InstallRoot \"" + installRoot + "\" -Silent");
                }

                if (!silent)
                {
                    var actAsk = MessageBox.Show(
                        "Activate license now?\n\n(You can also use Start Menu → Activate License later.)",
                        ProductName + " Setup",
                        MessageBoxButtons.YesNo,
                        MessageBoxIcon.Question);
                    if (actAsk == DialogResult.Yes)
                    {
                        var google = MessageBox.Show(
                            "Open Google login in browser first? (optional)",
                            ProductName + " Setup",
                            MessageBoxButtons.YesNo,
                            MessageBoxIcon.Question) == DialogResult.Yes;
                        var argsPs = "-InstallRoot \"" + installRoot + "\"";
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
                        "Open MT5 → Navigator → The Gold Mind → attach EA.",
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
            var asm = Assembly.GetExecutingAssembly();
            var name = asm.GetManifestResourceNames()
                .FirstOrDefault(n => n.EndsWith("payload.zip", StringComparison.OrdinalIgnoreCase));
            if (name == null)
                throw new InvalidOperationException("Embedded payload.zip not found in Setup.exe.");

            var tmpZip = Path.Combine(Path.GetTempPath(), "tgm-payload-" + Guid.NewGuid().ToString("N") + ".zip");
            using (var s = asm.GetManifestResourceStream(name)!)
            using (var f = File.Create(tmpZip))
                s.CopyTo(f);

            var tmpDir = Path.Combine(Path.GetTempPath(), "tgm-extract-" + Guid.NewGuid().ToString("N"));
            Directory.CreateDirectory(tmpDir);
            ZipFile.ExtractToDirectory(tmpZip, tmpDir, true);

            foreach (var dir in Directory.GetDirectories(tmpDir))
            {
                var dest = Path.Combine(installRoot, Path.GetFileName(dir));
                CopyDir(dir, dest);
            }
            foreach (var file in Directory.GetFiles(tmpDir))
            {
                File.Copy(file, Path.Combine(installRoot, Path.GetFileName(file)), true);
            }

            try { File.Delete(tmpZip); } catch { }
            try { Directory.Delete(tmpDir, true); } catch { }

            // Verify EA present
            var ea = Path.Combine(installRoot, "ea", "TheGoldMindAI_Professional.ex5");
            if (!File.Exists(ea))
                throw new InvalidOperationException("EA binary missing after extract: " + ea);
        }

        static void CopyDir(string src, string dest)
        {
            Directory.CreateDirectory(dest);
            foreach (var file in Directory.GetFiles(src))
                File.Copy(file, Path.Combine(dest, Path.GetFileName(file)), true);
            foreach (var dir in Directory.GetDirectories(src))
                CopyDir(dir, Path.Combine(dest, Path.GetFileName(dir)));
        }

        static void RunPs(string script, string args)
        {
            if (!File.Exists(script)) return;
            var psi = new ProcessStartInfo
            {
                FileName = "powershell.exe",
                Arguments = "-NoProfile -ExecutionPolicy Bypass -File \"" + script + "\" " + args,
                UseShellExecute = false,
                CreateNoWindow = false
            };
            using var p = Process.Start(psi);
            p?.WaitForExit();
        }

        static void CreateShortcuts(string installRoot, bool silent)
        {
            var launcher = Path.Combine(installRoot, "bin", "TGM-Professional-Launcher.exe");
            if (!File.Exists(launcher))
                launcher = Path.Combine(installRoot, "bin", "TGM-Professional-Launcher.cmd");

            var startDir = Path.Combine(
                Environment.GetFolderPath(Environment.SpecialFolder.StartMenu),
                "Programs", ProductName);
            Directory.CreateDirectory(startDir);

            WriteShortcut(Path.Combine(startDir, ProductName + ".lnk"), launcher, installRoot);
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

            var createDesktop = !silent;
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
                var desk = Path.Combine(
                    Environment.GetFolderPath(Environment.SpecialFolder.DesktopDirectory),
                    ProductName + ".lnk");
                WriteShortcut(desk, launcher, installRoot);
            }
        }

        static void WriteShortcut(string lnkPath, string target, string workDir, string? args = null)
        {
            // VBScript shortcut writer — no extra COM refs required at compile time beyond late bind via PowerShell
            var ps = new StringBuilder();
            ps.AppendLine("$w = New-Object -ComObject WScript.Shell");
            ps.AppendLine("$s = $w.CreateShortcut('" + lnkPath.Replace("'", "''") + "')");
            ps.AppendLine("$s.TargetPath = '" + target.Replace("'", "''") + "'");
            if (!string.IsNullOrEmpty(args))
                ps.AppendLine("$s.Arguments = '" + args.Replace("'", "''") + "'");
            ps.AppendLine("$s.WorkingDirectory = '" + workDir.Replace("'", "''") + "'");
            ps.AppendLine("$s.Description = '" + ProductName.Replace("'", "''") + "'");
            ps.AppendLine("$s.Save()");
            var tmp = Path.Combine(Path.GetTempPath(), "tgm-lnk-" + Guid.NewGuid().ToString("N") + ".ps1");
            File.WriteAllText(tmp, ps.ToString(), Encoding.UTF8);
            RunPs(tmp, "");
            try { File.Delete(tmp); } catch { }
        }

        static void RegisterUninstall(string installRoot)
        {
            var keyPath = @"Software\Microsoft\Windows\CurrentVersion\Uninstall\TheGoldMindProfessional";
            using var key = Microsoft.Win32.Registry.CurrentUser.CreateSubKey(keyPath);
            if (key == null) return;
            key.SetValue("DisplayName", ProductName);
            key.SetValue("Publisher", Publisher);
            key.SetValue("DisplayVersion", Version);
            key.SetValue("InstallLocation", installRoot);
            key.SetValue("InstallDate", DateTime.Now.ToString("yyyyMMdd"));
            key.SetValue("EstimatedSize", 4096);
            var uninst = "powershell.exe -NoProfile -ExecutionPolicy Bypass -Command \"Remove-Item -LiteralPath '" +
                         installRoot.Replace("'", "''") +
                         "' -Recurse -Force; Remove-Item -Path 'HKCU:\\" + keyPath.Replace("'", "''") + "' -Recurse -Force\"";
            key.SetValue("UninstallString", uninst);
            key.SetValue("NoModify", 1, Microsoft.Win32.RegistryValueKind.DWord);
            key.SetValue("NoRepair", 1, Microsoft.Win32.RegistryValueKind.DWord);
        }
    }
}
