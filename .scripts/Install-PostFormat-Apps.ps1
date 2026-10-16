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
  Invoke-WebRequest -Uri $Url -OutFile $dest -UseBasicParsing -TimeoutSec 1800 -ErrorAction Stop
  if((Get-Item -LiteralPath $dest -ErrorAction Stop).Length -lt 102400){throw 'Downloaded file unexpectedly small.'}
  $hash=Get-FileHashValue $dest
  if($ExpectedSha -and $hash -ne $ExpectedSha.ToUpperInvariant()){throw "SHA256 mismatch: $hash"}
  $signature=Get-AuthenticodeSignature -LiteralPath $dest -ErrorAction Stop
  $subject=if($signature.SignerCertificate){[string]$signature.SignerCertificate.Subject}else{''}
  if($signature.Status -ne 'Valid' -or $subject -notmatch $PublisherRegex){throw "Invalid publisher signature: status=$($signature.Status); signer=$subject"}
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
  $prev=$ErrorActionPreference
  try {
    $ErrorActionPreference='Continue'
    & $script:WinGetPath @args 2>&1 | ForEach-Object {Write-Host ("  {0}" -f $_)}
    $rc=[int]$LASTEXITCODE
  } finally {$ErrorActionPreference=$prev}
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

try {
 Write-Host 'APP PACKAGE DOWNLOAD + VERIFY ONLY (never install)'
 $winget=Get-Command winget.exe -ErrorAction SilentlyContinue
 if($winget){
  $script:WinGetPath=$winget.Source
  $old=$ErrorActionPreference
  try{
   $ErrorActionPreference='Continue'
   & $script:WinGetPath download --help *> $null
   $rc=[int]$LASTEXITCODE
  } finally {$ErrorActionPreference=$old}
  if($rc -ne 0){throw 'WinGet download command unavailable. Manually update Microsoft App Installer, then retry.'}
  $packages=@(
   @{Id='Microsoft.VCRedist.2008.x86';Name='Visual C++ 2008 x86'},
   @{Id='Microsoft.VCRedist.2008.x64';Name='Visual C++ 2008 x64'},
   @{Id='Microsoft.VCRedist.2010.x86';Name='Visual C++ 2010 x86'},
   @{Id='Microsoft.VCRedist.2010.x64';Name='Visual C++ 2010 x64'},
   @{Id='Microsoft.VCRedist.2012.x86';Name='Visual C++ 2012 x86'},
   @{Id='Microsoft.VCRedist.2012.x64';Name='Visual C++ 2012 x64'},
   @{Id='Microsoft.VCRedist.2013.x86';Name='Visual C++ 2013 x86'},
   @{Id='Microsoft.VCRedist.2013.x64';Name='Visual C++ 2013 x64'},
   @{Id='Microsoft.VCRedist.2015+.x86';Name='Visual C++ current x86'},
   @{Id='Microsoft.VCRedist.2015+.x64';Name='Visual C++ current x64'},
   @{Id='Google.Chrome';Name='Google Chrome'},
   @{Id='AutoHotkey.AutoHotkey';Name='AutoHotkey v2'},
   @{Id='FACEITLTD.FACEITAC';Name='FACEIT Anti-Cheat only'},
   @{Id='Spotify.Spotify';Name='Spotify'},
   @{Id='Valve.Steam';Name='Steam'}
  )
  foreach($pkg in $packages){
   $instruction='Install manually, verify publisher/version; no silent switches or bundled optional extras.'
   if($pkg.Id -eq 'FACEITLTD.FACEITAC'){$instruction='Manually install FACEIT Anti-Cheat; verify separate FACEIT platform client absent.'}
   if($pkg.Id -eq 'Spotify.Spotify'){$instruction='Install in standard user session; if WinGet hash mismatch occurs the download must fail.'}
   Invoke-WinGetDownload -Id $pkg.Id -Label $pkg.Name -Instructions $instruction
  }
 } else {Fail-Entry 'WinGet downloads' 'WinGet is missing. Install/update App Installer manually.'}

 Invoke-PublisherDownload 'DirectX June 2010 offline' 'https://download.microsoft.com/download/8/4/a/84a35bf1-dafe-4ae8-82af-ad2ae20b6b14/directx_Jun2010_redist.exe' 'directx_Jun2010_redist.exe' '(?i)Microsoft' '' 'Manually extract and run DXSETUP.exe; verify legacy components.'
 Invoke-PublisherDownload 'TeamSpeak 3.6.2' 'https://files.teamspeak-services.com/releases/client/3.6.2/TeamSpeak3-Client-win64-3.6.2.exe' 'TeamSpeak3-Client-win64-3.6.2.exe' '(?i)TeamSpeak' 'EAB9E0C1A7134643E5F7116B7E0E58FAFFB20D6DB528F8B333D2C2B5D1AB68AE' 'Manually install 3.6.2 without optional Overwolf; verify no Overwolf.'
 Invoke-PublisherDownload 'Logitech Onboard Memory Manager' 'https://download01.logi.com/web/ftp/pub/techsupport/gaming/OnboardMemoryManager_2.3.2055.exe' 'OnboardMemoryManager_2.3.2055.exe' '(?i)Logitech|Logi' '' 'Manually install OMM after verifying release/version.'
 Add-Entry 'NVIDIA Control Panel HSA' 'MANUAL LINK' 'https://apps.microsoft.com/detail/9NF8H0H7WMLT' '' '' 'Install manually from Microsoft Store after NVIDIA display driver.'
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
