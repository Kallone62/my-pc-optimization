# Intel I226-V baseline v2.5 — targeted changes, no blanket NDIS power disable
# Keep the previous Device Manager baseline; do not change other NDIS PM features.
#
# Changes:
#   - Energy Efficient Ethernet       -> Disabled
#   - DMA Coalescing                  -> Disabled, if exposed
#   - Flow Control                    -> Tx & Rx Disabled
#   - Reduce Speed On Power Down      -> Disabled, if exposed
#   - Ultra Low Power Mode            -> Disabled, if exposed
#   - Idle power down restriction     -> Only idle when user isn't present, if exposed
#   - Allow computer to turn off this device -> Disabled (master checkbox only)
#   - NetBIOS over TCP/IP             -> Disabled on this I226-V only
#
# Does NOT modify:
#   - Selective Suspend, D0 Packet Coalescing, Device Sleep on Disconnect
#   - ARP/NS offloads, RsnRekey, Wake on Magic Packet/Pattern
#   - Interrupt Moderation/ITR, RSS, checksum/segmentation offloads
#   - Speed & Duplex, system-wide PCIe ASPM
#
# Deliberately avoid Disable-NetAdapterPowerManagement without a feature switch:
# that command changes every supported NDIS power-management feature.

$ErrorActionPreference = "Stop"

$admin = ([Security.Principal.WindowsPrincipal](
    [Security.Principal.WindowsIdentity]::GetCurrent()
)).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $admin) {
    throw "Run this script as Administrator."
}

$nic = @(
    Get-NetAdapter -Physical |
    Where-Object { $_.InterfaceDescription -match '(?i)\bI226-V\b' }
)

if ($nic.Count -eq 0) { throw "Intel I226-V not found." }
if ($nic.Count -gt 1) { throw "Multiple I226-V adapters found; refusing to guess." }

$nic = $nic[0]
$changed = $false
$rebootRequired = $false

Write-Host "I226-V: $($nic.Name) / $($nic.InterfaceDescription)" -ForegroundColor Cyan

function Get-AdvancedProperty {
    param(
        [string[]]$RegistryKeywords,
        [string[]]$DisplayNames = @()
    )

    $props = @(Get-NetAdapterAdvancedProperty -Name $nic.Name -AllProperties -ErrorAction SilentlyContinue)

    foreach ($key in $RegistryKeywords) {
        $p = $props | Where-Object { $_.RegistryKeyword -eq $key } | Select-Object -First 1
        if ($p) { return $p }
    }

    foreach ($name in $DisplayNames) {
        $p = $props | Where-Object { $_.DisplayName -eq $name } | Select-Object -First 1
        if ($p) { return $p }
    }

    return $null
}

function Set-AdvancedRegistryValueSafely {
    param(
        [Parameter(Mandatory)][string]$Label,
        [Parameter(Mandatory)][string[]]$RegistryKeywords,
        [Parameter(Mandatory)][string]$RegistryValue,
        [string[]]$DisplayNames = @()
    )

    $p = Get-AdvancedProperty -RegistryKeywords $RegistryKeywords -DisplayNames $DisplayNames

    if (-not $p) {
        Write-Host "[SKIP] $Label - not exposed by current driver" -ForegroundColor DarkGray
        return $false
    }

    $valid = @($p.ValidRegistryValues | ForEach-Object { [string]$_ })
    if ($valid.Count -gt 0 -and $RegistryValue -notin $valid) {
        Write-Host "[SKIP] $Label - driver does not advertise value $RegistryValue" -ForegroundColor Yellow
        return $false
    }

    $current = @($p.RegistryValue | ForEach-Object { [string]$_ })

    if ($current.Count -eq 1 -and $current[0] -eq $RegistryValue) {
        Write-Host "[OK]   $Label (already set)" -ForegroundColor Green
        return $true
    }

    Set-NetAdapterAdvancedProperty `
        -Name $nic.Name `
        -RegistryKeyword $p.RegistryKeyword `
        -RegistryValue $RegistryValue `
        -NoRestart

    $script:changed = $true
    Write-Host "[SET]  $Label" -ForegroundColor Green
    return $true
}

