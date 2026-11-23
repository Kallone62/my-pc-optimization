@echo off
setlocal EnableExtensions DisableDelayedExpansion
title Microsoft Visual C++ All-in-One
set "SCRIPT=%~dp0Install_All_VisualCpp.ps1"
if not exist "%SCRIPT%" (echo [ERROR] Missing "%SCRIPT%" & pause & exit /b 2)
echo Run this CMD as Administrator after all 12 runtime downloads are READY.
"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT%"
set "RC=%ERRORLEVEL%"
echo.
echo Exit code: %RC%
pause
exit /b %RC%
