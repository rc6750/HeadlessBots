[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$Server = 'rc6750@192.168.4.186',
    [string]$RemoteSystem = '/home/rc6750/ut99/System',
    [string]$RemoteIni = '/home/rc6750/.utpg/System/UnrealTournament.ini',
    [string]$Service = 'ut99.service',
    [string]$UtRoot = 'C:\UnrealTournament'
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$package = Join-Path $UtRoot 'System\HeadlessBots.u'
$config = Join-Path $projectRoot 'HeadlessBots.ini'
foreach ($path in @($package, $config)) {
    if (-not (Test-Path -LiteralPath $path)) { throw "Required deployment file not found: $path. Run Build-HeadlessBots.ps1 first." }
}

$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$stage = "/tmp/headlessbots-$stamp"
$remote = @"
set -eu
stage='$stage'; system_dir='$RemoteSystem'; ini='$RemoteIni'; service='$Service'; stamp='$stamp'
backup="`$system_dir/headlessbots-backup-`$stamp"
mkdir -p "`$backup"
cp -p "`$system_dir/HeadlessBots.u" "`$backup/HeadlessBots.u" 2>/dev/null || true
cp -p "`$system_dir/HeadlessBots.ini" "`$backup/HeadlessBots.ini" 2>/dev/null || true
cp -p "`$ini" "`$backup/UnrealTournament.ini"
cp -p "`$stage/HeadlessBots.u" "`$system_dir/HeadlessBots.u"
cp -p "`$stage/HeadlessBots.ini" "`$system_dir/HeadlessBots.ini"
grep -qx 'ServerPackages=HeadlessBots' "`$ini" || sed -i '/^\[Engine\.GameEngine\]/a ServerPackages=HeadlessBots' "`$ini"
grep -qx 'Mutator=HeadlessBots.HeadlessBotsMut' "`$ini" || sed -i '/^\[Engine\.GameEngine\]/a Mutator=HeadlessBots.HeadlessBotsMut' "`$ini"
sed -i '/^Mutator=Autofill\.AutofillMut`$/d' "`$ini"
sudo systemctl restart "`$service"
sudo systemctl --no-pager --full status "`$service"
echo "Backup retained at `$backup"
"@

if ($PSCmdlet.ShouldProcess($Server, 'back up, deploy HeadlessBots, update active UT99 config, and restart the service')) {
    & ssh $Server "mkdir -p '$stage'"
    if ($LASTEXITCODE -ne 0) { throw 'Could not create remote staging directory.' }
    & scp $package "$Server`:$stage/HeadlessBots.u"
    if ($LASTEXITCODE -ne 0) { throw 'Could not upload HeadlessBots.u.' }
    & scp $config "$Server`:$stage/HeadlessBots.ini"
    if ($LASTEXITCODE -ne 0) { throw 'Could not upload HeadlessBots.ini.' }
    $encoded = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($remote))
    & ssh $Server "echo $encoded | base64 -d | sh"
    if ($LASTEXITCODE -ne 0) { throw 'Remote deployment failed. Inspect the timestamped backup in the remote System directory before retrying.' }
}