function Set-I226NetbiosDisabled {
    # Map the already-validated physical I226-V adapter to its TCP/IP
    # Win32_NetworkAdapterConfiguration instance. Do not touch other adapters.
    $configs = @(
        Get-CimInstance -ClassName Win32_NetworkAdapterConfiguration -ErrorAction Stop |
        Where-Object {
            $_.IPEnabled -and
            [int]$_.InterfaceIndex -eq [int]$nic.ifIndex
        }
    )

    if ($configs.Count -eq 0) {
        throw "I226-V TCP/IP configuration object was not found."
    }

    if ($configs.Count -gt 1) {
        throw "Multiple TCP/IP configuration objects matched I226-V; refusing to guess."
    }

    $cfg = $configs[0]
    $current = [int]$cfg.TcpipNetbiosOptions

    if ($current -eq 2) {
        Write-Host "[OK]   NetBIOS over TCP/IP -> Disabled (already set)" -ForegroundColor Green
        return
    }

    $result = Invoke-CimMethod `
        -InputObject $cfg `
        -MethodName SetTcpipNetbios `
        -Arguments @{ TcpipNetbiosOptions = [uint32]2 } `
        -ErrorAction Stop

    $returnValue = [int]$result.ReturnValue

    if ($returnValue -notin @(0, 1)) {
        throw "SetTcpipNetbios failed with return value $returnValue."
    }

    $verify = @(
        Get-CimInstance -ClassName Win32_NetworkAdapterConfiguration -ErrorAction Stop |
        Where-Object {
            $_.IPEnabled -and
            [int]$_.InterfaceIndex -eq [int]$nic.ifIndex
        }
    )

    if ($verify.Count -ne 1 -or [int]$verify[0].TcpipNetbiosOptions -ne 2) {
        throw "NetBIOS over TCP/IP disable did not verify on I226-V."
    }

    $script:changed = $true

    if ($returnValue -eq 1) {
        $script:rebootRequired = $true
        Write-Host "[SET]  NetBIOS over TCP/IP -> Disabled (Windows reports reboot required)" -ForegroundColor Green
    }
    else {
        Write-Host "[SET]  NetBIOS over TCP/IP -> Disabled" -ForegroundColor Green
    }
}

function Get-I226PowerManagement {
    return Get-NetAdapterPowerManagement -Name $nic.Name -ErrorAction Stop
}

function Write-I226PowerSnapshot {
    param(
        [Parameter(Mandatory)]$State,
        [string]$Prefix = ''
    )

    $fields = @(
        'AllowComputerToTurnOffDevice',
        'SelectiveSuspend',
        'D0PacketCoalescing',
        'DeviceSleepOnDisconnect',
        'ArpOffload',
        'NSOffload',
        'RsnRekeyOffload',
        'WakeOnMagicPacket',
        'WakeOnPattern'
    )

    foreach ($field in $fields) {
        if ($State.PSObject.Properties[$field]) {
            Write-Host ("{0}{1,-31}: {2}" -f $Prefix,$field,[string]$State.$field)
        }
    }
}

function Ensure-I226MasterPowerDisabled {
    $before = Get-I226PowerManagement

    Write-Host '[INFO] Windows/NDIS PM state before:' -ForegroundColor Cyan
    Write-I226PowerSnapshot -State $before -Prefix '       '

    if (-not $before.PSObject.Properties['AllowComputerToTurnOffDevice']) {
        throw 'I226-V driver does not expose AllowComputerToTurnOffDevice.'
    }

    $master = [string]$before.AllowComputerToTurnOffDevice
    if ($master -eq 'Unsupported') {
        throw 'I226-V driver reports AllowComputerToTurnOffDevice as Unsupported.'
    }

    # Match the previously used Device Manager master checkbox only.
    # Unlike a blanket Disable-NetAdapterPowerManagement call, this does not
    # intentionally disable Selective Suspend and subordinate NDIS PM features.
    if ($master -ne 'Disabled') {
        try {
            $before.AllowComputerToTurnOffDevice = 'Disabled'
            $before | Set-NetAdapterPowerManagement -NoRestart -ErrorAction Stop | Out-Null
            $script:changed = $true
            Write-Host '[SET]  Allow computer to turn off I226-V -> Disabled' -ForegroundColor Green
        }
        catch {
            throw ("Could not set AllowComputerToTurnOffDevice=Disabled: " + $_.Exception.Message)
        }
    }
    else {
        Write-Host '[OK]   Allow computer to turn off I226-V -> Disabled (already set)' -ForegroundColor Green
    }
}

function Assert-I226MasterPowerDisabled {
    $verify = Get-I226PowerManagement
    $master = [string]$verify.AllowComputerToTurnOffDevice

    Write-Host ''
    Write-Host '[INFO] Windows/NDIS PM state after adapter restart:' -ForegroundColor Cyan
    Write-I226PowerSnapshot -State $verify -Prefix '       '

    if ($master -ne 'Disabled') {
        throw ("Power-management lockdown failed: AllowComputerToTurnOffDevice is " + $master + ", expected Disabled.")
    }

    Write-Host '[VERIFIED] I226-V master device power-off permission = Disabled' -ForegroundColor Green
    Write-Host '[INFO] Subordinate NDIS power-management features were not changed by this script.' -ForegroundColor Yellow
}

$null = Set-AdvancedRegistryValueSafely `
    -Label "Energy Efficient Ethernet -> Disabled" `
    -RegistryKeywords @("*EEE", "EEELinkAdvertisement") `
    -RegistryValue "0" `
    -DisplayNames @("Energy Efficient Ethernet")

$null = Set-AdvancedRegistryValueSafely `
    -Label "DMA Coalescing -> Disabled" `
    -RegistryKeywords @("DMACoalescing") `
    -RegistryValue "0" `
    -DisplayNames @("DMA Coalescing")

