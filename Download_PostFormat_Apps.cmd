@echo off
setlocal EnableExtensions DisableDelayedExpansion
title SSD Setup - Application Download and Verify Only
set "PACK_ROOT=%~dp0"
set "SCRIPT=%PACK_ROOT%.scripts\Install-PostFormat-Apps.ps1"
if not exist "%SCRIPT%" (echo ERROR: Missing script: "%SCRIPT%" & pause & exit /b 2)
echo ====================================================
echo   APPLICATION DOWNLOAD + VERIFY ONLY - NO INSTALL
echo ====================================================
"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT%"
set "RC=%ERRORLEVEL%"
echo.
echo Downloads: "%PACK_ROOT%Downloads\Apps"
echo Logs:      "%PACK_ROOT%Logs\PostFormat"
echo Exit code: %RC%
pause
exit /b %RC%
