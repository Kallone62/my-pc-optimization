DRIVER DOWNLOAD & VERIFY ONLY - v3.0
==================================
Launcher: Download_Gaming_Drivers.cmd
Legacy launchers Run_Gaming_Drivers_v2.cmd and Audit_Gaming_Drivers_v2.cmd
now invoke the SAME download-only launcher. No Install mode exists.

Targets: ASUS ROG STRIX B850-I / Ryzen 7 9800X3D / RTX 3080 12GB.
Sources: official AMD/ASUS/NVIDIA endpoints + bundled ZOWIE WHQL archive.
Checks: current vendor version, HTTPS host allowlist, ASUS SHA256, vendor
Authenticode where available, matching hardware ID/INF and WHQL CAT signature
for bundled ZOWIE monitor. No pnputil add-driver or vendor setup execution.

Outputs (relative to SSD Setup regardless of installation location):
  Downloads\Drivers\
  Work\Drivers\Extracted\
  Logs\Drivers\

Open Downloads\Drivers\DRIVER_MANUAL_INSTALL_ORDER.csv for the exact files,
hashes, source URLs and manual notes.

Suggested MANUAL order:
1. AMD chipset (reboot, verify package).
2. Intel I226-V LAN (install matching INF, verify device).
3. Realtek UCM only if ACPI\RTK5452 present.
4. AMD iGPU (only matching driver INF; official full Adrenalin EXE is a
   container, NOT a driver-only offline package; do not blindly run it).
5. NVIDIA WHQL Game Ready (Custom setup: Graphics Driver only, no NVIDIA
   App and no HD Audio; reboot).
6. ZOWIE XL2566X+ WHQL matching INF.
7. NVIDIA Control Panel HSA through Microsoft Store manually.

No setup is executed, no PnP device is rebound, no driver guard/WU policies
are changed. Any unresolved version, hash, signature or device identity
must be treated as FAILED, never as READY.

Prerequisite: if the new Windows image lacks a working inbox I226-V network
driver, bootstrap a matching LAN INF once before using the online downloader.

See DOWNLOAD_ONLY.md at the SSD Setup root. Windows live runtime testing
is required; source/static review does not prove downloads work forever.