$null = Set-AdvancedRegistryValueSafely `
    -Label "Flow Control -> Tx & Rx Disabled" `
    -RegistryKeywords @("*FlowControl") `
    -RegistryValue "0" `
    -DisplayNames @("Flow Control")

$null = Set-AdvancedRegistryValueSafely `
    -Label "Reduce Speed On Power Down -> Disabled" `
    -RegistryKeywords @("ReduceSpeedOnPowerDown") `
    -RegistryValue "0" `
    -DisplayNames @("Reduce Speed On Power Down", "Reduce Speed on Power Down")

$null = Set-AdvancedRegistryValueSafely `
    -Label "Ultra Low Power Mode -> Disabled" `
    -RegistryKeywords @("ULPMode") `
    -RegistryValue "0" `
    -DisplayNames @("Ultra Low Power Mode")

$null = Set-AdvancedRegistryValueSafely `
    -Label "Idle power down restriction -> Only idle when user isn't present" `
    -RegistryKeywords @("*IdleRestriction") `
    -RegistryValue "1" `
    -DisplayNames @("Idle power down restriction")

# Preserve the previous Device Manager master power-off checkbox without blanket PM disable.
Ensure-I226MasterPowerDisabled

Set-I226NetbiosDisabled

if ($changed) {
    Write-Host "`nRestarting adapter once to apply changes..." -ForegroundColor Cyan
    Restart-NetAdapter -Name $nic.Name -Confirm:$false
    Start-Sleep -Seconds 3
}
else {
    Write-Host "`nNo changes required." -ForegroundColor Cyan
}

Assert-I226MasterPowerDisabled

Write-Host "`n=== CURRENT I226-V STATE ===" -ForegroundColor Cyan

Get-NetAdapterAdvancedProperty -Name $nic.Name -AllProperties |
    Where-Object {
        $_.RegistryKeyword -in @(
            "*EEE",
            "EEELinkAdvertisement",
            "DMACoalescing",
            "*FlowControl",
            "ReduceSpeedOnPowerDown",
            "ULPMode",
            "*IdleRestriction",
            "*InterruptModeration",
            "ITR"
        ) -or $_.DisplayName -in @(
            "Energy Efficient Ethernet",
            "DMA Coalescing",
            "Flow Control",
            "Reduce Speed On Power Down",
            "Reduce Speed on Power Down",
            "Ultra Low Power Mode",
            "Idle power down restriction",
            "Interrupt Moderation",
            "Interrupt Moderation Rate"
        )
    } |
    Select-Object DisplayName, DisplayValue, RegistryKeyword, RegistryValue |
    Sort-Object DisplayName |
    Format-Table -AutoSize

$pm = Get-NetAdapterPowerManagement -Name $nic.Name -ErrorAction SilentlyContinue
if ($pm) {
    $pm |
        Select-Object `
            Name,
            AllowComputerToTurnOffDevice,
            SelectiveSuspend,
            D0PacketCoalescing,
            DeviceSleepOnDisconnect,
            ArpOffload,
            NSOffload,
            WakeOnMagicPacket,
            WakeOnPattern |
        Format-List
}

$netbiosCfg = @(
    Get-CimInstance -ClassName Win32_NetworkAdapterConfiguration -ErrorAction SilentlyContinue |
    Where-Object {
        $_.IPEnabled -and
        [int]$_.InterfaceIndex -eq [int]$nic.ifIndex
    }
)

if ($netbiosCfg.Count -eq 1) {
    $netbiosValue = [int]$netbiosCfg[0].TcpipNetbiosOptions
    $netbiosState = switch ($netbiosValue) {
        0 { "DHCP controlled" }
        1 { "Enabled" }
        2 { "Disabled" }
        default { "Unknown ($netbiosValue)" }
    }

    Write-Host ("NetBIOS over TCP/IP : {0}" -f $netbiosState)
}

Write-Host "Interrupt Moderation / ITR were NOT modified." -ForegroundColor Yellow
Write-Host "RSS / checksum offloads / LSO / Speed & Duplex were NOT modified." -ForegroundColor Yellow
Write-Host "Selective Suspend and subordinate NDIS PM features were NOT modified." -ForegroundColor Yellow

Write-Host "System-wide PCIe ASPM was NOT modified." -ForegroundColor Yellow

if ($rebootRequired) {
    Write-Host ""
    Write-Host "Windows reports a reboot is required for the NetBIOS change to become fully effective." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "=== OPTIONAL A/B TEST REMINDERS ===" -ForegroundColor Cyan
Write-Host "These are NOT applied automatically." -ForegroundColor Yellow
Write-Host "1. Interrupt Moderation Rate: Low / Medium / High"
Write-Host "2. RSS receive queues: Driver default / 2 queues"
Write-Host "3. PCIe Link State Power Management / ASPM: system-wide; test separately only"
Write-Host "Test one variable at a time and keep the rest unchanged."
