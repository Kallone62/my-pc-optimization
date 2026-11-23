#requires -Version 5.1
<#
DOWNLOAD + VERIFY ONLY. No install/uninstall/registry edits.
WinGet's download command checks the installer SHA-256 against the manifest.
Manual installation is always separate.
#>
[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12
# Windows PowerShell 5.1 web-request progress drawing can slow large transfers.
$ProgressPreference='SilentlyContinue'
. (Join-Path $PSScriptRoot 'Download-Transport.ps1')
$PackRoot=Split-Path -Parent $PSScriptRoot
$DownloadRoot=Join-Path $PackRoot 'Downloads\Apps'
$LogRoot=Join-Path $PackRoot 'Logs\PostFormat'
foreach($dir in @($DownloadRoot,$LogRoot)){New-Item -ItemType Directory -Path $dir -Force | Out-Null}
$stamp=Get-Date -Format 'yyyyMMdd-HHmmss'
$LogFile=Join-Path $LogRoot "app-download-$stamp.log"
$script:Rows=New-Object System.Collections.Generic.List[object]
$script:Failures=0
Start-Transcript -Path $LogFile -Force | Out-Null

function Add-Entry {
 param([string]$Name,[string]$Status,[string]$Source,[string]$Path,[string]$Hash,[string]$Instructions)
 $script:Rows.Add([pscustomobject]@{Component=$Name;Status=$Status;Source=$Source;File=$Path;SHA256=$Hash;ManualInstructions=$Instructions})
 Write-Host "[$Status] $Name"
}
function Fail-Entry {
 param([string]$Name,[string]$Message)
 $script:Failures++
 Add-Entry $Name 'FAILED' '' '' '' $Message
}
function Get-FileHashValue {
 param([string]$Path)
 (Get-FileHash -Algorithm SHA256 -LiteralPath $Path -ErrorAction Stop).Hash.ToUpperInvariant()
}
function Invoke-PublisherDownload {
 param([string]$Name,[string]$Url,[string]$Filename,[string]$PublisherRegex,[string]$ExpectedSha,[string]$Instructions)
 try {
  $u=[Uri]$Url
  if($u.Scheme -ne 'https'){throw 'HTTPS required.'}
  $allow=@('download.microsoft.com','files.teamspeak-services.com','download01.logi.com')
  if($allow -notcontains $u.Host.ToLowerInvariant()){throw "Unapproved publisher host: $($u.Host)"}
  $dest=Join-Path $DownloadRoot $Filename
  $receipt="$dest.source.json"
  $reusable=$false
  if((Test-Path -LiteralPath $dest -PathType Leaf) -and (Test-Path -LiteralPath $receipt -PathType Leaf)){
   try{
    $record=Get-Content -LiteralPath $receipt -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
    $reusable=($record.Url -ceq $Url -and $record.SHA256 -match '^[A-Fa-f0-9]{64}$' -and (Get-FileHashValue $dest) -eq $record.SHA256)
   }catch{$reusable=$false}
  }
  if(-not $reusable){ Save-HttpsPayload -Url $Url -Destination $dest }
  else{ Write-Host "[CACHE OK] $Filename" }
  if((Get-Item -LiteralPath $dest -ErrorAction Stop).Length -lt 102400){throw 'Downloaded file unexpectedly small.'}
  $hash=Get-FileHashValue $dest
  if($ExpectedSha -and $hash -ne $ExpectedSha.ToUpperInvariant()){throw "SHA256 mismatch: $hash"}
  $signature=Get-AuthenticodeSignature -LiteralPath $dest -ErrorAction Stop
  $subject=if($signature.SignerCertificate){[string]$signature.SignerCertificate.Subject}else{''}
  if($signature.Status -ne 'Valid' -or $subject -notmatch $PublisherRegex){throw "Invalid publisher signature: status=$($signature.Status); signer=$subject"}
  if(-not $reusable){
   @{Url=$Url;SHA256=$hash} | ConvertTo-Json -Compress | Set-Content -LiteralPath $receipt -Encoding UTF8
  }
  Add-Entry $Name 'READY' $Url $dest $hash $Instructions
 }catch {Fail-Entry $Name $_.Exception.Message}
}
function Invoke-WinGetDownload {
 param([string]$Id,[string]$Label,[string]$Instructions)
 $folder=Join-Path $DownloadRoot $Id
 try {
  # Drop older package payloads before marking new manifest files READY.
  if(Test-Path -LiteralPath $folder -PathType Container) {
    Remove-Item -LiteralPath $folder -Recurse -Force -ErrorAction Stop
  }
  New-Item -ItemType Directory -Path $folder -Force | Out-Null
  $args=@('download','--id',$Id,'--exact','--source','winget','--download-directory',$folder,'--accept-source-agreements','--accept-package-agreements','--disable-interactivity')
  Write-Host "Downloading WinGet package $Id (NO INSTALL)"
  $clock=[Diagnostics.Stopwatch]::StartNew()
  $prev=$ErrorActionPreference
  try {
    $ErrorActionPreference='Continue'
    & $script:WinGetPath @args 2>&1 | ForEach-Object {Write-Host ("  {0}" -f $_)}
    $rc=[int]$LASTEXITCODE
  } finally {$ErrorActionPreference=$prev}
  $clock.Stop()
  Write-Host ("WinGet resolve+download: {0:N1}s for {1}" -f $clock.Elapsed.TotalSeconds,$Id)
  if($rc -ne 0){throw "WinGet download failed: $rc; security hash enforcement remains enabled."}
  $files=@(Get-ChildItem -LiteralPath $folder -File -Recurse -ErrorAction Stop | Where-Object {$_.Extension -match '(?i)^\.(exe|msi|msix|msixbundle|appx|appxbundle|zip)$'})
  if($files.Count -eq 0){throw 'No installer found after WinGet download returned success.'}
  foreach($file in $files){
   if($file.Length -lt 10240){throw "Implausibly small installer: $($file.FullName)"}
   $hash=Get-FileHashValue $file.FullName
   $sig=Get-AuthenticodeSignature -LiteralPath $file.FullName -ErrorAction SilentlyContinue
   $sigState=if($sig){[string]$sig.Status}else{'Unavailable'}
   Add-Entry $Label 'READY' "winget:$Id ; Authenticode=$sigState" $file.FullName $hash $Instructions
  }
 } catch {Fail-Entry $Label $_.Exception.Message}
}

function Invoke-TechPowerUpVisualCpp {
 # Resolve current filename and SHA256 from the publisher's canonical release page.
 $page='https://www.techpowerup.com/download/visual-c-redistributable-runtime-package-all-in-one/'
 try{
  $response=Invoke-WebRequest -Uri $page -UseBasicParsing -TimeoutSec 60 -Headers @{'User-Agent'='Mozilla/5.0 (Windows NT 10.0; Win64; x64)'} -ErrorAction Stop
  $plain=[Net.WebUtility]::HtmlDecode(([string]$response.Content -replace '(?s)<[^>]+>',' ')) -replace '\s+',' '
  $rx='(?i)Visual-C-Runtimes-All-in-One-(?<v>[A-Za-z]+-20\d{2})\.zip.{0,350}?SHA256\s*:\s*(?<sha>[0-9a-f]{64})'
  $matches=[regex]::Matches($plain,$rx)
  $found=New-Object 'System.Collections.Generic.List[object]'
  foreach($m in $matches){
   try{$date=[datetime]::ParseExact($m.Groups['v'].Value,'MMM-yyyy',[Globalization.CultureInfo]::InvariantCulture)}
   catch{continue}
   $found.Add([pscustomobject]@{Date=$date;Version=$m.Groups['v'].Value;Sha=$m.Groups['sha'].Value.ToUpperInvariant()})
  }
  if($found.Count -eq 0){throw 'Could not verify current TechPowerUp release metadata (filename and SHA256).'}
  $latest=$found | Sort-Object Date -Descending | Select-Object -First 1
  $name='Visual-C-Runtimes-All-in-One-'+$latest.Version+'.zip'
  # TechPowerUp's closest-dl dispatcher routes to a geographically appropriate mirror.
  # No third-party mirror or unverified archive is accepted.
  $url='https://closest-dl.techpowerup.com/files/'+$name
  $dest=Join-Path $DownloadRoot $name
  if(Test-Path -LiteralPath $dest -PathType Leaf){
   if((Get-FileHashValue $dest) -eq $latest.Sha){Write-Host "[CACHE OK] $name"}
   else{Remove-Item -LiteralPath $dest -Force -ErrorAction Stop}
  }
  if(-not (Test-Path -LiteralPath $dest -PathType Leaf)){
   Save-HttpsPayload -Url $url -Destination $dest
  }
  if((Get-Item -LiteralPath $dest -ErrorAction Stop).Length -lt 10MB){throw "TechPowerUp ZIP unexpectedly small."}
  $hash=Get-FileHashValue $dest
  if($hash -ne $latest.Sha){throw "TechPowerUp SHA256 mismatch: expected $($latest.Sha), actual $hash"}
  Add-Type -AssemblyName System.IO.Compression.FileSystem
  $archive=[IO.Compression.ZipFile]::OpenRead($dest)
  try{
   $names=@($archive.Entries | ForEach-Object {$_.Name})
   if($names -notcontains 'install_all.bat'){throw 'TechPowerUp package is missing install_all.bat.'}
   if(@($names | Where-Object {$_ -match '(?i)\.exe$'}).Count -lt 8){throw 'Visual C++ installer files missing from ZIP.'}
  }finally{$archive.Dispose()}
  Add-Entry 'Visual C++ All-in-One (TechPowerUp)' 'READY' $page $dest $hash "Verified $($latest.Version) ZIP. Extract, then run included install_all.bat as Administrator. No automatic install."
 }catch{
  Fail-Entry 'Visual C++ All-in-One (TechPowerUp)' ($_.Exception.Message+' | Manual fallback: '+$page)
 }
}

try {
 Write-Host 'APP PACKAGE DOWNLOAD + VERIFY ONLY (never install)'
 # Independent official downloads first, including when WinGet is missing.
 Invoke-PublisherDownload 'DirectX End-User Runtime Web Installer' 'https://download.microsoft.com/download/1/7/1/1718ccc4-6315-4d8e-9543-8e28a4e18c4c/dxwebsetup.exe' 'dxwebsetup.exe' '(?i)Microsoft' '' 'Run web installer manually while online; downloads required legacy components during installation.'
 Invoke-PublisherDownload 'Logitech Onboard Memory Manager' 'https://download01.logi.com/web/ftp/pub/techsupport/gaming/OnboardMemoryManager_2.3.2055.exe' 'OnboardMemoryManager_2.3.2055.exe' '(?i)Logitech|Logi' '' 'Manually install OMM after verifying release/version.'

 $winget=Get-Command winget.exe -ErrorAction SilentlyContinue
 $wingetReady=$false
 if($winget){
  $script:WinGetPath=$winget.Source
  try{
   $previous=$ErrorActionPreference
   try{
    $ErrorActionPreference='Continue'
    & $script:WinGetPath download --help *> $null
    $code=[int]$LASTEXITCODE
   }finally{$ErrorActionPreference=$previous}
   if($code -ne 0){throw "WinGet download unavailable: $code"}
   $wingetReady=$true
  }catch{Fail-Entry 'WinGet preflight' $_.Exception.Message}
 }else{Fail-Entry 'WinGet preflight' 'WinGet is missing; install/update App Installer.'}

 if($wingetReady){
  foreach($p in @(
   @{Id='Google.Chrome';Name='Google Chrome'},
   @{Id='AutoHotkey.AutoHotkey';Name='AutoHotkey v2'},
   @{Id='Valve.Steam';Name='Steam'}
  )){
   Invoke-WinGetDownload -Id $p.Id -Label $p.Name -Instructions 'Manual installation; verify publisher and version.'
  }

  # Known failure-prone downloads last; individual errors do not stop other packages.
  Invoke-WinGetDownload -Id 'FACEITLTD.FACEITAC' -Label 'FACEIT Anti-Cheat only' -Instructions 'Manual FACEIT AC install; verify separate FACEIT platform client absent.'
  Invoke-WinGetDownload -Id 'Spotify.Spotify' -Label 'Spotify' -Instructions 'Manual install; hash mismatch must fail instead of bypassing security.'
 }else{
  Write-Warning 'WinGet unavailable: other WinGet app packages skipped.'
 }

 # Single direct publisher archive replaces 12 sequential WinGet runtime downloads.
 Invoke-TechPowerUpVisualCpp

 Invoke-PublisherDownload 'TeamSpeak 3.6.2' 'https://files.teamspeak-services.com/releases/client/3.6.2/TeamSpeak3-Client-win64-3.6.2.exe' 'TeamSpeak3-Client-win64-3.6.2.exe' '(?i)TeamSpeak' 'EAB9E0C1A7134643E5F7116B7E0E58FAFFB20D6DB528F8B333D2C2B5D1AB68AE' 'Manually install 3.6.2 without optional Overwolf; verify no Overwolf.'
 Add-Entry 'NVIDIA Control Panel HSA' 'MANUAL LINK' 'https://apps.microsoft.com/detail/9NF8H0H7WMLT' '' '' 'Install through separate Downloads\Drivers CMD after the NVIDIA driver.'
 Add-Entry 'Wootility Web' 'MANUAL LINK' 'https://v5.wootility.io/' '' '' 'Open in browser; no offline installer.'
 Add-Entry 'ExitLag optional' 'MANUAL LINK' 'https://www.exitlag.com/download/' '' '' 'Optional, download/install manually.'
} catch {Fail-Entry 'Preflight' $_.Exception.Message}
finally{
 $csv=Join-Path $DownloadRoot 'APP_MANUAL_INSTALL_ORDER.csv'
 $json=Join-Path $LogRoot "app-download-$stamp.json"
 $script:Rows | Export-Csv -LiteralPath $csv -NoTypeInformation -Encoding UTF8
 $script:Rows | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $json -Encoding UTF8
 Write-Host "Manifest: $csv ; Log: $LogFile ; Failures: $($script:Failures)"
 try{Stop-Transcript | Out-Null}catch{}
}
if($script:Failures -gt 0){exit 1}
exit 0
