using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Drawing;
using System.IO;
using System.IO.Compression;
using System.Linq;
using System.Reflection;
using System.Security.Cryptography;
using System.Text;
using System.Windows.Forms;
using Microsoft.Win32;

namespace TgmProfessionalSetup
{
    internal static class Program
    {
        internal const string ProductName = "THE GOLD MIND PROFESSIONAL";
        internal const string Version = "1.0.0";
        internal const string Publisher = "RTAS Group of Companies";
        internal const string PortalBase = "https://the-gold-mind-ai-v2-professional.vercel.app";
        internal const string PortalLoginGoogle = PortalBase + "/login?provider=google&callbackUrl=%2Fportal%2Flicenses";

        [STAThread]
        static int Main(string[] args)
        {
            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);

            bool silent = args.Any(a =>
                a.Equals("/SILENT", StringComparison.OrdinalIgnoreCase) ||
                a.Equals("/VERYSILENT", StringComparison.OrdinalIgnoreCase));

            string installRoot = Path.Combine(
                Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
                ProductName);

            try
            {
                if (silent)
                {
                    Directory.CreateDirectory(installRoot);
                    InstallerCore.ExtractPayload(installRoot);
                    InstallerCore.CreateShortcuts(installRoot, createDesktop: false);
                    InstallerCore.RegisterUninstall(installRoot);
                    return 0;
                }

                Application.Run(new SetupWizardForm(installRoot));
                return SetupWizardForm.ExitCode;
            }
            catch (Exception ex)
            {
                MessageBox.Show("Setup failed:\n" + ex.Message, ProductName + " Setup",
                    MessageBoxButtons.OK, MessageBoxIcon.Error);
                return 2;
            }
        }
    }

    internal sealed class Mt5Terminal
    {
        public string Id;
        public string Path;
        public string Label;
        public string ExpertsPath;
        public override string ToString() { return Label; }
    }

    internal static class InstallerCore
    {
        public static void ExtractPayload(string installRoot)
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
                CopyDir(dir, Path.Combine(installRoot, Path.GetFileName(dir)));
            foreach (string file in Directory.GetFiles(tmpDir))
                File.Copy(file, Path.Combine(installRoot, Path.GetFileName(file)), true);

            try { File.Delete(tmpZip); } catch { }
            try { Directory.Delete(tmpDir, true); } catch { }

            // Always write production portal config (never thegoldmind.ai)
            string cfgDir = Path.Combine(installRoot, "config");
            Directory.CreateDirectory(cfgDir);
            File.WriteAllText(Path.Combine(cfgDir, "portal.json"),
                "{\n  \"portalBase\": \"" + Program.PortalBase + "\",\n  \"productId\": \"the-gold-mind-ai-v2-professional\"\n}\n",
                Encoding.UTF8);

            string ea = Path.Combine(installRoot, "ea", "TheGoldMindAI_Professional.ex5");
            if (!File.Exists(ea))
                throw new InvalidOperationException("EA binary missing after extract: " + ea);
        }

        public static List<Mt5Terminal> DetectMt5()
        {
            var list = new List<Mt5Terminal>();
            foreach (string root in new[]
            {
                Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData), "MetaQuotes", "Terminal"),
                Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "MetaQuotes", "Terminal")
            })
            {
                if (!Directory.Exists(root)) continue;
                foreach (string dir in Directory.GetDirectories(root))
                {
                    string experts = Path.Combine(dir, "MQL5", "Experts");
                    string label = Path.GetFileName(dir);
                    string origin = Path.Combine(dir, "origin.txt");
                    if (File.Exists(origin))
                    {
                        try { label = File.ReadAllText(origin).Trim(); } catch { }
                    }
                    list.Add(new Mt5Terminal
                    {
                        Id = Path.GetFileName(dir),
                        Path = dir,
                        Label = label + (Directory.Exists(experts) ? "" : " (no Experts yet)"),
                        ExpertsPath = experts
                    });
                }
            }
            foreach (string pf in new[]
            {
                Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ProgramFiles), "MetaTrader 5"),
                Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ProgramFilesX86), "MetaTrader 5")
            })
            {
                if (!Directory.Exists(pf)) continue;
                list.Add(new Mt5Terminal
                {
                    Id = "INSTALL_" + Guid.NewGuid().ToString("N").Substring(0, 8),
                    Path = pf,
                    Label = "Program Files: " + pf,
                    ExpertsPath = Path.Combine(pf, "MQL5", "Experts")
                });
            }
            return list.GroupBy(t => t.Path, StringComparer.OrdinalIgnoreCase).Select(g => g.First()).ToList();
        }

        public static string DeployEa(string installRoot, string terminalPath)
        {
            string src = Path.Combine(installRoot, "ea", "TheGoldMindAI_Professional.ex5");
            if (!File.Exists(src)) throw new InvalidOperationException("EA source missing: " + src);
            string destDir = Path.Combine(terminalPath, "MQL5", "Experts", "The Gold Mind");
            Directory.CreateDirectory(destDir);
            string dest = Path.Combine(destDir, "TheGoldMindAI_Professional.ex5");
            File.Copy(src, dest, true);
            string srcHash = Sha256(src);
            string dstHash = Sha256(dest);
            if (!string.Equals(srcHash, dstHash, StringComparison.OrdinalIgnoreCase))
                throw new InvalidOperationException("EA copy verification failed (SHA mismatch).");
            File.WriteAllText(Path.Combine(destDir, "INSTALL_VERIFY.json"),
                "{\n  \"product\": \"" + Program.ProductName + "\",\n  \"destination\": \"" + dest.Replace("\\", "\\\\") + "\",\n  \"eaSha256\": \"" + dstHash + "\",\n  \"installedAt\": \"" + DateTime.UtcNow.ToString("o") + "\"\n}\n",
                Encoding.UTF8);
            return dest;
        }

        public static string Sha256(string path)
        {
            using (var sha = SHA256.Create())
            using (var fs = File.OpenRead(path))
            {
                byte[] hash = sha.ComputeHash(fs);
                var sb = new StringBuilder(hash.Length * 2);
                foreach (byte b in hash) sb.Append(b.ToString("x2"));
                return sb.ToString();
            }
        }

        public static void CopyDir(string src, string dest)
        {
            Directory.CreateDirectory(dest);
            foreach (string file in Directory.GetFiles(src))
                File.Copy(file, Path.Combine(dest, Path.GetFileName(file)), true);
            foreach (string dir in Directory.GetDirectories(src))
                CopyDir(dir, Path.Combine(dest, Path.GetFileName(dir)));
        }

        public static void RunHiddenPs(string script, string args)
        {
            if (!File.Exists(script)) return;
            var psi = new ProcessStartInfo
            {
                FileName = "powershell.exe",
                Arguments = "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File \"" + script + "\" " + args,
                UseShellExecute = false,
                CreateNoWindow = true,
                WindowStyle = ProcessWindowStyle.Hidden
            };
            using (Process p = Process.Start(psi))
            {
                if (p != null) p.WaitForExit(120000);
            }
        }

        public static void CreateShortcuts(string installRoot, bool createDesktop)
        {
            string launcher = Path.Combine(installRoot, "bin", "TGM-Professional-Launcher.exe");
            if (!File.Exists(launcher))
                launcher = Path.Combine(installRoot, "bin", "TGM-Professional-Launcher.cmd");

            string startDir = Path.Combine(
                Environment.GetFolderPath(Environment.SpecialFolder.StartMenu),
                "Programs", Program.ProductName);
            Directory.CreateDirectory(startDir);

            WriteShortcut(Path.Combine(startDir, Program.ProductName + ".lnk"), launcher, installRoot, null);
            WriteShortcut(
                Path.Combine(startDir, "Activate License.lnk"),
                "powershell.exe",
                installRoot,
                "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File \"" + Path.Combine(installRoot, "scripts", "Activate-License.ps1") + "\" -InstallRoot \"" + installRoot + "\"");
            WriteShortcut(
                Path.Combine(startDir, "Open Customer Portal.lnk"),
                Program.PortalBase,
                installRoot,
                null);
            WriteShortcut(
                Path.Combine(startDir, "Deploy EA to MT5.lnk"),
                "powershell.exe",
                installRoot,
                "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File \"" + Path.Combine(installRoot, "scripts", "Deploy-EA-To-MT5.ps1") + "\" -InstallRoot \"" + installRoot + "\"");

            if (createDesktop)
            {
                string desk = Path.Combine(
                    Environment.GetFolderPath(Environment.SpecialFolder.DesktopDirectory),
                    Program.ProductName + ".lnk");
                WriteShortcut(desk, launcher, installRoot, null);
            }
        }

        static void WriteShortcut(string lnkPath, string target, string workDir, string args)
        {
            var ps = new StringBuilder();
            ps.AppendLine("$w = New-Object -ComObject WScript.Shell");
            ps.AppendLine("$s = $w.CreateShortcut('" + lnkPath.Replace("'", "''") + "')");
            ps.AppendLine("$s.TargetPath = '" + target.Replace("'", "''") + "'");
            if (!string.IsNullOrEmpty(args))
                ps.AppendLine("$s.Arguments = '" + args.Replace("'", "''") + "'");
            ps.AppendLine("$s.WorkingDirectory = '" + workDir.Replace("'", "''") + "'");
            ps.AppendLine("$s.Description = '" + Program.ProductName.Replace("'", "''") + "'");
            ps.AppendLine("$s.Save()");
            string tmp = Path.Combine(Path.GetTempPath(), "tgm-lnk-" + Guid.NewGuid().ToString("N") + ".ps1");
            File.WriteAllText(tmp, ps.ToString(), Encoding.UTF8);
            RunHiddenPs(tmp, "");
            try { File.Delete(tmp); } catch { }
        }

        public static void RegisterUninstall(string installRoot)
        {
            string keyPath = @"Software\Microsoft\Windows\CurrentVersion\Uninstall\TheGoldMindProfessional";
            using (RegistryKey key = Registry.CurrentUser.CreateSubKey(keyPath))
            {
                if (key == null) return;
                key.SetValue("DisplayName", Program.ProductName);
                key.SetValue("Publisher", Program.Publisher);
                key.SetValue("DisplayVersion", Program.Version);
                key.SetValue("InstallLocation", installRoot);
                key.SetValue("InstallDate", DateTime.Now.ToString("yyyyMMdd"));
                key.SetValue("EstimatedSize", 4096);
                key.SetValue("URLInfoAbout", Program.PortalBase);
                string uninst = "powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -Command \"Remove-Item -LiteralPath '" +
                                installRoot.Replace("'", "''") +
                                "' -Recurse -Force; Remove-Item -Path 'HKCU:\\" + keyPath.Replace("'", "''") + "' -Recurse -Force\"";
                key.SetValue("UninstallString", uninst);
                key.SetValue("NoModify", 1, RegistryValueKind.DWord);
                key.SetValue("NoRepair", 1, RegistryValueKind.DWord);
            }
        }
    }

    internal sealed class SetupWizardForm : Form
    {
        public static int ExitCode = 1;

        readonly string _defaultRoot;
        int _step;
        readonly Panel _body;
        readonly Label _title;
        readonly Label _subtitle;
        readonly Button _back;
        readonly Button _next;
        readonly Button _cancel;

        // Controls reused across steps
        CheckBox _acceptLicense;
        TextBox _folderBox;
        ListBox _terminalList;
        Label _progressLabel;
        ProgressBar _progressBar;
        CheckBox _optLaunch;
        CheckBox _optPortal;
        CheckBox _optActivate;
        CheckBox _optDesktop;
        string _installRoot;
        string _installedEaPath;

        public SetupWizardForm(string defaultRoot)
        {
            _defaultRoot = defaultRoot;
            _installRoot = defaultRoot;

            Text = Program.ProductName + " Setup";
            FormBorderStyle = FormBorderStyle.FixedDialog;
            MaximizeBox = false;
            MinimizeBox = false;
            StartPosition = FormStartPosition.CenterScreen;
            ClientSize = new Size(720, 480);
            BackColor = Color.FromArgb(10, 10, 12);
            ForeColor = Color.FromArgb(243, 239, 230);
            Font = new Font("Segoe UI", 9.5f);

            var header = new Panel
            {
                Dock = DockStyle.Top,
                Height = 78,
                BackColor = Color.FromArgb(14, 14, 16),
                Padding = new Padding(24, 16, 24, 12)
            };
            _title = new Label
            {
                AutoSize = false,
                Dock = DockStyle.Top,
                Height = 28,
                Font = new Font("Segoe UI Semibold", 14f),
                ForeColor = Color.FromArgb(212, 188, 130),
                Text = "Welcome"
            };
            _subtitle = new Label
            {
                AutoSize = false,
                Dock = DockStyle.Top,
                Height = 22,
                ForeColor = Color.FromArgb(180, 175, 165),
                Text = Program.ProductName + " · " + Program.Publisher
            };
            header.Controls.Add(_subtitle);
            header.Controls.Add(_title);

            _body = new Panel
            {
                Dock = DockStyle.Fill,
                Padding = new Padding(28, 16, 28, 16)
            };

            var footer = new Panel
            {
                Dock = DockStyle.Bottom,
                Height = 64,
                BackColor = Color.FromArgb(14, 14, 16),
                Padding = new Padding(20, 12, 20, 12)
            };
            _cancel = MakeBtn("Cancel", false);
            _back = MakeBtn("Back", false);
            _next = MakeBtn("Next", true);
            _cancel.Click += (s, e) => { ExitCode = 1; Close(); };
            _back.Click += (s, e) => { if (_step > 0) { _step--; RenderStep(); } };
            _next.Click += (s, e) => OnNext();
            footer.Controls.Add(_cancel);
            footer.Controls.Add(_back);
            footer.Controls.Add(_next);
            _cancel.Left = 20; _cancel.Top = 14;
            _back.Left = ClientSize.Width - 280; _back.Top = 14;
            _next.Left = ClientSize.Width - 150; _next.Top = 14;

            Controls.Add(_body);
            Controls.Add(footer);
            Controls.Add(header);

            RenderStep();
        }

        Button MakeBtn(string text, bool primary)
        {
            var b = new Button
            {
                Text = text,
                Width = 110,
                Height = 34,
                FlatStyle = FlatStyle.Flat,
                Cursor = Cursors.Hand,
                Font = new Font("Segoe UI Semibold", 9f)
            };
            if (primary)
            {
                b.BackColor = Color.FromArgb(184, 155, 95);
                b.ForeColor = Color.FromArgb(10, 10, 12);
                b.FlatAppearance.BorderSize = 0;
            }
            else
            {
                b.BackColor = Color.FromArgb(28, 28, 32);
                b.ForeColor = Color.FromArgb(243, 239, 230);
                b.FlatAppearance.BorderColor = Color.FromArgb(60, 60, 66);
            }
            return b;
        }

        void RenderStep()
        {
            _body.Controls.Clear();
            _back.Enabled = _step > 0 && _step < 5;
            _next.Enabled = true;
            _next.Text = _step == 4 ? "Install" : (_step == 5 ? "Finish" : "Next");
            _cancel.Visible = _step < 5;

            switch (_step)
            {
                case 0: RenderWelcome(); break;
                case 1: RenderLicense(); break;
                case 2: RenderFolder(); break;
                case 3: RenderMt5(); break;
                case 4: RenderProgress(); break;
                case 5: RenderFinish(); break;
            }
        }

        void RenderWelcome()
        {
            _title.Text = "Welcome";
            _subtitle.Text = "Commercial installer · Core Trading Engine is never modified";
            var l = new Label
            {
                AutoSize = false,
                Dock = DockStyle.Fill,
                Text =
                    "This wizard installs THE GOLD MIND PROFESSIONAL commercial package.\n\n" +
                    "• Windows commercial shell & shortcuts\n" +
                    "• Certified Expert Advisor binary (copy only)\n" +
                    "• MetaTrader 5 detection & deployment\n" +
                    "• Customer Portal licensing\n\n" +
                    "Portal:\n" + Program.PortalBase + "\n\n" +
                    "Click Next to continue."
            };
            _body.Controls.Add(l);
        }

        void RenderLicense()
        {
            _title.Text = "License Agreement";
            _subtitle.Text = "Please review and accept to continue";
            var box = new TextBox
            {
                Multiline = true,
                ReadOnly = true,
                ScrollBars = ScrollBars.Vertical,
                Dock = DockStyle.Top,
                Height = 260,
                BackColor = Color.FromArgb(20, 20, 24),
                ForeColor = Color.FromArgb(220, 215, 205),
                BorderStyle = BorderStyle.FixedSingle,
                Text =
                    "END-USER LICENSE AGREEMENT (SUMMARY)\n\n" +
                    "THE GOLD MIND PROFESSIONAL is licensed software from RTAS Group of Companies.\n\n" +
                    "• Trading involves substantial risk of loss.\n" +
                    "• Past performance is not indicative of future results.\n" +
                    "• The Core Trading Engine binary is certified and must not be reverse engineered.\n" +
                    "• License entitlement is managed via the Customer Portal.\n" +
                    "• Unauthorized redistribution is prohibited.\n\n" +
                    "Full terms: " + Program.PortalBase + "/terms\n" +
                    "Risk disclosure: " + Program.PortalBase + "/risk"
            };
            _acceptLicense = new CheckBox
            {
                Text = "I accept the license agreement",
                AutoSize = true,
                Top = 280,
                Left = 0,
                ForeColor = Color.FromArgb(243, 239, 230)
            };
            _body.Controls.Add(_acceptLicense);
            _body.Controls.Add(box);
        }

        void RenderFolder()
        {
            _title.Text = "Installation Folder";
            _subtitle.Text = "Choose where to install the commercial package";
            var lbl = new Label { Text = "Destination folder", AutoSize = true, Top = 8, Left = 0 };
            _folderBox = new TextBox
            {
                Text = _installRoot,
                Left = 0,
                Top = 36,
                Width = 520,
                BackColor = Color.FromArgb(20, 20, 24),
                ForeColor = Color.FromArgb(243, 239, 230),
                BorderStyle = BorderStyle.FixedSingle
            };
            var browse = MakeBtn("Browse…", false);
            browse.Left = 540; browse.Top = 32; browse.Width = 100;
            browse.Click += (s, e) =>
            {
                using (var d = new FolderBrowserDialog())
                {
                    d.SelectedPath = _folderBox.Text;
                    if (d.ShowDialog(this) == DialogResult.OK)
                        _folderBox.Text = d.SelectedPath;
                }
            };
            _optDesktop = new CheckBox
            {
                Text = "Create Desktop shortcut",
                Checked = true,
                AutoSize = true,
                Top = 90,
                Left = 0
            };
            _body.Controls.Add(lbl);
            _body.Controls.Add(_folderBox);
            _body.Controls.Add(browse);
            _body.Controls.Add(_optDesktop);
        }

        void RenderMt5()
        {
            _title.Text = "Detect MetaTrader 5";
            _subtitle.Text = "Select a terminal for Expert Advisor deployment";
            var refresh = MakeBtn("Refresh", false);
            refresh.Left = 0; refresh.Top = 0;
            _terminalList = new ListBox
            {
                Left = 0,
                Top = 48,
                Width = 640,
                Height = 220,
                BackColor = Color.FromArgb(20, 20, 24),
                ForeColor = Color.FromArgb(243, 239, 230),
                BorderStyle = BorderStyle.FixedSingle
            };
            Action load = () =>
            {
                _terminalList.Items.Clear();
                foreach (var t in InstallerCore.DetectMt5())
                    _terminalList.Items.Add(t);
                if (_terminalList.Items.Count > 0) _terminalList.SelectedIndex = 0;
            };
            refresh.Click += (s, e) => load();
            load();
            var hint = new Label
            {
                AutoSize = false,
                Left = 0,
                Top = 280,
                Width = 640,
                Height = 40,
                ForeColor = Color.FromArgb(180, 175, 165),
                Text = "If no terminal is listed, open MetaTrader 5 once, then click Refresh. You can also skip and deploy later from the Start Menu."
            };
            _body.Controls.Add(refresh);
            _body.Controls.Add(_terminalList);
            _body.Controls.Add(hint);
        }

        void RenderProgress()
        {
            _title.Text = "Installing";
            _subtitle.Text = "Please wait while files are deployed";
            _progressLabel = new Label { AutoSize = true, Top = 40, Left = 0, Text = "Preparing…" };
            _progressBar = new ProgressBar
            {
                Left = 0,
                Top = 80,
                Width = 640,
                Height = 22,
                Minimum = 0,
                Maximum = 100,
                Value = 5,
                Style = ProgressBarStyle.Continuous
            };
            _body.Controls.Add(_progressLabel);
            _body.Controls.Add(_progressBar);
            _back.Enabled = false;
            _next.Enabled = false;
            BeginInvoke(new Action(RunInstall));
        }

        void RenderFinish()
        {
            _title.Text = "Completed";
            _subtitle.Text = "Installation finished successfully";
            var done = new Label
            {
                AutoSize = false,
                Dock = DockStyle.Top,
                Height = 70,
                Text = "THE GOLD MIND PROFESSIONAL is installed.\nLocation: " + _installRoot +
                        (_installedEaPath != null ? "\nEA deployed: " + _installedEaPath : "\nEA deploy can be completed from Start Menu.")
            };
            _optLaunch = new CheckBox { Text = "Launch THE GOLD MIND", Checked = true, AutoSize = true, Top = 90, Left = 0 };
            _optPortal = new CheckBox { Text = "Open Customer Portal", Checked = true, AutoSize = true, Top = 120, Left = 0 };
            _optActivate = new CheckBox { Text = "Activate License", Checked = true, AutoSize = true, Top = 150, Left = 0 };
            _body.Controls.Add(done);
            _body.Controls.Add(_optLaunch);
            _body.Controls.Add(_optPortal);
            _body.Controls.Add(_optActivate);
        }

        void OnNext()
        {
            if (_step == 1)
            {
                if (_acceptLicense == null || !_acceptLicense.Checked)
                {
                    MessageBox.Show(this, "Please accept the license agreement to continue.", Text,
                        MessageBoxButtons.OK, MessageBoxIcon.Information);
                    return;
                }
            }
            if (_step == 2)
            {
                _installRoot = (_folderBox.Text ?? "").Trim();
                if (string.IsNullOrWhiteSpace(_installRoot))
                {
                    MessageBox.Show(this, "Choose an installation folder.", Text,
                        MessageBoxButtons.OK, MessageBoxIcon.Information);
                    return;
                }
            }
            if (_step == 5)
            {
                FinishActions();
                ExitCode = 0;
                Close();
                return;
            }
            if (_step < 5)
            {
                _step++;
                RenderStep();
            }
        }

        void RunInstall()
        {
            try
            {
                SetProgress(10, "Creating install directory…");
                Directory.CreateDirectory(_installRoot);

                SetProgress(30, "Extracting commercial package…");
                InstallerCore.ExtractPayload(_installRoot);

                SetProgress(55, "Deploying Expert Advisor…");
                if (_terminalList != null && _terminalList.SelectedItem is Mt5Terminal term)
                {
                    _installedEaPath = InstallerCore.DeployEa(_installRoot, term.Path);
                }

                SetProgress(75, "Creating shortcuts…");
                bool desk = _optDesktop == null || _optDesktop.Checked;
                InstallerCore.CreateShortcuts(_installRoot, desk);

                SetProgress(90, "Registering uninstall…");
                InstallerCore.RegisterUninstall(_installRoot);

                SetProgress(100, "Installation complete.");
                _step = 5;
                RenderStep();
            }
            catch (Exception ex)
            {
                MessageBox.Show(this, "Installation failed:\n" + ex.Message, Text,
                    MessageBoxButtons.OK, MessageBoxIcon.Error);
                ExitCode = 2;
                Close();
            }
        }

        void SetProgress(int value, string text)
        {
            if (_progressBar != null) _progressBar.Value = Math.Max(0, Math.Min(100, value));
            if (_progressLabel != null) _progressLabel.Text = text;
            Application.DoEvents();
        }

        void FinishActions()
        {
            if (_optPortal != null && _optPortal.Checked)
            {
                try { Process.Start(new ProcessStartInfo(Program.PortalBase) { UseShellExecute = true }); } catch { }
            }
            if (_optActivate != null && _optActivate.Checked)
            {
                try { Process.Start(new ProcessStartInfo(Program.PortalLoginGoogle) { UseShellExecute = true }); } catch { }
                string act = Path.Combine(_installRoot, "scripts", "Activate-License.ps1");
                InstallerCore.RunHiddenPs(act, "-InstallRoot \"" + _installRoot + "\" -GoogleLogin");
            }
            if (_optLaunch != null && _optLaunch.Checked)
            {
                string launcher = Path.Combine(_installRoot, "bin", "TGM-Professional-Launcher.exe");
                if (File.Exists(launcher))
                {
                    try { Process.Start(new ProcessStartInfo(launcher) { UseShellExecute = true }); } catch { }
                }
            }
        }
    }
}
