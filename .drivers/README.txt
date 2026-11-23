SURUCU HAZIRLIGI / DRIVER DOWNLOAD + VERIFY
=============================================

TURKCE

Baslatici: Download_Gaming_Drivers.cmd
PowerShell: Download-Gaming-Drivers.ps1
Syntax kontrolu: tests\Check_Gaming_Driver_Syntax.cmd (repo kokunden)

Script, uygun driver paketlerini indirir ve dogrular; otomatik kurulum yapmaz.
Sonuc raporu: Downloads\Drivers\DRIVER_MANUAL_INSTALL_ORDER.csv
FAILED olan bir paket kurulum icin hazir degildir.

Manuel kurulum sirasi:
1. AMD chipset
2. Intel I226-V LAN
3. Realtek UCM (eslesen ACPI device varsa)
4. AMD iGPU (ayri test edilen baseline'a dahilse)
5. NVIDIA RTX 3080 WHQL graphics-only
6. ZOWIE XL2566X+ WHQL monitor INF
7. NVIDIA driver + reboot sonrasi Downloads\Drivers\Install_NVIDIA_Control_Panel.cmd

AMD Adrenalin EXE, hazir driver-only INF degildir. iGPU icin hardware ID ve
INF eslesmesi kontrol edilir.

ENGLISH

Launcher: Download_Gaming_Drivers.cmd
PowerShell source: Download-Gaming-Drivers.ps1
Syntax check: tests\Check_Gaming_Driver_Syntax.cmd (from repository root)

The script downloads and verifies hardware-matched drivers; installation
remains manual. Review Downloads\Drivers\DRIVER_MANUAL_INSTALL_ORDER.csv.
A FAILED package is not ready.

Manual order: AMD chipset, I226-V LAN, Realtek UCM if present, optional
separately tested AMD iGPU, NVIDIA graphics-only WHQL, ZOWIE monitor INF,
then the separate NVIDIA Control Panel CMD after reboot.

AMD Adrenalin EXE is not a pre-extracted driver-only INF. Verify hardware
ID and matching INF before preparing the optional iGPU driver.

Detaylar / Details: docs\DOWNLOAD_ONLY.md
