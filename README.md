# my-pc-optimization

Personal, hardware-specific Windows 11 / CS2 environment, **not** a general PC-tweak guide. Target hardware and peripherals: [SYSTEM.md](SYSTEM.md); CS2 reference values: [REFERENCE_STATE.md](REFERENCE_STATE.md).

## Current deployment model — download & verify, then manual install

**Driver and application launchers no longer install, uninstall, bind PnP drivers, or remove bundled applications.** They prepare current official downloads under the folder containing SSD Setup and record hashes, versions, source URLs and errors.

Run:
1. `.drivers\Check_Gaming_Driver_Syntax.cmd` (Windows PowerShell 5.1 parser check).
2. `.drivers\Download_Gaming_Drivers.cmd` — AMD B850, ASUS I226-V/Realtek UCM, AMD iGPU, NVIDIA RTX 3080 WHQL, bundled ZOWIE INF.
3. `Download_PostFormat_Apps.cmd` — WinGet `download` for runtime/apps; official DirectX, TeamSpeak and Logitech downloads; Store/web-only items as manual links.
4. Review `Downloads\Drivers\DRIVER_MANUAL_INSTALL_ORDER.csv` and `Downloads\Apps\APP_MANUAL_INSTALL_ORDER.csv`, resolve every FAILED row, then **manually** install one component at a time with verification/reboots as appropriate.
5. Apply Windows/CS2 baseline separately using `Run_CS2_Gaming_Scripts.cmd` only when intended and after drivers are stable.

Legacy `Run_Gaming_Drivers_v2.cmd`, `Audit_Gaming_Drivers_v2.cmd`, and `Run_PostFormat_Apps.cmd` are safe aliases to the new **download-only** launchers. The older Spotify unattended helper has been removed. No automatic installer mode remains in the two package preparation scripts.

All script-owned file artifacts are rooted relative to **SSD Setup**, not `ProgramData`, `Program Files` or the user Temp directory:

```text
SSD Setup/
  Downloads/Drivers/
  Downloads/Apps/
  Logs/Drivers/
  Logs/PostFormat/
  Logs/CS2/
  Logs/Policy/
  Logs/Devices/
  State/
  Work/Drivers/Extracted/
```

This governs paths that our scripts choose. Windows, WinGet and vendor utilities can still maintain their own internal OS caches when invoked or when you install manually.

**Important:** `00_Fresh_Install_W11_Pro.cmd` is separate, destructive Windows-image automation and still contains a hard-coded D: format target. Do not run casually. The `.scripts` Windows/CS2 baseline tools also make OS setting changes; only the **driver/app preparation** layers are download-only.

Detailed procedures, limits, error handling and manual order: [DOWNLOAD_ONLY.md](DOWNLOAD_ONLY.md).

## Optimization baseline

AMD Ryzen 7 9800X3D, ASUS ROG STRIX B850-I, same G.Skill Hynix A-die 2×16GB kit, RTX 3080 12GB, Samsung 990 Pro, BenQ XL2566X+, Logitech Superlight 2 DEX and Wooting 80HE. BIOS legacy Tachyon settings live separately in `.bios/legacy/` and are not current defaults.

CS2 baseline v1.0.9 and launcher REV14.8, I226-V v2.4, gaming-device-power v1.4 and KovaaK standardized profile remain separate. Paths/storage changed earlier; this deployment alters **driver and app installers**, not these game/performance settings.

[VALIDATION.md](VALIDATION.md) distinguishes static source checks from the still-required real Windows runtime validation. [SOURCE_PACKAGE.md](SOURCE_PACKAGE.md) preserves historical 2026-10-08 ZIP provenance.
