using System;
using System.Diagnostics;
using System.Drawing;
using System.IO;
using System.Text;
using System.Windows.Forms;
using Microsoft.Win32;

namespace TgmProfessionalLauncher
{
    internal static class Program
    {
        internal const string ProductName = "THE GOLD MIND PROFESSIONAL";
        internal const string UninstallRegistryValueName = "TheGoldMindProfessional";

        static readonly string[] BrokerMarkers = new string[]
        {
            "exness", "ftmo", "xm global", "xm.com", "ic markets", "icmarkets",
            "pepperstone", "roboforex", "fxpro", "tickmill"
        };

        internal static string InstallRoot
        {
            get
            {
                string appDir = AppDomain.CurrentDomain.BaseDirectory;
                return Path.GetFullPath(Path.Combine(appDir, ".."));
            }
        }

        static bool IsMetaQuotesOfficialExe(string exePath)
        {
            if (string.IsNullOrEmpty(exePath) || !File.Exists(exePath)) return false;
            string lowerPath = exePath.ToLowerInvariant();
            foreach (string m in BrokerMarkers)
                if (lowerPath.IndexOf(m, StringComparison.Ordinal) >= 0) return false;
            try
            {
                FileVersionInfo vi = FileVersionInfo.GetVersionInfo(exePath);
                string blob = ((vi.CompanyName ?? "") + " " + (vi.ProductName ?? "") + " " +
                               (vi.FileDescription ?? "")).ToLowerInvariant();
                foreach (string m in BrokerMarkers)
                    if (blob.IndexOf(m, StringComparison.Ordinal) >= 0) return false;
                return blob.IndexOf("metaquotes", StringComparison.Ordinal) >= 0;
            }
            catch { return false; }
        }

