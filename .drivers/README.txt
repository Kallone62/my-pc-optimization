DRIVER DOWNLOAD + VERIFY ONLY
================================
Launcher: Download_Gaming_Drivers.cmd
PowerShell source: Download-Gaming-Drivers.ps1
Syntax checker: Check_Gaming_Driver_Syntax.cmd

The downloader does not install or bind drivers. It prepares official packages
and writes Downloads\Drivers\DRIVER_MANUAL_INSTALL_ORDER.csv with validation
results, hashes and manual installation notes. A FAILED component is not ready.

Suggested manual order:
1. AMD chipset
2. Intel I226-V LAN
3. Realtek UCM only if matching ACPI device is present
4. AMD iGPU OPTIONAL: only for a separately tested iGPU-driver configuration
5. NVIDIA RTX 3080 WHQL Graphics Driver only
6. ZOWIE XL2566X+ WHQL monitor INF
7. After installing NVIDIA and rebooting, run Downloads\\Drivers\\Install_NVIDIA_Control_Panel.cmd to install NVIDIA Control Panel from Microsoft Store.

The AMD Adrenalin EXE is not a pre-extracted driver-only INF package.
Review the exact hardware ID/INF before manual driver installation.
See DOWNLOAD_ONLY.md and VALIDATION.md at the repository root.
