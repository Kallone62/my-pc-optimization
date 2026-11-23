# Validation state

The canonical downloaders are `.drivers/Download-Gaming-Drivers.ps1`
and `.scripts/Download-PostFormat-Apps.ps1`; CMD wrappers and the release
manifest must reference these exact paths.

The release workflow verifies required files and nested ZIP integrity.
It excludes the destructive Windows imaging launcher.

The October 2026 legacy `FINAL_AUDIT.txt` and `FINAL_README.txt` described
an earlier unattended installer and are retained in Git history, not as
current validation records.

## Still requires real Windows verification

- PowerShell 5.1 syntax and execution.
- Vendor URLs, downloads, hashes/signatures, INF/hardware matching.
- Post-reboot driver, NIC, USB and security state.
- CS2/FACEIT gameplay and input/frametime-tail A/B tests.

Static inspection alone is **not** proof of working or faster runtime behavior.
