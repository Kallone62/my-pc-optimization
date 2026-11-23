#requires -Version 5.1
<#
Download and verify ONLY. Does not install drivers, change the driver store,
modify PnP/WU policies, modify services or add Microsoft Store applications.
Outputs are relative to the SSD Setup folder, not ProgramData or Program Files.
#>
[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$script:WebSession = New-Object Microsoft.PowerShell.Commands.WebRequestSession
$ScriptVersion = '3.0-download-only'
$ScriptRoot = $PSScriptRoot
$PackRoot = Split-Path -Parent $ScriptRoot
$DownloadRoot = Join-Path $PackRoot 'Downloads\Drivers'
$ExtractRoot = Join-Path $PackRoot 'Work\Drivers\Extracted'
$LogRoot = Join-Path $PackRoot 'Logs\Drivers'
$NvidiaTargetHardwareRegex = '^PCI\\VEN_10DE&DEV_220A(?:&|$)'
$AsusSupportUrl = 'https://www.asus.com/us/supportonly/rog%20strix%20b850-i%20gaming%20wifi/helpdesk_download/'
$AmdChipsetPage = 'https://www.amd.com/en/support/downloads/drivers.html/chipsets/am5/b850.html'
$AmdIgpuPage = 'https://www.amd.com/en/support/downloads/drivers.html/processors/ryzen/ryzen-9000-series/amd-ryzen-7-9800x3d.html'
$NvidiaLookupBase = 'https://gfwsl.geforce.com/services_toolkit/services/com/nvidia/services/AjaxDriverService.php'
$MonitorPackageRelativePath = 'Assets\Monitor\XL2566X+_WHQL dirver_V001_Windows_240605180238.7z'
$MonitorPackagePath = Join-Path $ScriptRoot $MonitorPackageRelativePath
$MonitorPackageSha256 = 'E8B600BE155F85BA417BEE80EAE6065848885F9E72A331B19D17D53FD9751D38'
$script:VerifiedDownloads = @{}
$script:OfficialPages = @{}
$script:NvidiaLatest = $null
$script:Rows = New-Object System.Collections.Generic.List[object]
$script:Failures = 0
foreach($dir in @($DownloadRoot,$ExtractRoot,$LogRoot)) {
  New-Item -ItemType Directory -Path $dir -Force -ErrorAction Stop | Out-Null
}
$Stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$LogFile = Join-Path $LogRoot "driver-download-$Stamp.log"
Start-Transcript -Path $LogFile -Force | Out-Null

function Save-DriverReady {
  param([string]$Name,[string]$Version,[string]$Path,[string]$Url,[string]$Instructions)
  if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { throw "Missing verified payload: $Path" }
  $hash = Get-FileSha256 -Path $Path
  $script:Rows.Add([pscustomobject]@{
    Component=$Name; Status='READY'; Version=$Version; File=$Path; SHA256=$hash;
    Source=$Url; ManualInstructions=$Instructions
  })
  Write-Host "[READY] $Name / $Version / $Path" -ForegroundColor Green
}
function Write-DriverFailure {
  param([string]$Name,[string]$Message)
  $script:Failures++
  $script:Rows.Add([pscustomobject]@{ Component=$Name; Status='FAILED'; Version=''; File=''; SHA256=''; Source=''; ManualInstructions=$Message })
  Write-Host "[FAILED] $Name - $Message" -ForegroundColor Red
}
function Invoke-DriverDownloadStep {
  param([string]$Name,[scriptblock]$Action)
  try { & $Action } catch { Write-DriverFailure -Name $Name -Message $_.Exception.Message }
}

function Write-Section {
    param([Parameter(Mandatory)][string]$Name)
    Write-Host ''
    Write-Host ('=' * 64)
    Write-Host (' {0}' -f $Name) -ForegroundColor Cyan
    Write-Host ('=' * 64)
}

function Convert-ToVersionSafe {
    param([string]$Text)
    try { return [version]$Text } catch { return $null }
}

function Compare-VersionText {
    param([string]$Installed,[string]$Target)
    $a = Convert-ToVersionSafe $Installed
    $b = Convert-ToVersionSafe $Target
    if ($null -eq $a -or $null -eq $b) { return $null }
    return $a.CompareTo($b)
}

function Get-OptionalPropertyString {
    param([object]$Record,[Parameter(Mandatory)][string]$Name)

    if ($null -eq $Record) { return '' }
    $property = $Record.PSObject.Properties[$Name]
    if ($null -eq $property -or $null -eq $property.Value) { return '' }
    return [string]$property.Value
}

function Get-OfficialPage {
    param(
        [Parameter(Mandatory)][string]$Url,
        [string]$Referer
    )

    if ($script:OfficialPages.ContainsKey($Url)) {
        return $script:OfficialPages[$Url]
    }

    $headers = @{
        'User-Agent' = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/153 Safari/537.36'
        'Accept'     = 'text/html,application/xhtml+xml,application/json;q=0.9,*/*;q=0.8'
    }
    if ($Referer) { $headers['Referer'] = $Referer }

    $r = Invoke-WebRequest -Uri $Url -Headers $headers -WebSession $script:WebSession -UseBasicParsing -TimeoutSec 45 -ErrorAction Stop
    if ($r.StatusCode -lt 200 -or $r.StatusCode -ge 300) {
        throw "HTTP $($r.StatusCode) for $Url"
    }

    $content = [Net.WebUtility]::HtmlDecode([string]$r.Content)
    $content = $content.Replace('\/','/').Replace('\u002F','/').Replace('\u0026','&')
    $script:OfficialPages[$Url] = $content
    return $content
}

function Get-FileSha256 {
    param([Parameter(Mandatory)][string]$Path)
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256 -ErrorAction Stop).Hash.ToUpperInvariant()
}

