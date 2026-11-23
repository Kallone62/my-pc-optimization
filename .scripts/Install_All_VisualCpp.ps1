#requires -Version 5.1
# Explicit post-download installer; never invoked by the download script.
[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$ids=@(
 'Microsoft.VCRedist.2015+.x86',
 'Microsoft.VCRedist.2015+.x64',
 'Microsoft.VCRedist.2013.x86',
 'Microsoft.VCRedist.2013.x64',
 'Microsoft.VCRedist.2012.x86',
 'Microsoft.VCRedist.2012.x64',
 'Microsoft.VCRedist.2010.x86',
 'Microsoft.VCRedist.2010.x64',
 'Microsoft.VCRedist.2008.x86',
 'Microsoft.VCRedist.2008.x64',
 'Microsoft.VCRedist.2005.x86',
 'Microsoft.VCRedist.2005.x64'
)
try{
 $principal=New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
 if(-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)){throw 'Run Install_All_VisualCpp.cmd as Administrator.'}
 $manifest=Join-Path $PSScriptRoot 'VC_PACKAGES.csv'
 if(-not (Test-Path -LiteralPath $manifest -PathType Leaf)){throw 'VC_PACKAGES.csv missing; rerun downloader until all packages are READY.'}
 $rows=@(Import-Csv -LiteralPath $manifest -ErrorAction Stop)
 if($rows.Count -ne $ids.Count){throw "Incomplete runtime bundle: $($rows.Count)/$($ids.Count)."}
 $root=[IO.Path]::GetFullPath($PSScriptRoot).TrimEnd('\')+'\'
 $verified=New-Object 'System.Collections.Generic.List[object]'
 # Verify every package BEFORE attempting any installation.
 for($i=0;$i -lt $ids.Count;$i++){
  $entry=$rows[$i]
  if($entry.Id -cne $ids[$i]){throw "Unexpected VC++ package in row $($i+1)."}
  $path=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot $entry.RelativeFile))
  if(-not $path.StartsWith($root,[StringComparison]::OrdinalIgnoreCase) -or -not $path.EndsWith('.exe',[StringComparison]::OrdinalIgnoreCase)){throw "Invalid installer path: $path"}
  if(-not (Test-Path -LiteralPath $path -PathType Leaf)){throw "Installer missing: $path"}
  $hash=(Get-FileHash -LiteralPath $path -Algorithm SHA256 -ErrorAction Stop).Hash
  if($hash -ne $entry.SHA256){throw "SHA256 mismatch: $path"}
  $sig=Get-AuthenticodeSignature -LiteralPath $path -ErrorAction Stop
  if($sig.Status -ne 'Valid' -or -not $sig.SignerCertificate -or $sig.SignerCertificate.Subject -notmatch '(?i)Microsoft'){throw "Microsoft publisher signature invalid: $path"}
  $verified.Add([pscustomobject]@{Id=$entry.Id;File=$path})
 }
 Write-Host "Validated $($verified.Count) original Microsoft-signed installers." -ForegroundColor Green
 $reboot=$false
 foreach($p in $verified){
  $switches=if($p.Id -match '2005|2008|2010'){'/q /norestart'}else{'/install /quiet /norestart'}
  Write-Host "[INSTALL] $($p.Id)"
  $run=Start-Process -FilePath $p.File -ArgumentList $switches -PassThru -Wait -ErrorAction Stop
  if($run.ExitCode -eq 3010){$reboot=$true;continue}
  if($run.ExitCode -ne 0){throw "Installation stopped at $($p.Id) (exit $($run.ExitCode))."}
 }
 Write-Host 'Visual C++ All-in-One completed.' -ForegroundColor Green
 if($reboot){Write-Host 'Restart Windows to complete pending runtime updates.' -ForegroundColor Yellow}
 exit 0
}catch{
 Write-Host "[FAILED] $($_.Exception.Message)" -ForegroundColor Red
 exit 1
}
