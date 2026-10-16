# Download + Verify Only: manual deployment

The intent is to reduce uncontrolled variables while debugging CS2 freezes, focus loss/alt-tab behavior and intermittent latency. **Not** proof that a previously observed spike originated from a driver.

## Scope

- Only official publisher/vendor download sources; current versions resolved at execution when available.
- Package prep scripts perform no `winget install`, `Start-Process` installer, `pnputil /add-driver`, app uninstall, driver-policy modification or task scheduling.
- Downloads, logs, extracted archives and receipts live below the **current SSD Setup root**; they do not depend on `C:` or `D:`.
- Auto-download failures are explicit. No `--ignore-security-hash`, guessed versions or defaulting to an unverified package.
- Other baseline scripts and the destructive Windows-image deployment script are outside this limited scope.

## Drivers

Launch `.drivers\Download_Gaming_Drivers.cmd`. The downloader checks that it runs on the intended B850-I / 9800X3D / RTX 3080 (PCI DEV_220A) system, resolves the official current files, and writes receipts. ASUS packages are verified against SHA-256 from the matching ASUS page record. AMD/NVIDIA EXEs require valid matching Authenticode signatures. The monitor archive is pinned to a known SHA-256 and catalog verification.

Inspect `Downloads\Drivers\DRIVER_MANUAL_INSTALL_ORDER.csv`. A failure row means NOT READY. Suggested manual progression: AMD chipset → LAN I226-V → Realtek UCM if device exists → AMD iGPU driver-only if exact device exists → NVIDIA WHQL custom graphics-only → ZOWIE monitor INF → manual NVIDIA Control Panel HSA (<https://apps.microsoft.com/detail/9NF8H0H7WMLT>). Reboot and inspect Device Manager, installed versions and Event Viewer as appropriate. Do not run the full AMD Adrenalin installer just to get driver-only behavior: its signed EXE is a package container, not a pre-extracted driver-only deliverable. If a verified matching INF cannot be selected manually, defer the iGPU step.

For freshly imaged Windows without working I226-V inbox Ethernet, manually bootstrap the LAN INF from a trusted previously prepared package before online download.

## Apps

Launch `Download_PostFormat_Apps.cmd`. It invokes `winget download` (never `winget install`) for Visual C++ runtimes, Chrome, AutoHotkey, FACEIT AC, Spotify and Steam. The WinGet source performs manifest hash validation; the script also records per-file SHA-256 and any Authenticode status. If WinGet source metadata is stale or a CDN file fails its expected hash, that component is FAILED, not silently accepted.

Microsoft DirectX legacy runtime, TeamSpeak 3.6.2 and Logitech Onboard Memory Manager are downloaded from their respective official endpoints with publisher signature checks. TeamSpeak is additionally pinned to its expected SHA-256. Manual TeamSpeak installation must avoid optional Overwolf. FACEIT Anti-Cheat must be checked to ensure the unwanted separate FACEIT platform client was not installed.

NVIDIA Control Panel HSA is Store-only and Wootility is browser-based; these and optional ExitLag are manual links in `Downloads\Apps\APP_MANUAL_INSTALL_ORDER.csv`, not fabricated offline EXEs.

Install applications manually and verify installed versions, optional components and behavior after each batch. The preparation script does **not** know whether manual installation later succeeded.

## Repeated tests

Keep downloads/receipts for evidence. WinGet package subfolders are refreshed before each new download to prevent stale binaries being marked current. Do not run gaming/driver installers while benchmarking. Compare stable sessions with the same CS2 map/server/client settings; track frametime outliers, alt-tab/focus changes, Event Viewer driver resets and latency, not just average FPS.

## Runtime boundary

Static checks can establish that wrappers call safe download paths and obvious mutating installer commands are absent. **They cannot validate** Windows PowerShell 5.1 execution, changing vendor support page schemas, WinGet download behavior, current signatures, inf compatibility, internet availability or Windows driver binding on the target system.
