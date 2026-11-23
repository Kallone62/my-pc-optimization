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
$VcRoot=Join-Path $DownloadRoot 'VisualCpp_AllInOne'
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
 param([string]$Id,[string]$Label,[string]$Instructions,[string]$TargetRoot=$DownloadRoot)
 $folder=Join-Path $TargetRoot $Id
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

function Publish-VcBundle {
 param([object[]]$Packages)
 $manifest=Join-Path $VcRoot 'VC_PACKAGES.csv'
 $rows=New-Object 'System.Collections.Generic.List[object]'
 try{
  New-Item -ItemType Directory -Path $VcRoot -Force | Out-Null
  $base=[IO.Path]::GetFullPath($VcRoot).TrimEnd('\')+'\'
  foreach($p in $Packages){
   $items=@($script:Rows | Where-Object {$_.Component -eq $p.Name -and $_.Status -eq 'READY' -and $_.Source -like ('winget:'+$p.Id+' *')})
   if($items.Count -ne 1){throw "Incomplete VC++ package: $($p.Id)"}
   $item=$items[0]
   $file=[IO.Path]::GetFullPath([string]$item.File)
   if(-not $file.StartsWith($base,[StringComparison]::OrdinalIgnoreCase) -or -not $file.EndsWith('.exe',[StringComparison]::OrdinalIgnoreCase)){throw "Unexpected VC++ executable: $file"}
   $sig=Get-AuthenticodeSignature -LiteralPath $file -ErrorAction Stop
   if($sig.Status -ne 'Valid' -or -not $sig.SignerCertificate -or $sig.SignerCertificate.Subject -notmatch '(?i)Microsoft'){throw "Microsoft signature check failed: $file"}
   $rows.Add([pscustomobject]@{Id=$p.Id;RelativeFile=$file.Substring($base.Length);SHA256=$item.SHA256})
  }
  foreach($name in @('Install_All_VisualCpp.cmd','Install_All_VisualCpp.ps1')){
   $source=Join-Path $PSScriptRoot $name
   if(-not (Test-Path -LiteralPath $source -PathType Leaf)){throw "Missing template: $source"}
   Copy-Item -LiteralPath $source -Destination (Join-Path $VcRoot $name) -Force -ErrorAction Stop
  }
  $rows | Export-Csv -LiteralPath $manifest -NoTypeInformation -Encoding UTF8
  Add-Entry 'Visual C++ All-in-One' 'READY' 'Microsoft via WinGet' (Join-Path $VcRoot 'Install_All_VisualCpp.cmd') '' 'Run as administrator after download; local installer verifies all 12 files before installation.'
 }catch{
  Remove-Item -LiteralPath $manifest -Force -ErrorAction SilentlyContinue
  Fail-Entry 'Visual C++ All-in-One' $_.Exception.Message
 }
}
try {
 Write-Host 'APP PACKAGE DOWNLOAD + VERIFY ONLY (never install)'
 # Independent official downloads first, including when WinGet is missing.
 Invoke-PublisherDownload 'DirectX June 2010 offline' 'https://download.microsoft.com/download/8/4/a/84a35bf1-dafe-4ae8-82af-ad2ae20b6b14/directx_Jun2010_redist.exe' 'directx_Jun2010_redist.exe' '(?i)Microsoft' '' 'Manually extract and run DXSETUP.exe; verify legacy components.'
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

  # TechPowerUp-style one-folder/one-CMD bundle; all source packages stay Microsoft-signed.
  $vc=@(
   @{Id='Microsoft.VCRedist.2015+.x86';Name='Visual C++ v14 x86'},
   @{Id='Microsoft.VCRedist.2015+.x64';Name='Visual C++ v14 x64'},
   @{Id='Microsoft.VCRedist.2013.x86';Name='Visual C++ 2013 x86'},
   @{Id='Microsoft.VCRedist.2013.x64';Name='Visual C++ 2013 x64'},
   @{Id='Microsoft.VCRedist.2012.x86';Name='Visual C++ 2012 x86'},
   @{Id='Microsoft.VCRedist.2012.x64';Name='Visual C++ 2012 x64'},
   @{Id='Microsoft.VCRedist.2010.x86';Name='Visual C++ 2010 x86'},
   @{Id='Microsoft.VCRedist.2010.x64';Name='Visual C++ 2010 x64'},
   @{Id='Microsoft.VCRedist.2008.x86';Name='Visual C++ 2008 x86'},
   @{Id='Microsoft.VCRedist.2008.x64';Name='Visual C++ 2008 x64'},
   @{Id='Microsoft.VCRedist.2005.x86';Name='Visual C++ 2005 x86'},
   @{Id='Microsoft.VCRedist.2005.x64';Name='Visual C++ 2005 x64'}
  )
  foreach($p in $vc){
   Invoke-WinGetDownload -Id $p.Id -Label $p.Name -TargetRoot $VcRoot -Instructions 'Install via VisualCpp_AllInOne\Install_All_VisualCpp.cmd once all runtimes are READY.'
  }
  Publish-VcBundle -Packages $vc

  # Known failure-prone downloads last; individual errors do not stop other packages.
  Invoke-WinGetDownload -Id 'FACEITLTD.FACEITAC' -Label 'FACEIT Anti-Cheat only' -Instructions 'Manual FACEIT AC install; verify separate FACEIT platform client absent.'
  Invoke-WinGetDownload -Id 'Spotify.Spotify' -Label 'Spotify' -Instructions 'Manual install; hash mismatch must fail instead of bypassing security.'
 }else{
  Fail-Entry 'Visual C++ All-in-One' 'WinGet is unavailable, so runtime bundle cannot be prepared.'
 }

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
