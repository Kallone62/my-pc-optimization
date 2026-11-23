#requires -Version 5.1
# Shared transport layer. Callers are responsible for source allowlists,
# SHA-256 and Authenticode verification before declaring READY.
function Save-HttpsPayload {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Url,
        [Parameter(Mandatory)][string]$Destination,
        [string]$Referer,
        [string]$UserAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'
    )
    if (([uri]$Url).Scheme -ne 'https') { throw "HTTPS required: $Url" }
    $folder = Split-Path -Parent $Destination
    New-Item -ItemType Directory -Path $folder -Force -ErrorAction Stop | Out-Null
    $partial = "$Destination.part"
    $origin = "$Destination.part.url"
    if (Test-Path -LiteralPath $partial -PathType Leaf) {
        $previous = if (Test-Path -LiteralPath $origin -PathType Leaf) { [IO.File]::ReadAllText($origin) } else { '' }
        if ($previous -cne $Url) { Remove-Item -LiteralPath $partial -Force -ErrorAction Stop }
    }
    [IO.File]::WriteAllText($origin,$Url)
    $clock = [Diagnostics.Stopwatch]::StartNew()
    $curl = Get-Command curl.exe -ErrorAction SilentlyContinue
    if ($curl) {
        $successful = $false
        for ($attempt=1; $attempt -le 3; $attempt++) {
            $resume = (Test-Path -LiteralPath $partial -PathType Leaf) -and ((Get-Item -LiteralPath $partial).Length -gt 0)
            $arguments = @('-q','--fail','--location','--silent','--show-error','--max-redirs','6','--connect-timeout','30','--max-time','1800','--proto','=https','--proto-redir','=https','--user-agent',$UserAgent,'--output',$partial)
            if ($Referer) { $arguments += @('--referer',$Referer) }
            if ($resume) { $arguments += @('--continue-at','-') }
            $arguments += $Url
            & $curl.Source @arguments
            $exitCode = [int]$LASTEXITCODE
            if ($exitCode -eq 0) { $successful = $true; break }
            if ($exitCode -eq 33 -and $resume) {
                Write-Warning 'Server does not support resuming this file; restarting from zero.'
                Remove-Item -LiteralPath $partial -Force -ErrorAction SilentlyContinue
            } elseif (@(7,18,28,35,52,55,56) -notcontains $exitCode) {
                throw "HTTPS transfer failed (curl exit $exitCode): $Url"
            }
            if ($attempt -lt 3) {
                Write-Warning "Download interrupted ($exitCode), retry $attempt/3."
                Start-Sleep -Seconds $attempt
            }
        }
        if (-not $successful) { throw "Download failed after retries: $Url" }
    }
    else {
        if (Test-Path -LiteralPath $partial) { Remove-Item -LiteralPath $partial -Force }
        $headers = @{ 'User-Agent' = $UserAgent }
        if ($Referer) { $headers['Referer'] = $Referer }
        Invoke-WebRequest -Uri $Url -OutFile $partial -Headers $headers -UseBasicParsing -TimeoutSec 1800 -ErrorAction Stop
    }
    $clock.Stop()
    if (-not (Test-Path -LiteralPath $partial -PathType Leaf)) { throw "Download did not create a file: $Url" }
    $bytes = (Get-Item -LiteralPath $partial -ErrorAction Stop).Length
    if ($bytes -eq 0) { throw "Empty file: $Url" }
    Move-Item -LiteralPath $partial -Destination $Destination -Force -ErrorAction Stop
    Remove-Item -LiteralPath $origin -Force -ErrorAction SilentlyContinue
    $elapsed = [math]::Max($clock.Elapsed.TotalSeconds,0.01)
    Write-Host ("[TRANSFER] {0:N1} MiB in {1:N1}s ({2:N1} MiB/s)" -f ($bytes/1MB),$elapsed,(($bytes/1MB)/$elapsed))
}
