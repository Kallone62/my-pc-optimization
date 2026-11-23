@echo off
setlocal EnableExtensions DisableDelayedExpansion
title Driver and App Downloaders - PowerShell Parser Check

for %%I in ("%~dp0..") do set "REPO_ROOT=%%~fI"
set "POWERSHELL_EXE=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"
if not exist "%POWERSHELL_EXE%" (
    echo [ERROR] Windows PowerShell 5.1 is missing.
    pause
    exit /b 2
)

"%POWERSHELL_EXE%" -NoLogo -NoProfile -ExecutionPolicy Bypass -Command ^
  "$files=@((Join-Path $env:REPO_ROOT '.drivers\Download-Gaming-Drivers.ps1'),(Join-Path $env:REPO_ROOT '.scripts\Download-PostFormat-Apps.ps1'),(Join-Path $env:REPO_ROOT '.scripts\Download-Transport.ps1')); $failed=$false; foreach($file in $files){ if(-not (Test-Path -LiteralPath $file -PathType Leaf)){ Write-Host ('MISSING: '+$file) -ForegroundColor Red; $failed=$true; continue }; $tokens=$null; $errors=$null; [void][System.Management.Automation.Language.Parser]::ParseFile($file,[ref]$tokens,[ref]$errors); if($errors.Count -gt 0){ Write-Host ('FAILED: '+$file) -ForegroundColor Red; foreach($item in $errors){ Write-Host ('  line {0}: {1}' -f $item.Extent.StartLineNumber,$item.Message) }; $failed=$true } else { Write-Host ('OK: '+$file) -ForegroundColor Green } }; if($failed){exit 1}else{exit 0}"
set "RC=%ERRORLEVEL%"
echo.
pause
exit /b %RC%
