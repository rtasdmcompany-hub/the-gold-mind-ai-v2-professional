THE GOLD MIND PROFESSIONAL — Installation package notes

This package delivers the commercial installer/updater shell only.

It does NOT modify:
- Trading Engine
- Strategy Logic
- Recovery Engine
- Risk Management
- Order Execution
- Magic Number Logic

Install:
  powershell -ExecutionPolicy Bypass -File ..\scripts\Install-TheGoldMindProfessional.ps1

Update:
  powershell -ExecutionPolicy Bypass -File ..\scripts\Update-TheGoldMindProfessional.ps1 -Apply

Owner: RTAS Group of Companies