        internal static string FindOfficialMt5()
        {
            string[] dirs = new string[]
            {
                Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ProgramFiles), "MetaTrader 5"),
                Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ProgramFilesX86), "MetaTrader 5")
            };
            foreach (string dir in dirs)
            {
                foreach (string name in new[] { "terminal64.exe", "terminal.exe" })
                {
                    string exe = Path.Combine(dir, name);
                    if (IsMetaQuotesOfficialExe(exe)) return exe;
                }
            }
            return null;
        }

        internal static string ReadVersion()
        {
            string versionFile = Path.Combine(InstallRoot, "config", "version.json");
            string version = "1.0.0";
            if (!File.Exists(versionFile)) return version;
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
            return version;
        }

        internal static string ReadPortalBase()
        {
            string portalFile = Path.Combine(InstallRoot, "config", "portal.json");
            string fallback = "https://the-gold-mind-ai-v2-professional.vercel.app";
            if (!File.Exists(portalFile)) return fallback;
            try
            {
                string txt = File.ReadAllText(portalFile);
                int idx = txt.IndexOf("\"portalBase\"", StringComparison.OrdinalIgnoreCase);
                if (idx < 0) return fallback;
                int colon = txt.IndexOf(':', idx);
                int q1 = txt.IndexOf('"', colon + 1);
                int q2 = txt.IndexOf('"', q1 + 1);
                if (q1 > 0 && q2 > q1) return txt.Substring(q1 + 1, q2 - q1 - 1);
            }
            catch { }
            return fallback;
        }

        internal static string QuoteArg(string s)
        {
            if (s == null) s = "";
            return "\"" + s.Replace("\"", "\\\"") + "\"";
        }

        internal static int RunHiddenScript(string scriptName, string extraArgs)
        {
            string script = Path.Combine(InstallRoot, "scripts", scriptName);
            if (!File.Exists(script))
                throw new FileNotFoundException("Required helper not found: " + scriptName, script);

            string args = "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File \"" + script +
                          "\" -InstallRoot \"" + InstallRoot + "\"";
            if (!string.IsNullOrEmpty(extraArgs))
                args += " " + extraArgs;

            ProcessStartInfo psi = new ProcessStartInfo
            {
                FileName = "powershell.exe",
                Arguments = args,
                UseShellExecute = false,
                CreateNoWindow = true,
                WindowStyle = ProcessWindowStyle.Hidden,
                WorkingDirectory = InstallRoot
            };
            using (Process p = Process.Start(psi))
            {
                if (p == null) return -1;
                p.WaitForExit(180000);
                return p.ExitCode;
            }
        }

        internal static void RunDetachedHidden(string fileName, string arguments)
        {
            ProcessStartInfo psi = new ProcessStartInfo
            {
                FileName = fileName,
                Arguments = arguments,
                UseShellExecute = false,
                CreateNoWindow = true,
                WindowStyle = ProcessWindowStyle.Hidden
            };
            Process.Start(psi);
        }

        /// <summary>
        /// Removes the commercial shell (Start Menu / Desktop shortcuts, uninstall registry
        /// entry, and the install folder). Never touches Customer Portal license state or
        /// any file already deployed into a MetaTrader 5 terminal - those are independent of
        /// this shell and are left alone. Called both from the launcher UI and from
        /// "Apps & Features" via Main(string[]) with the /uninstall switch.
        /// </summary>
        internal static bool Uninstall(bool silent)
        {
            if (!silent)
            {
                DialogResult confirm = MessageBox.Show(
                    "This will remove " + ProductName + " from this computer.\n\n" +
                    "Your license activation on the Customer Portal and any EA already deployed " +
                    "into MetaTrader 5 are not affected.\n\n" +
                    "Continue?",
                    "Uninstall " + ProductName,
                    MessageBoxButtons.YesNo,
                    MessageBoxIcon.Warning);
                if (confirm != DialogResult.Yes) return false;
            }

            string installRoot = InstallRoot;

            try
            {
                using (RegistryKey uninstallRoot = Registry.CurrentUser.OpenSubKey(
                    @"Software\Microsoft\Windows\CurrentVersion\Uninstall", true))
                {
                    if (uninstallRoot != null)
                        uninstallRoot.DeleteSubKeyTree(UninstallRegistryValueName, false);
                }
            }
            catch { }

            try
            {
                string startDir = Path.Combine(
                    Environment.GetFolderPath(Environment.SpecialFolder.StartMenu),
                    "Programs", ProductName);
                if (Directory.Exists(startDir)) Directory.Delete(startDir, true);
            }
            catch { }

            try
            {
                string desk = Path.Combine(
                    Environment.GetFolderPath(Environment.SpecialFolder.DesktopDirectory),
                    ProductName + ".lnk");
                if (File.Exists(desk)) File.Delete(desk);
            }
            catch { }

            // The launcher exe itself lives under installRoot\bin, so the folder can only be
            // removed after this process exits. Hand off cleanup to a short-lived hidden
            // PowerShell process that waits, deletes the install folder, then deletes itself.
            try
            {
                string escapedRoot = installRoot.Replace("'", "''");
                string tmp = Path.Combine(Path.GetTempPath(), "tgm-uninstall-" + Guid.NewGuid().ToString("N") + ".ps1");
                string escapedTmp = tmp.Replace("'", "''");
                StringBuilder ps = new StringBuilder();
                ps.AppendLine("Start-Sleep -Seconds 2");
                ps.AppendLine("try { Remove-Item -LiteralPath '" + escapedRoot + "' -Recurse -Force -ErrorAction SilentlyContinue } catch { }");
                ps.AppendLine("try { Remove-Item -LiteralPath '" + escapedTmp + "' -Force -ErrorAction SilentlyContinue } catch { }");
                File.WriteAllText(tmp, ps.ToString(), Encoding.UTF8);
                RunDetachedHidden("powershell.exe",
                    "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File \"" + tmp + "\"");
            }
            catch { }

            if (!silent)
            {
                MessageBox.Show(
                    ProductName + " has been uninstalled.",
                    ProductName,
                    MessageBoxButtons.OK,
                    MessageBoxIcon.Information);
            }
            return true;
        }

        [STAThread]
        static void Main(string[] args)
        {
            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);

            bool uninstall = false;
            if (args != null)
            {
                foreach (string a in args)
                {
                    if (string.Equals(a, "/uninstall", StringComparison.OrdinalIgnoreCase) ||
                        string.Equals(a, "-uninstall", StringComparison.OrdinalIgnoreCase) ||
                        string.Equals(a, "/UNINSTALL", StringComparison.OrdinalIgnoreCase))
                    {
                        uninstall = true;
                        break;
                    }
                }
            }

            if (uninstall)
            {
                // Invoked from Windows "Apps & Features" (UninstallString). No main window.
                Uninstall(false);
                return;
            }

            Application.Run(new LauncherForm());
        }
    }

    internal sealed class LauncherForm : Form
    {
        readonly Label _status;

        public LauncherForm()
        {
            Text = "THE GOLD MIND PROFESSIONAL";
            FormBorderStyle = FormBorderStyle.FixedDialog;
            MaximizeBox = false;
            MinimizeBox = false;
            StartPosition = FormStartPosition.CenterScreen;
            ClientSize = new Size(460, 370);
            BackColor = Color.FromArgb(12, 10, 8);
            ForeColor = Color.FromArgb(230, 220, 200);
            Font = new Font("Segoe UI", 9F);

            Label title = new Label
            {
                Text = "THE GOLD MIND PROFESSIONAL",
                ForeColor = Color.FromArgb(198, 168, 86),
                Font = new Font("Segoe UI Semibold", 12F),
                Location = new Point(24, 18),
                AutoSize = true
            };
            Label version = new Label
            {
                Text = "Version " + Program.ReadVersion() + "  \u2022  Commercial Edition",
                ForeColor = Color.FromArgb(160, 150, 120),
                Location = new Point(24, 46),
                AutoSize = true
            };
            Label hint = new Label
            {
                Text = "Use the actions below. Helper scripts run hidden - no customer console windows.",
                ForeColor = Color.FromArgb(140, 130, 110),
                Location = new Point(24, 72),
                Size = new Size(410, 32)
            };

            Button activate = MakeButton("Activate License", 24, 112, false);
            activate.Click += (s, e) => ActivateLicense();

            Button portal = MakeButton("Open Customer Portal", 240, 112, false);
            portal.Click += (s, e) =>
            {
                try { Process.Start(new ProcessStartInfo(Program.ReadPortalBase()) { UseShellExecute = true }); }
                catch (Exception ex) { MessageBox.Show(ex.Message, Text, MessageBoxButtons.OK, MessageBoxIcon.Warning); }
            };

            Button deploy = MakeButton("Deploy EA to MetaTrader 5", 24, 152, false);
            deploy.Click += (s, e) => RunAction("Deploy EA", () =>
            {
                int code = Program.RunHiddenScript("Deploy-EA-To-MT5.ps1", "-Silent");
                if (code != 0) throw new Exception("EA deploy did not complete (code " + code + ").");
            });

            Button mt5 = MakeButton("Open MetaTrader 5", 240, 152, false);
            mt5.Click += (s, e) => OpenMt5();

            Button firstRun = MakeButton("First-Run Guide", 24, 192, false);
            firstRun.Click += (s, e) => OpenFirstRunGuide();

            Button uninstallBtn = MakeButton("Uninstall", 240, 192, true);
            uninstallBtn.Click += (s, e) =>
            {
                if (Program.Uninstall(false)) Close();
            };

            Button close = MakeButton("Close", 240, 280, false);
            close.Click += (s, e) => Close();

            _status = new Label
            {
                Text = "Ready.",
                ForeColor = Color.FromArgb(140, 200, 160),
                Location = new Point(24, 232),
                Size = new Size(410, 40)
            };

            Controls.Add(title);
            Controls.Add(version);
            Controls.Add(hint);
            Controls.Add(activate);
            Controls.Add(portal);
            Controls.Add(deploy);
            Controls.Add(mt5);
            Controls.Add(firstRun);
            Controls.Add(uninstallBtn);
            Controls.Add(close);
            Controls.Add(_status);
        }

        Button MakeButton(string text, int x, int y, bool danger)
        {
            return new Button
            {
                Text = text,
                Location = new Point(x, y),
                Size = new Size(196, 32),
                FlatStyle = FlatStyle.Flat,
                BackColor = danger ? Color.FromArgb(58, 28, 24) : Color.FromArgb(45, 38, 22),
                ForeColor = danger ? Color.FromArgb(235, 190, 170) : Color.FromArgb(230, 220, 200),
                Cursor = Cursors.Hand
            };
        }

        void RunAction(string name, Action work)
        {
            _status.ForeColor = Color.FromArgb(198, 168, 86);
            _status.Text = name + " in progress...";
            Refresh();
            try
            {
                work();
                _status.ForeColor = Color.FromArgb(140, 200, 160);
                _status.Text = name + " completed.";
                MessageBox.Show(name + " completed successfully.", Text, MessageBoxButtons.OK, MessageBoxIcon.Information);
            }
            catch (Exception ex)
            {
                _status.ForeColor = Color.FromArgb(220, 120, 100);
                _status.Text = name + " failed.";
                MessageBox.Show(ex.Message, Text, MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
        }

        void ActivateLicense()
        {
            using (ActivateLicenseDialog dlg = new ActivateLicenseDialog())
            {
                if (dlg.ShowDialog(this) != DialogResult.OK) return;
                string email = dlg.Email;
                string key = dlg.LicenseKey;
                RunAction("Activate License", () =>
                {
                    string extraArgs = "-Silent -Email " + Program.QuoteArg(email) +
                                       " -LicenseKey " + Program.QuoteArg(key);
                    int code = Program.RunHiddenScript("Activate-License.ps1", extraArgs);
                    if (code != 0) throw new Exception("License activation did not complete (code " + code + ").");
                });
            }
        }

        void OpenFirstRunGuide()
        {
            string doc = Path.Combine(Program.InstallRoot, "docs", "FIRST_RUN.txt");
            try
            {
                if (File.Exists(doc))
                {
                    Process.Start(new ProcessStartInfo(doc) { UseShellExecute = true });
                }
                else
                {
                    MessageBox.Show(
                        "First-run guide not found:\n" + doc,
                        Text, MessageBoxButtons.OK, MessageBoxIcon.Warning);
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show(ex.Message, Text, MessageBoxButtons.OK, MessageBoxIcon.Warning);
            }
        }

        void OpenMt5()
        {
            string exe = Program.FindOfficialMt5();
            if (exe != null)
            {
                Process.Start(new ProcessStartInfo(exe)
                {
                    UseShellExecute = true,
                    WorkingDirectory = Path.GetDirectoryName(exe)
                });
                _status.Text = "MetaTrader 5 launched.";
                return;
            }
            MessageBox.Show(
                "Official MetaTrader 5 (MetaQuotes) was not found.\n\n" +
                "Broker terminals are never opened by this launcher.\n\n" +
                "Install from https://www.metatrader5.com/en/download",
                Text,
                MessageBoxButtons.OK,
                MessageBoxIcon.Warning);
            try
            {
                Process.Start(new ProcessStartInfo("https://www.metatrader5.com/en/download") { UseShellExecute = true });
            }
            catch { }
        }
    }

    internal sealed class ActivateLicenseDialog : Form
    {
        readonly TextBox _email;
        readonly TextBox _key;

        internal string Email { get { return _email.Text.Trim(); } }
        internal string LicenseKey { get { return _key.Text.Trim(); } }

        public ActivateLicenseDialog()
        {
            Text = "Activate License";
            FormBorderStyle = FormBorderStyle.FixedDialog;
            MaximizeBox = false;
            MinimizeBox = false;
            ShowInTaskbar = false;
            StartPosition = FormStartPosition.CenterParent;
            ClientSize = new Size(380, 226);
            BackColor = Color.FromArgb(12, 10, 8);
            ForeColor = Color.FromArgb(230, 220, 200);
            Font = new Font("Segoe UI", 9F);

            Label heading = new Label
            {
                Text = "Enter your Customer Portal credentials",
                ForeColor = Color.FromArgb(198, 168, 86),
                Font = new Font("Segoe UI Semibold", 10F),
                Location = new Point(20, 16),
                AutoSize = true
            };

            Label emailLabel = new Label { Text = "Customer email (portal login)", Location = new Point(20, 54), AutoSize = true };
            _email = new TextBox
            {
                Location = new Point(20, 74),
                Size = new Size(340, 24),
                BackColor = Color.FromArgb(30, 26, 18),
                ForeColor = Color.FromArgb(230, 220, 200),
                BorderStyle = BorderStyle.FixedSingle
            };

            Label keyLabel = new Label { Text = "License key (from portal)", Location = new Point(20, 108), AutoSize = true };
            _key = new TextBox
            {
                Location = new Point(20, 128),
                Size = new Size(340, 24),
                BackColor = Color.FromArgb(30, 26, 18),
                ForeColor = Color.FromArgb(230, 220, 200),
                BorderStyle = BorderStyle.FixedSingle
            };

            Button ok = new Button
            {
                Text = "Activate",
                Location = new Point(164, 174),
                Size = new Size(96, 32),
                FlatStyle = FlatStyle.Flat,
                BackColor = Color.FromArgb(45, 38, 22),
                ForeColor = Color.FromArgb(230, 220, 200),
                Cursor = Cursors.Hand
            };
            ok.Click += (s, e) =>
            {
                if (string.IsNullOrWhiteSpace(_email.Text) || string.IsNullOrWhiteSpace(_key.Text))
                {
                    MessageBox.Show("Email and license key are both required.", Text, MessageBoxButtons.OK, MessageBoxIcon.Warning);
                    return;
                }
                DialogResult = DialogResult.OK;
                Close();
            };

            Button cancel = new Button
            {
                Text = "Cancel",
                Location = new Point(264, 174),
                Size = new Size(96, 32),
                FlatStyle = FlatStyle.Flat,
                BackColor = Color.FromArgb(45, 38, 22),
                ForeColor = Color.FromArgb(230, 220, 200),
                Cursor = Cursors.Hand
            };
            cancel.Click += (s, e) =>
            {
                DialogResult = DialogResult.Cancel;
                Close();
            };

            AcceptButton = ok;
            CancelButton = cancel;

            Controls.Add(heading);
            Controls.Add(emailLabel);
            Controls.Add(_email);
            Controls.Add(keyLabel);
            Controls.Add(_key);
            Controls.Add(ok);
            Controls.Add(cancel);
        }
    }
}
