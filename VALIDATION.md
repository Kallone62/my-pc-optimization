# Validation

## 2026-10-16: download-only migration (current)

New driver and application preparation sources replace the prior unattended install flows.

Static checks:
- Both package preparation scripts have no installer process launch, `winget install`, PnP binding, uninstall or Windows policy mutation calls.
- Driver resolver retains target hardware assertions, vendor host allowlist, ASUS hash, AMD/NVIDIA Authenticode, ZOWIE bundled archive SHA-256 and catalog verification, and device/INF matching.
- App downloader uses `winget download`, direct HTTPS publisher downloads and per-file receipts. Failed hash/source/signature checks are reported as FAILED.
- Old driver CMD aliases point to the download-only launcher; old app CMD alias points to the download-only launcher. The unattended Spotify helper is removed.
- Downloads, logs and extraction paths are rooted relative to SSD Setup.
- Removed stale static `MANIFEST.sha256` from earlier ZIP revisions: runtime downloads produce current per-file SHA-256 CSV manifests, not an outdated immutable hash list.

**Not yet validated on target Windows 11:** PowerShell 5.1 AST parsing, live vendor page layout, current WinGet package availability/download support, signatures, INF bindings, Microsoft Store HSA manual install, post-reboot state or CS2 stability. No claim of an end-to-end working deployment until those tests pass.

Historical earlier ZIP/linkage audits remain described in [SOURCE_PACKAGE.md](SOURCE_PACKAGE.md) and source `FINAL_AUDIT.txt`; they refer to the 2026-10-08 *installer* version and must not be mistaken for this downloader's runtime validation.
