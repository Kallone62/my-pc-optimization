# PC Optimization — CS2 machine

Hardware-specific Windows 11 / CS2 setup for one PC, not a generic tuning guide.

- [Hardware](docs/SYSTEM.md) · [CS2/input/display reference](docs/REFERENCE_STATE.md)
- [Manual installation details](docs/DOWNLOAD_ONLY.md) · [Validation status](docs/VALIDATION.md)

## Canonical entrypoints

| Task | Launcher | Effect |
| --- | --- | --- |
| Check downloader syntax | `.drivers\Check_Gaming_Driver_Syntax.cmd` | Read-only |
| Prepare official driver packages | `.drivers\Download_Gaming_Drivers.cmd` | Download and verify; no install |
| Prepare application packages | `Download_PostFormat_Apps.cmd` | Download and verify; no install |
| Apply Windows/CS2 policies | `Run_CS2_Gaming_Scripts.cmd` | **Changes Windows, network, device, and security settings** |

Before manual installation, inspect the generated
`Downloads\Drivers\DRIVER_MANUAL_INSTALL_ORDER.csv` and
`Downloads\Apps\APP_MANUAL_INSTALL_ORDER.csv`.
NVIDIA Control Panel is a separate Microsoft Store app.
AMD iGPU installation is optional and must be tested independently.

## Rules

1. Establish a clean, official-driver Windows reference before applying policy scripts.
2. Keep cosmetic setup separate from performance or network changes.
3. Change one variable per CS2 comparison; record frametime tails, shot consistency and online behavior.
4. Validate Windows runtime, reboot persistence and FACEIT before calling any change an improvement.

**Safety:** `00_Fresh_Install_W11_Pro.cmd` can **format D:** and is not
part of the release ZIP. Do not run it as a normal optimization step.
`Run_CS2_Gaming_Scripts.cmd` can disable Defender features and automatic updates.
Its effects are not limited to cosmetic cleanup.

Current B850-I BIOS settings are pending capture. Never apply
`.bios/legacy/Z690-Tachyon/` settings to this platform.
