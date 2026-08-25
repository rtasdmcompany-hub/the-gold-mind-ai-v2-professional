# Authenticode workflow

## Modes
- unsigned - local/dev (default)
- standard - Standard Code Signing Certificate
- ev - EV Code Signing Certificate

## Commands
signtool sign /fd SHA256 /td SHA256 /tr http://timestamp.digicert.com /sha1 THUMBPRINT path\Setup.exe
signtool sign /fd SHA256 /td SHA256 /tr http://timestamp.digicert.com /f cert.pfx /p PASSWORD path\Setup.exe
signtool verify /pa /v path\Setup.exe

## Build
.\Build-CommercialRelease.ps1 -SignMode standard -SignThumbprint <THUMBPRINT>
.\Build-CommercialRelease.ps1 -SignMode ev -SignCertPath .\ev.pfx -SignCertPassword <SECRET>
