SÜRÜCÜ HAZIRLIĞI / DRIVER DOWNLOAD + VERIFY
=============================================

TÜRKÇE

Başlatıcı: Download_Gaming_Drivers.cmd
PowerShell: Download-Gaming-Drivers.ps1
Syntax kontrolü: tests\Check_Gaming_Driver_Syntax.cmd (repo kökünden)

Bu downloader hardware-matched driver paketlerini indirir ve verify eder; installation manuel.
Sonuç: Downloads\Drivers\DRIVER_MANUAL_INSTALL_ORDER.csv
FAILED durumundaki paket kurulum için hazır değil.

Manuel kurulum sırası:
1. AMD chipset
2. Intel I226-V LAN
3. Realtek UCM (eşleşen ACPI device varsa)
4. AMD iGPU (ayrı test edilen baseline'a dahilse)
5. NVIDIA RTX 3080 WHQL graphics-only
6. ZOWIE XL2566X+ WHQL monitor INF
7. NVIDIA driver + reboot sonrasında:
   Downloads\Drivers\Install_NVIDIA_Control_Panel.cmd

AMD Adrenalin EXE doğrudan driver-only INF değil. iGPU için hardware ID ve
INF eşleşmesini ayrı doğruluyorum.

ENGLISH

Launcher: Download_Gaming_Drivers.cmd
PowerShell source: Download-Gaming-Drivers.ps1
Syntax check: tests\Check_Gaming_Driver_Syntax.cmd (from repository root)

This script downloads and verifies hardware-matched packages; installation
remains manual. Review Downloads\Drivers\DRIVER_MANUAL_INSTALL_ORDER.csv.
A FAILED package is not ready for installation.

Manual order: AMD chipset, I226-V LAN, Realtek UCM when present, optional
separately tested AMD iGPU, NVIDIA graphics-only WHQL, ZOWIE monitor INF,
then the NVIDIA Control Panel CMD after installing the driver and rebooting.

AMD Adrenalin EXE is not a driver-only INF. Match hardware ID and INF before
preparing the optional iGPU driver.

Ayrıntılar / Details: docs\DOWNLOAD_ONLY.md
