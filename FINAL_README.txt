CURRENT REPO: DOWNLOAD + VERIFY ONLY (2026-10-16)
=============================================
This repository has migrated away from the original 2026-10-08 unattended
driver/application installer ZIP. Historical FINAL_AUDIT.txt refers to the old
ZIP and is NOT proof of this new runtime path.

Run:
  .drivers\Check_Gaming_Driver_Syntax.cmd
  .drivers\Download_Gaming_Drivers.cmd
  Download_PostFormat_Apps.cmd

Inspect:
  Downloads\Drivers\DRIVER_MANUAL_INSTALL_ORDER.csv
  Downloads\Apps\APP_MANUAL_INSTALL_ORDER.csv
  Logs\Drivers\ and Logs\PostFormat\

Manually install drivers and apps ONE AT A TIME, verifying results/rebooting
where necessary. No driver/app install/cleanup runs automatically.
For complete details consult README.md and DOWNLOAD_ONLY.md.

CAUTION: 00_Fresh_Install_W11_Pro.cmd STILL formats a preselected D: target
and applies a Windows image. The Windows/CS2 baseline scripts also still
modify settings when explicitly run. These are NOT downloader launchers.