function Assert-AuthenticodePublisher {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$PublisherRegex
    )

    $sig = Get-AuthenticodeSignature -LiteralPath $Path -ErrorAction Stop

    if ($sig.Status -ne 'Valid') {
        throw "Authenticode signature is not valid for '$Path'. Status: $($sig.Status)"
    }

    $subject = [string]$sig.SignerCertificate.Subject
    if ($subject -notmatch $PublisherRegex) {
        throw "Unexpected signer for '$Path': $subject"
    }

    Write-Host ("Signature  : VALID | {0}" -f $subject)
}

function Download-OfficialFile {
    param(
        [Parameter(Mandatory)][string]$Url,
        [Parameter(Mandatory)][string]$Destination,
        [string]$Referer,
        [string]$ExpectedSha256
    )

    $allowed = @(
        'drivers.amd.com',
        'dlcdnets.asus.com',
        'dlcdnets.asus.com.cn',
        'download.nvidia.com',
        'us.download.nvidia.com',
        'international.download.nvidia.com',
        'uk.download.nvidia.com',
        'de.download.nvidia.com'
    )

    $uri = [Uri]$Url
    if ($uri.Scheme -ne 'https') {
        throw "Refusing non-HTTPS download: $Url"
    }
    if ($allowed -notcontains $uri.Host.ToLowerInvariant()) {
        throw "Refusing non-approved download host: $($uri.Host)"
    }

    New-Item -ItemType Directory -Path (Split-Path -Parent $Destination) -Force | Out-Null

    # ASUS supplies an official SHA-256. AMD/NVIDIA do not; for those EXEs,
    # reuse a previous download only after its URL + SHA-256 have been saved
    # following a VALID vendor signature. Callers validate the signature again
    # even when the file came from this cache.
    $cacheRecordPath = "$Destination.source.json"
    if (Test-Path -LiteralPath $Destination) {
        if ($ExpectedSha256) {
            $have = Get-FileSha256 -Path $Destination
            if ($have -eq $ExpectedSha256.ToUpperInvariant()) {
                Write-Host ("[CACHE OK] {0}" -f $Destination)
                return
            }
        }
        else {
            $verified = $null
            if ($script:VerifiedDownloads.ContainsKey($Destination)) {
                $verified = $script:VerifiedDownloads[$Destination]
            }
            elseif (Test-Path -LiteralPath $cacheRecordPath) {
                try {
                    $saved = Get-Content -LiteralPath $cacheRecordPath -Raw -ErrorAction Stop |
                        ConvertFrom-Json -ErrorAction Stop
                    $savedUrl = Get-OptionalPropertyString -Record $saved -Name 'Url'
                    $savedSha = Get-OptionalPropertyString -Record $saved -Name 'Sha256'
                    if ($savedUrl -eq $Url -and $savedSha -match '^[0-9A-Fa-f]{64}$') {
                        $verified = [pscustomobject]@{ Url = $savedUrl; Sha256 = $savedSha }
                    }
                }
                catch {
                    Write-Warning "Ignoring invalid download-cache record: $cacheRecordPath"
                }
            }
            if ($null -ne $verified -and $verified.Url -eq $Url -and
                (Get-FileSha256 -Path $Destination) -eq $verified.Sha256) {
                $script:VerifiedDownloads[$Destination] = $verified
                Write-Host ("[CACHE OK] URL + SHA-256; publisher signature checked next: {0}" -f $Destination)
                return
            }
        }
        Remove-Item -LiteralPath $Destination -Force -ErrorAction SilentlyContinue
    }

    Write-Host ("Downloading : {0}" -f $Url)

    $headers = @{
        'User-Agent' = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/153 Safari/537.36'
        'Accept'     = '*/*'
    }
    if ($Referer) { $headers['Referer'] = $Referer }

    $bits = Get-Command Start-BitsTransfer -ErrorAction SilentlyContinue

    if ($bits -and -not $Referer) {
        Start-BitsTransfer -Source $Url -Destination $Destination -ErrorAction Stop
    }
    else {
        Invoke-WebRequest `
            -Uri $Url `
            -OutFile $Destination `
            -Headers $headers `
            -WebSession $script:WebSession `
            -UseBasicParsing `
            -TimeoutSec 1800 `
            -ErrorAction Stop
    }

    if (-not (Test-Path -LiteralPath $Destination)) {
        throw "Download did not create: $Destination"
    }

    $size = (Get-Item -LiteralPath $Destination).Length
    if ($size -lt 100KB) {
        throw "Downloaded file is unexpectedly small ($size bytes): $Destination"
    }

    $actualSha = Get-FileSha256 -Path $Destination
    Write-Host ("SHA-256    : {0}" -f $actualSha)

    if ($ExpectedSha256 -and $actualSha -ne $ExpectedSha256.ToUpperInvariant()) {
        throw "SHA-256 mismatch for '$Destination'. Expected $ExpectedSha256, got $actualSha"
    }

    $script:VerifiedDownloads[$Destination] = [pscustomobject]@{
        Url = $Url
        Sha256 = $actualSha
    }
}

function Register-SignedDownloadCache {
    param([Parameter(Mandatory)][string]$Path,[Parameter(Mandatory)][string]$Url)

    # Invoke ONLY after Assert-AuthenticodePublisher succeeds. A partial or
    # modified sidecar never authorizes an install: the next run checks the
    # source URL, recomputes the payload hash and validates its signer again.
    if (-not $script:VerifiedDownloads.ContainsKey($Path)) {
        throw "No verified download state for: $Path"
    }
    $entry = $script:VerifiedDownloads[$Path]
    if ($entry.Url -ne $Url) {
        throw "Download cache source does not match official URL: $Path"
    }
    $record = [pscustomobject]@{ Url = $entry.Url; Sha256 = $entry.Sha256 }
    $record | ConvertTo-Json -Compress |
        Set-Content -LiteralPath "$Path.source.json" -Encoding UTF8 -Force -ErrorAction Stop
}

function Get-DeviceMatchIds {
    param([Parameter(Mandatory)][string]$InstanceId)

    $ids = @()
    foreach ($key in @('DEVPKEY_Device_HardwareIds', 'DEVPKEY_Device_CompatibleIds')) {
        try {
            $p = Get-PnpDeviceProperty -InstanceId $InstanceId -KeyName $key -ErrorAction Stop
            $ids += @($p.Data | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) })
        }
        catch {
            # Some device classes have no compatible-ID property. The hardware
            # IDs remain usable, and a missing property does not identify a driver.
        }
    }

    # Windows can put PCI\VEN_xxxx&DEV_xxxx in Compatible IDs instead of
    # Hardware IDs. Derive only that documented base identity as a fallback
    # when a device property's list is incomplete; never use a vendor-only ID.
    if ($InstanceId -match '^(PCI\\VEN_[0-9A-F]{4}&DEV_[0-9A-F]{4})(?:&|\\)') {
        $ids += $matches[1]
    }

    return @($ids | Select-Object -Unique)
}

function Get-PresentDeviceByHardwareRegex {
    param(
        [Parameter(Mandatory)][string]$HardwareRegex,
        [string]$ClassRegex = '.*'
    )

    $deviceMatches = @()

    foreach ($dev in @(Get-PnpDevice -PresentOnly -ErrorAction SilentlyContinue)) {
        if ([string]$dev.Class -notmatch $ClassRegex) { continue }

        $ids = @(Get-DeviceMatchIds -InstanceId ([string]$dev.InstanceId))
        if ($ids.Count -eq 0) { continue }

        if (@($ids | Where-Object { [string]$_ -match $HardwareRegex }).Count -gt 0) {
            $deviceMatches += [pscustomobject]@{
                Device      = $dev
                HardwareIds = $ids
            }
        }
    }

    return @($deviceMatches)
}

function Get-InfText {
    param([Parameter(Mandatory)][string]$Path)

    try {
        $sr = [IO.StreamReader]::new($Path, $true)
        try { return $sr.ReadToEnd() }
        finally { $sr.Dispose() }
    }
    catch {
        return [IO.File]::ReadAllText($Path, [Text.Encoding]::Default)
    }
}

function Resolve-InfStringToken {
    param([string]$Text,[string]$Value)

    $v = $Value.Trim()
    if ($v -notmatch '^%([^%]+)%$') {
        return $v.Trim('"')
    }

    $token = $matches[1]
    $m = [regex]::Match(
        $Text,
        '(?im)^\s*' + [regex]::Escape($token) +
        '\s*=\s*(?:"(?<quoted>[^"\r\n]*)"|(?<plain>[^;\r\n]*?))\s*(?:;[^\r\n]*)?$'
    )
    if ($m.Success) {
        if ($m.Groups['quoted'].Success) { return $m.Groups['quoted'].Value.Trim() }
        return $m.Groups['plain'].Value.Trim()
    }
    return $v
}

function Get-InfMetadata {
    param([Parameter(Mandatory)][string]$InfPath)

    $text = Get-InfText -Path $InfPath

    $providerRaw = ''
    $providerMatch = [regex]::Match($text, '(?im)^\s*Provider\s*=\s*(.+?)\s*$')
    if ($providerMatch.Success) {
        $providerRaw = $providerMatch.Groups[1].Value.Trim()
    }

    $driverVer = ''
    $driverMatch = [regex]::Match(
        $text,
        '(?im)^\s*DriverVer\s*=\s*[^,\r\n]+,\s*([0-9\.]+)\s*$'
    )
    if ($driverMatch.Success) {
        $driverVer = $driverMatch.Groups[1].Value.Trim()
    }

    [pscustomobject]@{
        Path     = $InfPath
        Provider = Resolve-InfStringToken -Text $text -Value $providerRaw
        Version  = $driverVer
        Text     = $text
    }
}

function Assert-InfCatalogSignature {
    param(
        [Parameter(Mandatory)]$InfMetadata,
        [Parameter(Mandatory)][string]$SearchRoot
    )

    $catalogMatch = [regex]::Match(
        $InfMetadata.Text,
        '(?im)^\s*CatalogFile(?:\.[^=]+)?\s*=\s*"?([^"\r\n]+)"?\s*$'
    )

    if (-not $catalogMatch.Success) {
        throw "INF does not declare a CatalogFile: $($InfMetadata.Path)"
    }

    $catalogName = $catalogMatch.Groups[1].Value.Trim()
    $sameDir = Join-Path (Split-Path -Parent $InfMetadata.Path) $catalogName

    if (Test-Path -LiteralPath $sameDir) {
        $catalogPath = $sameDir
    }
    else {
        $catalogCandidates = @(
            Get-ChildItem -LiteralPath $SearchRoot -Filter $catalogName -File -Recurse -ErrorAction SilentlyContinue
        )

        if ($catalogCandidates.Count -ne 1) {
            throw "Could not uniquely resolve catalog '$catalogName' for INF '$($InfMetadata.Path)'."
        }

        $catalogPath = $catalogCandidates[0].FullName
    }

    $sig = Get-AuthenticodeSignature -LiteralPath $catalogPath -ErrorAction Stop
    if ($sig.Status -ne 'Valid') {
        throw "Driver catalog signature is not valid: '$catalogPath' (status: $($sig.Status))."
    }

    $subject = [string]$sig.SignerCertificate.Subject
    if ($subject -notmatch '(?i)Microsoft Windows Hardware Compatibility Publisher|Microsoft Windows|BenQ|ZOWIE') {
        throw "Unexpected monitor driver catalog signer: $subject"
    }

    Write-Host ("Catalog     : VALID | {0}" -f $subject)
    return $catalogPath
}

function Find-MatchingInf {
    param(
        [Parameter(Mandatory)][string]$RootFolder,
        [Parameter(Mandatory)][string[]]$HardwareIds
    )

    $found = @()

    foreach ($inf in @(Get-ChildItem -LiteralPath $RootFolder -Filter '*.inf' -File -Recurse -ErrorAction SilentlyContinue)) {
        $meta = Get-InfMetadata -InfPath $inf.FullName
        if ([string]::IsNullOrWhiteSpace($meta.Version)) { continue }

        # Only a model entry can bind a device. A hardware ID in a comment,
        # string table or unrelated directive is not sufficient evidence.
        $modelLines = @($meta.Text -split '\r?\n' | Where-Object {
            $_ -match '^\s*[^;\[\]\r\n=]+\s*=\s*[^;\r\n,]+,'
        })
        foreach ($id in $HardwareIds) {
            $modelPattern = '(?i)^\s*[^;\[\]\r\n=]+\s*=\s*[^;\r\n,]+,\s*"?' +
                [regex]::Escape([string]$id) + '"?\s*(?:,|;|$)'
            if (@($modelLines | Where-Object { $_ -match $modelPattern }).Count -gt 0) {
                $found += $meta
                break
            }
        }
    }

    if ($found.Count -eq 0) { return $null }

    if ($found.Count -gt 1) {
        throw ("Several INFs contain a matching model entry; refusing to guess: {0}" -f
            (($found | ForEach-Object { $_.Path }) -join '; '))
    }
    return $found[0]
}

function Expand-ZipFresh {
    param([Parameter(Mandatory)][string]$Zip,[Parameter(Mandatory)][string]$Destination)

    if (Test-Path -LiteralPath $Destination) {
        Remove-Item -LiteralPath $Destination -Recurse -Force
    }
    New-Item -ItemType Directory -Path $Destination -Force | Out-Null

    Expand-Archive -LiteralPath $Zip -DestinationPath $Destination -Force
}

function Resolve-AmdChipsetLatest {
    $html = Get-OfficialPage -Url $AmdChipsetPage

    $m = [regex]::Match(
        $html,
        '(?is)AMD\s+Chipset\s+Drivers.*?Revision\s+Number\s*.*?([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+).*?Release\s+Date'
    )

    if (-not $m.Success) {
        throw 'Could not resolve current AMD B850 chipset version from AMD.'
    }

    $version = $m.Groups[1].Value

    $urlMatch = [regex]::Match(
        $html,
        '(?i)https://drivers\.amd\.com/[^"''<>\s]+AMD_Chipset_Software_' +
        [regex]::Escape($version) +
        '\.exe'
    )

    if (-not $urlMatch.Success) {
        throw "AMD did not publish a direct chipset download link for version $version on its B850 page."
    }
    $url = $urlMatch.Value

    return [pscustomobject]@{
        Name    = 'AMD B850 Chipset'
        Version = $version
        Url     = $url
        Referer = $AmdChipsetPage
    }
}

function Resolve-AsusPackage {
    param(
        [Parameter(Mandatory)][string]$TitleRegex
    )

    $html = Get-OfficialPage -Url $AsusSupportUrl

    # The ASUS support page serializes each package as a compact record:
    # "filename.zip","version","title",...,"/pub/ASUS/.../filename.zip",...,"SHA256"
    # The visible title/version panel has no download URL next to it. Bind all
    # four fields to ONE record, never a window that can cross package boundaries.
    $recordPattern = '(?is)"(?<file>[^"/\\\r\n]+\.zip)","(?<ver>[0-9][0-9A-Za-z\.\-_]{1,40})",' +
        '"(?<title>[^"\r\n]{3,300})"(?<tail>(?:(?!\{"Id":).){0,2000})'
    $records = @()

    foreach ($entry in [regex]::Matches($html, $recordPattern)) {
        if ($entry.Groups['title'].Value -notmatch $TitleRegex) { continue }

        $version = $entry.Groups['ver'].Value
        if ($null -eq (Convert-ToVersionSafe -Text $version)) {
            throw "ASUS package version is not numeric: '$version' for $TitleRegex"
        }

        $tail = $entry.Groups['tail'].Value
        $paths = @([regex]::Matches($tail, '(?i)"(?<path>/pub/ASUS/[^"\r\n]+\.zip)"') |
            ForEach-Object { $_.Groups['path'].Value } | Select-Object -Unique)
        $hashes = @([regex]::Matches($tail, '(?i)"(?<hash>[A-F0-9]{64})"') |
            ForEach-Object { $_.Groups['hash'].Value.ToUpperInvariant() } | Select-Object -Unique)
        $filename = @($entry.Groups['file'].Value -split '@')[-1]
        $valid = ($paths.Count -eq 1 -and $hashes.Count -eq 1)
        if ($valid) {
            $valid = [string]::Equals([IO.Path]::GetFileName($paths[0]),
                $filename, [StringComparison]::OrdinalIgnoreCase)
        }
        $sha = if ($hashes.Count -eq 1) { $hashes[0] } else { '' }
        $url = if ($paths.Count -eq 1) { 'https://dlcdnets.asus.com' + $paths[0] } else { '' }

        $records += [pscustomobject]@{
            Version = $version
            Sha256  = $sha
            Url     = $url
            Valid   = $valid
        }
    }

    if ($records.Count -eq 0) {
        throw "No complete ASUS package record found for: $TitleRegex"
    }

    $sorted = @($records | Sort-Object -Property @{Expression = { [version]$_.Version }} -Descending)
    $latest = $sorted[0]
    foreach ($candidate in @($sorted | Where-Object { $_.Version -eq $latest.Version })) {
        if (-not $candidate.Valid -or $candidate.Url -ne $latest.Url -or
            $candidate.Sha256 -ne $latest.Sha256) {
            throw "Latest ASUS package version $($latest.Version) is incomplete or ambiguous for '$TitleRegex'."
        }
    }

    return [pscustomobject]@{
        Version = $latest.Version
        Sha256  = $latest.Sha256
        Url     = $latest.Url
        Referer = $AsusSupportUrl
    }
}

function Resolve-AmdIgpuRecommendedLatest {
    $html = Get-OfficialPage -Url $AmdIgpuPage

    $m = [regex]::Match(
        $html,
        '(?is)Adrenalin\s+([0-9]+\.[0-9]+\.[0-9]+)\s*\(WHQL\s+Recommended\)'
    )

    if (-not $m.Success) {
        throw 'Could not resolve AMD WHQL Recommended graphics version for Ryzen 7 9800X3D.'
    }

    $version = $m.Groups[1].Value

    $urls = @(
        [regex]::Matches(
            $html,
            '(?i)https://drivers\.amd\.com/[^"''<>\s]+\.exe'
        ) |
        ForEach-Object { $_.Value } |
        Where-Object {
            $_ -match '(?i)whql-amd-software-adrenalin-edition' -and
            $_ -match [regex]::Escape($version)
        } |
        Select-Object -Unique
    )

    if ($urls.Count -eq 0) {
        throw "AMD did not publish a direct WHQL Recommended download link for $version on the 9800X3D page."
    }

    return [pscustomobject]@{
        Version = $version
        Urls    = $urls
        Referer = $AmdIgpuPage
    }
}

function Expand-ArchiveWithWindowsTar {
    param(
        [Parameter(Mandatory)][string]$Archive,
        [Parameter(Mandatory)][string]$Destination
    )

    $tar = Join-Path $env:SystemRoot 'System32\tar.exe'
    if (-not (Test-Path -LiteralPath $tar)) {
        return $false
    }

    if (Test-Path -LiteralPath $Destination) {
        Remove-Item -LiteralPath $Destination -Recurse -Force
    }
    New-Item -ItemType Directory -Path $Destination -Force | Out-Null

    # Current Windows tar is bsdtar/libarchive and supports .7z archives. AMD's
    # package is tested as an archive first; if the SFX wrapper is not readable,
    # caller can use the ASUS OEM VGA fallback instead of guessing.
    & $tar -tf $Archive *> $null
    if ($LASTEXITCODE -ne 0) {
        Remove-Item -LiteralPath $Destination -Recurse -Force -ErrorAction SilentlyContinue
        return $false
    }

    & $tar -xf $Archive -C $Destination
    if ($LASTEXITCODE -ne 0) {
        Remove-Item -LiteralPath $Destination -Recurse -Force -ErrorAction SilentlyContinue
        return $false
    }

    return $true
}

function Resolve-NvidiaLatestGameReady {
    if ($null -ne $script:NvidiaLatest) {
        return $script:NvidiaLatest
    }

    # NVIDIA official driver lookup backend:
    # psid=120 => GeForce RTX 30 Series
    # pfid=929 => GeForce RTX 3080 (including the 12GB variant)
    # osID=57  => Windows 10/11 64-bit driver family
    $query = (
        $NvidiaLookupBase +
        '?func=DriverManualLookup' +
        '&psid=120' +
        '&pfid=929' +
        '&osID=57' +
        '&languageCode=1033' +
        '&beta=0' +
        '&isWHQL=1' +
        '&dltype=1' +
        '&dch=1' +
        '&sort1=0' +
        '&numberOfResults=10'
    )

    $headers = @{
        'User-Agent' = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'
        'Accept' = 'application/json,text/plain,*/*'
        'Referer' = 'https://www.nvidia.com/en-us/geforce/drivers/'
    }

    $raw = Invoke-WebRequest -Uri $query -Headers $headers -WebSession $script:WebSession -UseBasicParsing -TimeoutSec 45 -ErrorAction Stop
    $payload = $raw.Content | ConvertFrom-Json

    if ($null -eq $payload -or $null -eq $payload.PSObject.Properties['IDS']) {
        throw 'NVIDIA lookup did not return an IDS result list.'
    }
    $rows = @($payload.IDS | Where-Object { $null -ne $_ })
    if ($rows.Count -eq 0) {
        throw 'NVIDIA returned no WHQL driver results for RTX 3080.'
    }

    $candidates = @()

    foreach ($row in $rows) {
        $infoProperty = $row.PSObject.Properties['downloadInfo']
        $info = if ($null -ne $infoProperty) { $infoProperty.Value } else { $null }
        if ($null -eq $info) { continue }

        $name = [Uri]::UnescapeDataString((Get-OptionalPropertyString -Record $info -Name 'Name'))
        if ($name -notmatch '(?i)^GeForce\s+Game\s+Ready\s+Driver$') { continue }
        if ((Get-OptionalPropertyString -Record $info -Name 'DownloadTypeID') -ne '1' -or
            (Get-OptionalPropertyString -Record $info -Name 'IsWHQL') -ne '1') { continue }

        $supportedProducts = @(
            foreach ($series in @($info.series)) {
                foreach ($product in @($series.products)) {
                    [Uri]::UnescapeDataString((Get-OptionalPropertyString -Record $product -Name 'productName'))
                }
            }
        )
        if ($supportedProducts -notcontains 'GeForce RTX 3080') { continue }

        $candidateVersion = Get-OptionalPropertyString -Record $info -Name 'Version'
        if ($null -eq (Convert-ToVersionSafe -Text $candidateVersion)) { continue }
        $candidates += $info
    }

    if ($candidates.Count -eq 0) {
        throw 'NVIDIA lookup returned results but no WHQL Game Ready package explicitly supports RTX 3080.'
    }
    $selected = @($candidates | Sort-Object -Property @{
        Expression = { [version](Get-OptionalPropertyString -Record $_ -Name 'Version') }
    } -Descending)[0]

    $version = Get-OptionalPropertyString -Record $selected -Name 'Version'
    $url = Get-OptionalPropertyString -Record $selected -Name 'DownloadURL'

    if ([string]::IsNullOrWhiteSpace($version) -or [string]::IsNullOrWhiteSpace($url)) {
        throw 'NVIDIA result did not include both Version and DownloadURL.'
    }

    $downloadHost = ([Uri]$url).Host.ToLowerInvariant()
    if ($downloadHost -notmatch '(^|\.)download\.nvidia\.com$') {
        throw "NVIDIA returned an unexpected download host: $downloadHost"
    }

    $script:NvidiaLatest = [pscustomobject]@{
        Version = $version
        Url     = $url
        Referer = 'https://www.nvidia.com/en-us/geforce/drivers/'
    }
    return $script:NvidiaLatest
}

function Assert-TargetPlatform {
    $cv = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -ErrorAction Stop
    if ([int]$cv.CurrentBuild -lt 22000) {
        throw "Windows 11 required. Build detected: $($cv.CurrentBuild)"
    }

    $board = Get-CimInstance Win32_BaseBoard -ErrorAction Stop | Select-Object -First 1
    $boardName = [string]$board.Product
    if ($boardName -notmatch '(?i)ROG\s+STRIX\s+B850-I\s+GAMING\s+WIFI') {
        throw "This installer targets ROG STRIX B850-I GAMING WIFI. Detected board: '$boardName'"
    }

    $cpu = Get-CimInstance Win32_Processor -ErrorAction Stop | Select-Object -First 1
    if ([string]$cpu.Name -notmatch '(?i)Ryzen\s+7\s+9800X3D') {
        throw "This installer targets Ryzen 7 9800X3D. Detected CPU: '$($cpu.Name)'"
    }

    $nvidia = @(Get-PresentDeviceByHardwareRegex -HardwareRegex $NvidiaTargetHardwareRegex)
    if ($nvidia.Count -eq 0) {
        throw 'This package targets RTX 3080 12GB (DEV_220A), but it is not present. No driver installation was started. Confirm the current GPU before changing the target.'
    }

    Write-Host ("Board : {0}" -f $boardName)
    Write-Host ("CPU   : {0}" -f $cpu.Name)
    foreach ($record in $nvidia) {
        Write-Host ("GPU   : {0} | {1}" -f $record.Device.FriendlyName,$record.Device.InstanceId)
    }
}


try {
  Write-Host "GAMING DRIVER DOWNLOAD + VERIFY ONLY | v$ScriptVersion"
  Assert-TargetPlatform

  Invoke-DriverDownloadStep 'AMD B850 chipset' {
    $pkg = Resolve-AmdChipsetLatest
    $p = Join-Path $DownloadRoot ("AMD_Chipset_Software_{0}.exe" -f $pkg.Version)
    Download-OfficialFile -Url $pkg.Url -Destination $p -Referer $pkg.Referer
    Assert-AuthenticodePublisher -Path $p -PublisherRegex '(?i)Advanced Micro Devices|AMD'
    Register-SignedDownloadCache -Path $p -Url $pkg.Url
    Save-DriverReady 'AMD B850 chipset' $pkg.Version $p $pkg.Url 'Manually run official AMD chipset installer; reboot and verify package version.'
  }
  Invoke-DriverDownloadStep 'Intel I226-V LAN' {
    $devices = @(Get-PresentDeviceByHardwareRegex -HardwareRegex '^PCI\\VEN_8086&DEV_125C(?:&|$)')
    if($devices.Count -ne 1) { throw "Expected one present I226-V DEV_125C, found $($devices.Count)" }
    $pkg=Resolve-AsusPackage -TitleRegex '(?i)Intel\s+I225/I226\s+LAN\s+driver'
    $p=Join-Path $DownloadRoot ("ASUS-Intel-I226-LAN-{0}.zip" -f $pkg.Version)
    Download-OfficialFile -Url $pkg.Url -Destination $p -Referer $pkg.Referer -ExpectedSha256 $pkg.Sha256
    $unpack=Join-Path $ExtractRoot ("Intel-I226-LAN-{0}" -f $pkg.Version)
    Expand-ZipFresh -Zip $p -Destination $unpack
    $inf=Find-MatchingInf -RootFolder $unpack -HardwareIds $devices[0].HardwareIds
    if(-not $inf -or $inf.Provider -notmatch '(?i)Intel') { throw 'No exact I226-V Intel INF match found in verified ASUS package.' }
    Save-DriverReady 'Intel I226-V LAN' $pkg.Version $p $pkg.Url ("Manual Device Manager INF: {0} ; DriverVer {1}" -f $inf.Path,$inf.Version)
  }
  Invoke-DriverDownloadStep 'Realtek UCM' {
    $devices=@(Get-PresentDeviceByHardwareRegex -HardwareRegex '^ACPI\\RTK5452')
    if($devices.Count -eq 0) {
      $script:Rows.Add([pscustomobject]@{Component='Realtek UCM';Status='NOT PRESENT';Version='';File='';SHA256='';Source='';ManualInstructions='Exact ACPI RTK5452 device not present; skip.'})
    } else {
      $pkg=Resolve-AsusPackage -TitleRegex '(?i)Realtek\s+UCM\s+driver'
      $p=Join-Path $DownloadRoot ("ASUS-Realtek-UCM-{0}.zip" -f $pkg.Version)
      Download-OfficialFile -Url $pkg.Url -Destination $p -Referer $pkg.Referer -ExpectedSha256 $pkg.Sha256
      $unpack=Join-Path $ExtractRoot ("Realtek-UCM-{0}" -f $pkg.Version)
      Expand-ZipFresh -Zip $p -Destination $unpack
      foreach($dev in $devices) {
        $inf=Find-MatchingInf -RootFolder $unpack -HardwareIds $dev.HardwareIds
        if(-not $inf -or $inf.Provider -notmatch '(?i)Realtek') {throw 'Realtek UCM INF/provider not matched.'}
      }
      Save-DriverReady 'Realtek UCM' $pkg.Version $p $pkg.Url 'Install matching UCM INF manually from Work\\Drivers\\Extracted; verify device.'
    }
  }
  Invoke-DriverDownloadStep 'AMD 9800X3D iGPU' {
    $devices=@(Get-PresentDeviceByHardwareRegex -HardwareRegex '^PCI\\VEN_1002&DEV_13C0(?:&|$)')
    if($devices.Count -eq 0) {
      $script:Rows.Add([pscustomobject]@{Component='AMD 9800X3D iGPU';Status='NOT PRESENT';Version='';File='';SHA256='';Source='';ManualInstructions='No matching AMD display device; skip.'})
    } else {
      $pkg=Resolve-AmdIgpuRecommendedLatest
      $success=$false
      foreach($url in @($pkg.Urls)) {
        try {
          $p=Join-Path $DownloadRoot ("AMD-iGPU-WHQL-{0}.exe" -f $pkg.Version)
          Download-OfficialFile -Url $url -Destination $p -Referer $pkg.Referer
          Assert-AuthenticodePublisher -Path $p -PublisherRegex '(?i)Advanced Micro Devices|AMD'
          Register-SignedDownloadCache -Path $p -Url $url
          Save-DriverReady 'AMD 9800X3D iGPU' $pkg.Version $p $url 'Official AMD Adrenalin container; DO NOT run full setup if driver-only is desired. Extract, select matching Display INF manually; otherwise defer.'
          $success=$true
          break
        } catch { Write-Warning $_.Exception.Message }
      }
      if(-not $success) {throw 'No signed official AMD Recommended iGPU package could be resolved.'}
    }
  }
  Invoke-DriverDownloadStep 'NVIDIA RTX 3080 GRD' {
    $pkg=Resolve-NvidiaLatestGameReady
    $p=Join-Path $DownloadRoot ("NVIDIA-GRD-{0}.exe" -f $pkg.Version)
    Download-OfficialFile -Url $pkg.Url -Destination $p -Referer $pkg.Referer
    Assert-AuthenticodePublisher -Path $p -PublisherRegex '(?i)NVIDIA'
    Register-SignedDownloadCache -Path $p -Url $pkg.Url
    Save-DriverReady 'NVIDIA RTX 3080 WHQL Game Ready' $pkg.Version $p $pkg.Url 'Manual CUSTOM installer selection: Graphics Driver only; do not select NVIDIA App / HD Audio. Verify display driver, reboot.'
  }
  Invoke-DriverDownloadStep 'BenQ ZOWIE XL2566X+ monitor INF' {
    if(-not (Test-Path -LiteralPath $MonitorPackagePath -PathType Leaf)) {throw "Bundled package missing: $MonitorPackagePath"}
    if((Get-FileSha256 -Path $MonitorPackagePath) -ne $MonitorPackageSha256) {throw 'Bundled ZOWIE WHQL archive SHA256 mismatch.'}
    $dest=Join-Path $DownloadRoot 'ZOWIE-XL2566X+-V001.7z'
    Copy-Item -LiteralPath $MonitorPackagePath -Destination $dest -Force
    $unpack=Join-Path $ExtractRoot 'ZOWIE-XL2566X+-V001'
    if(-not (Expand-ArchiveWithWindowsTar -Archive $dest -Destination $unpack)) {throw 'ZOWIE 7z extraction/inspection failed.'}
    $infFiles = @(Get-ChildItem -LiteralPath $unpack -Filter '*.inf' -File -Recurse)
    if($infFiles.Count -eq 0) { throw 'ZOWIE bundle contains no INF files.' }
    foreach($inf in $infFiles) {
      $meta=Get-InfMetadata -InfPath $inf.FullName
      $null=Assert-InfCatalogSignature -InfMetadata $meta -SearchRoot $unpack
    }
    Save-DriverReady 'ZOWIE XL2566X+ monitor INF' 'V001' $dest 'Bundled official WHQL file' 'Manually bind only the matching monitor INF from Work\\Drivers\\Extracted; verify monitor ID and driver binding.'
  }
}
catch {
  Write-DriverFailure 'PRECHECK' $_.Exception.Message
}
finally {
  try {
    $csv=Join-Path $DownloadRoot 'DRIVER_MANUAL_INSTALL_ORDER.csv'
    $json=Join-Path $LogRoot "driver-download-$Stamp.json"
    $script:Rows | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $json -Encoding UTF8
    $script:Rows | Export-Csv -LiteralPath $csv -NoTypeInformation -Encoding UTF8
    Write-Host "Manifest : $csv"
    Write-Host "Log      : $LogFile"
    Write-Host "MS Store NVIDIA Control Panel (manual): https://apps.microsoft.com/detail/9NF8H0H7WMLT"
    Write-Host "Status: $($script:Failures) failed components; NO INSTALLATION was attempted."
  } finally {
    try {Stop-Transcript | Out-Null} catch {}
  }
}
if($script:Failures -gt 0) {exit 1}
exit 0
