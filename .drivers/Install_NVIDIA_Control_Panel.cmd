@echo off
setlocal EnableExtensions DisableDelayedExpansion
title NVIDIA Control Panel - Microsoft Store installer

echo ====================================================
echo   NVIDIA CONTROL PANEL - MICROSOFT STORE
echo ====================================================
echo.
echo Run after manually installing the NVIDIA RTX 3080 display driver.
echo The Microsoft Store app will be installed for the current Windows user.
echo.

set "PS=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"
if not exist "%PS%" (
    echo [ERROR] Windows PowerShell not found.
    goto :fail
)

rem Require the correct NVIDIA display driver, not just an NVIDIA PCI device.
"%PS%" -NoLogo -NoProfile -Command "$d = @(Get-CimInstance Win32_PnPSignedDriver -ErrorAction SilentlyContinue | Where-Object { $_.DeviceClass -eq 'DISPLAY' -and $_.DeviceID -match 'VEN_10DE&DEV_220A' -and $_.DriverProviderName -match 'NVIDIA' }); if ($d.Count -gt 0) { exit 0 } else { exit 1 }"
if errorlevel 1 (
    echo [ERROR] NVIDIA RTX 3080 display driver was not verified.
    echo Install the downloaded NVIDIA graphics driver, reboot, then retry.
    goto :fail
)

rem The Store package is per-user. If already installed, do not reinstall.
"%PS%" -NoLogo -NoProfile -Command "if (Get-AppxPackage -Name NVIDIACorp.NVIDIAControlPanel -ErrorAction SilentlyContinue) { exit 0 } else { exit 1 }"
if not errorlevel 1 (
    echo [OK] NVIDIA Control Panel is already installed for this user.
    goto :success
)

where winget.exe >nul 2>&1
if errorlevel 1 (
    echo [ERROR] WinGet was not found. Check Microsoft App Installer.
    goto :fail
)

echo [INSTALL] Microsoft Store package 9NF8H0H7WMLT...
winget.exe install --id 9NF8H0H7WMLT --exact --source msstore --accept-package-agreements --accept-source-agreements
if errorlevel 1 (
    echo [ERROR] Microsoft Store installation failed.
    goto :fail
)

rem Report success only after the package exists for the current user.
"%PS%" -NoLogo -NoProfile -Command "if (Get-AppxPackage -Name NVIDIACorp.NVIDIAControlPanel -ErrorAction SilentlyContinue) { exit 0 } else { exit 1 }"
if errorlevel 1 (
    echo [ERROR] WinGet returned success, but NVIDIA Control Panel was not verified.
    goto :fail
)

:success
echo.
echo [OK] NVIDIA Control Panel installation verified.
echo.
pause
exit /b 0

:fail
echo.
echo Official Microsoft Store page:
echo https://apps.microsoft.com/detail/9NF8H0H7WMLT
echo.
pause
exit /b 1
