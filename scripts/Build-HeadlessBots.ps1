[CmdletBinding()]
param([string]$UtRoot = 'C:\UnrealTournament')

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$systemDir = Join-Path $UtRoot 'System'
$ucc = Join-Path $systemDir 'UCC.exe'
$ini = Join-Path $systemDir 'UnrealTournament.ini'
$package = Join-Path $systemDir 'HeadlessBots.u'

foreach ($path in @($ucc, $ini, (Join-Path $projectRoot 'Classes\HeadlessBotsMut.uc'))) {
    if (-not (Test-Path -LiteralPath $path)) { throw "Required path not found: $path" }
}

Copy-Item -LiteralPath $ini -Destination "$ini.before-headlessbots-build" -Force
$iniText = Get-Content -LiteralPath $ini -Raw
if ($iniText -notmatch '(?m)^EditPackages=HeadlessBots\s*$') {
    $iniText = $iniText -replace '(?m)^(EditPackages=DisguiseRelic)\s*$', "`$1`r`nEditPackages=HeadlessBots"
    if ($iniText -notmatch '(?m)^EditPackages=HeadlessBots\s*$') { throw 'Could not add EditPackages=HeadlessBots after DisguiseRelic.' }
    Set-Content -LiteralPath $ini -Value $iniText -NoNewline -Encoding Default
}

if (Test-Path -LiteralPath $package) {
    Copy-Item -LiteralPath $package -Destination "$package.before-build" -Force
    Remove-Item -LiteralPath $package -Force
}

Push-Location $systemDir
try {
    & $ucc make
    if ($LASTEXITCODE -ne 0) { throw "UCC make failed with exit code $LASTEXITCODE." }
} finally { Pop-Location }

if (-not (Test-Path -LiteralPath $package)) { throw 'UCC reported success but HeadlessBots.u was not produced.' }
Copy-Item -LiteralPath (Join-Path $projectRoot 'HeadlessBots.ini') -Destination (Join-Path $systemDir 'HeadlessBots.ini') -Force
Write-Host "Built $package and installed HeadlessBots.ini. Previous .u: $package.before-build"
