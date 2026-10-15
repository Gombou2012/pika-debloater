# Build a Pika Debloater branded fork from the upstream MIT-licensed WinUtil source.
# This builder runs on GitHub Actions / Windows with PowerShell 7.
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$UpstreamDirectory,
    [Parameter(Mandatory = $true)][string]$OutputDirectory,
    [Parameter(Mandatory = $true)][string]$Repository
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ($Repository -notmatch '^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$') {
    throw 'Repository must look like GitHubUsername/pika-debloater.'
}
$upstream = (Resolve-Path -LiteralPath $UpstreamDirectory).Path
$output = (Resolve-Path -LiteralPath $OutputDirectory).Path
$xamlPath = Join-Path $upstream 'xaml/inputXML.xaml'
$startPath = Join-Path $upstream 'scripts/start.ps1'
$mainPath = Join-Path $upstream 'scripts/main.ps1'
$compilePath = Join-Path $upstream 'Compile.ps1'
$licensePath = Join-Path $upstream 'LICENSE'
foreach ($p in @($xamlPath, $startPath, $mainPath, $compilePath, $licensePath)) {
    if (-not (Test-Path -LiteralPath $p)) { throw "Upstream file missing: $p" }
}

# Change user-facing strings only. Do NOT rename WinUtil's internal functions or XAML names:
# they are linked to the upstream application logic and changing them breaks the GUI.
$xaml = Get-Content -LiteralPath $xamlPath -Raw -Encoding UTF8
if (-not $xaml.Contains('Title="WinUtil"')) { throw 'Expected upstream XAML window title not found. Review upstream changes.' }
$xaml = $xaml.Replace('Title="WinUtil"', 'Title="Pika Debloater"')
$xaml = $xaml.Replace('Change the WinUtil UI Theme', 'Change the Pika Debloater UI Theme')
$xaml = $xaml.Replace('managed by WinUtil', 'managed by Pika Debloater')
$xaml = $xaml.Replace('applied by WinUtil', 'applied by Pika Debloater')
$xaml = $xaml.Replace('WinUtil update policies', 'Pika Debloater update policies')
Set-Content -LiteralPath $xamlPath -Value $xaml -Encoding utf8NoBOM -NoNewline

# Keep the original upstream source credits in scripts/start.ps1 unchanged.
$start = Get-Content -LiteralPath $startPath -Raw -Encoding UTF8
$start = $start.Replace('$Host.UI.RawUI.WindowTitle = "WinUtil"', '$Host.UI.RawUI.WindowTitle = "Pika Debloater"')
$start = $start.Replace('Write-Output "WinUtil needs to be run as Administrator.', 'Write-Output "Pika Debloater needs to be run as Administrator.')
Set-Content -LiteralPath $startPath -Value $start -Encoding utf8NoBOM -NoNewline

# Replace only the startup terminal banner, not the functional code.
$main = Get-Content -LiteralPath $mainPath -Raw -Encoding UTF8
$originalBanner = '\AWrite-Host @"[\s\S]*?"@'
if ($main -notmatch $originalBanner) { throw 'Expected startup banner not found. Review upstream changes.' }
$main = [regex]::Replace($main, $originalBanner, "Write-Host 'PIKA DEBLOATER  |  Windows utility' -ForegroundColor Cyan`r`nWrite-Host 'Based on Chris Titus Tech WinUtil (MIT licensed)' -ForegroundColor Gray", 1)
Set-Content -LiteralPath $mainPath -Value $main -Encoding utf8NoBOM -NoNewline

# Compile all upstream features (applications, debloat, tweaks, config, updates).
Push-Location $upstream
try {
    & $compilePath
    if (-not (Test-Path -LiteralPath (Join-Path $upstream 'winutil.ps1'))) {
        throw 'Upstream compilation did not produce winutil.ps1.'
    }
} finally {
    Pop-Location
}

# Redistribute the complete license notice both as a separate file and in the bundle.
$license = Get-Content -LiteralPath $licensePath -Raw -Encoding UTF8
$notice = @"
# Pika Debloater - WinUtil-based fork (not affiliated with Chris Titus Tech).
# Modified window/title/launcher; most functional code remains upstream WinUtil.
<#
$license
#>

"@
$compiled = Get-Content -LiteralPath (Join-Path $upstream 'winutil.ps1') -Raw -Encoding UTF8
$destination = Join-Path $output 'PikaDebloater.ps1'
Set-Content -LiteralPath $destination -Value ($notice + $compiled) -Encoding utf8NoBOM -NoNewline
Copy-Item -LiteralPath $licensePath -Destination (Join-Path $output 'LICENSE-WINUTIL') -Force

# Produce a short, repo-specific command loader that downloads the exact forked build.
# Running the downloaded script as a local -File keeps WinUtil's elevation path local.
$rawUrl = 'https://raw.githubusercontent.com/' + $Repository + '/main/PikaDebloater.ps1'
$launcher = @'
# Pika Debloater launcher. Inspect PikaDebloater.ps1 in the public repository before executing.
$ErrorActionPreference = 'Stop'
if ($env:OS -ne 'Windows_NT') { throw 'Pika Debloater requires Windows.' }
$uri = '__RAW_URL__'
$target = Join-Path $env:TEMP 'PikaDebloater.ps1'
Write-Host 'Pika Debloater: downloading the script from your GitHub repository...' -ForegroundColor Cyan
Invoke-WebRequest -UseBasicParsing -Uri $uri -OutFile $target
if (-not (Test-Path $target) -or (Get-Item $target).Length -lt 1000) {
    throw 'Download failed or file is unexpectedly small.'
}
Write-Host 'Launching Pika Debloater. Windows might request administrator approval.' -ForegroundColor Cyan
& powershell.exe -NoProfile -STA -ExecutionPolicy Bypass -File $target
'@
$launcher = $launcher.Replace('__RAW_URL__', $rawUrl)
Set-Content -LiteralPath (Join-Path $output 'run.ps1') -Value $launcher -Encoding utf8NoBOM

Write-Host "Generated $destination and run.ps1 from upstream source." -ForegroundColor Green
Write-Host 'Preserved upstream license and attribution.'
