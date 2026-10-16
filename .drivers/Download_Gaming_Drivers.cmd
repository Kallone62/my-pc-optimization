@echo off
setlocal EnableExtensions DisableDelayedExpansion
title SSD Setup - Driver Download and Verify Only
set "SCRIPT=%~dp0Install-Gaming-Drivers-v2-LatestOfficial.ps1"
if not exist "%SCRIPT%" (echo ERROR: Missing script: "%SCRIPT%" & pause & exit /b 2)
echo ====================================================
echo   DRIVER DOWNLOAD + VERIFY ONLY - NO INSTALLATION
echo ====================================================
"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT%"
set "RC=%ERRORLEVEL%"
echo.
echo Downloads: "%~dp0..\Downloads\Drivers"
echo Logs:      "%~dp0..\Logs\Drivers"
echo Exit code: %RC%
pause
exit /b %RC%
