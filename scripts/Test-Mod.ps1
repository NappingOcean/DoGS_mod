param(
    [Parameter(Mandatory=$true)][string]$GameDirectory,
    # Mod folder to check; Build-Release.ps1 passes its staged copy.
    [string]$ModDirectory = (Join-Path $PSScriptRoot '../DoGS_mod'),
    # Check the folder as shipped (developer tools off) instead of enabling them in the copy.
    [switch]$Release
)
$ErrorActionPreference = 'Stop'
$dogsGame = (Resolve-Path -LiteralPath $GameDirectory).Path
$dogsExecutable = Join-Path $dogsGame 'cataclysm-bn-tiles.exe'
if (-not (Test-Path -LiteralPath $dogsExecutable)) { throw 'BN tiles executable not found.' }
$dogsSource = (Resolve-Path -LiteralPath $ModDirectory).Path
$dogsTest = Join-Path ([IO.Path]::GetTempPath()) ('dogs-check-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path (Join-Path $dogsTest 'mods') -Force | Out-Null
$dogsCopy = Join-Path $dogsTest 'mods/DoGS'
Copy-Item -LiteralPath $dogsSource -Destination $dogsCopy -Recurse
$dogsVersion = (Get-Content -LiteralPath (Join-Path $dogsCopy 'modinfo.json') -Raw | ConvertFrom-Json)[0].version
$dogsConfig = Join-Path $dogsCopy 'dogs/config.lua'
$dogsConfigText = Get-Content -LiteralPath $dogsConfig -Raw
if ($Release) {
    if (-not $dogsConfigText.Contains('dev_tools = false,')) { throw 'config.lua must ship with dev_tools = false.' }
} else {
    # The self-tests and hook registration run only with developer tools on.
    $dogsConfigText = $dogsConfigText.Replace('dev_tools = false,', 'dev_tools = true,')
    if (-not $dogsConfigText.Contains('dev_tools = true,')) { throw 'dev_tools not found in config.lua.' }
    [IO.File]::WriteAllText($dogsConfig, $dogsConfigText)
}
$dogsStdout = Join-Path $dogsTest 'stdout.txt'
$dogsStderr = Join-Path $dogsTest 'stderr.txt'
$dogsArgs = @('--userdir', ('"' + $dogsTest + '/"'), '--check-mods', 'DoGS')
$dogsProcess = Start-Process -FilePath $dogsExecutable -ArgumentList $dogsArgs -WorkingDirectory $dogsGame -WindowStyle Hidden -RedirectStandardOutput $dogsStdout -RedirectStandardError $dogsStderr -PassThru
$null = $dogsProcess.Handle
while (-not $dogsProcess.WaitForExit(30000)) { Write-Output 'BN is still checking mod data...' }
$dogsProcess.WaitForExit()
$dogsLog = Join-Path $dogsTest 'config/debug.log'
Write-Output "Artifacts: $dogsTest"
Get-Content -LiteralPath $dogsStdout
Get-Content -LiteralPath $dogsStderr
if ($dogsProcess.ExitCode -ne 0) { throw "BN check failed: exit $($dogsProcess.ExitCode)" }
# BN can report a Lua load error and still exit 0.
$dogsOutput = (Get-Content -LiteralPath $dogsStdout -Raw) + (Get-Content -LiteralPath $dogsStderr -Raw)
if ($dogsOutput -match 'Error') { throw 'BN reported an error while checking DoGS.' }
$dogsLogText = Get-Content -LiteralPath $dogsLog -Raw
$dogsMarkers = @("event=load build=$dogsVersion dev_tools=$(if ($Release) { 'false' } else { 'true' })", 'event=finalize result=pass')
if (-not $Release) { $dogsMarkers += 'event=selftest scope=policy result=pass' }
foreach ($dogsMarker in $dogsMarkers) {
    if (-not $dogsLogText.Contains($dogsMarker)) { throw "Missing Lua validation marker: $dogsMarker" }
}
if ($Release -and $dogsLogText.Contains('event=selftest')) { throw 'Self-tests ran with developer tools off.' }
if ($Release) {
    Write-Output 'PASS: BN data loading and ID checks with developer tools off. This is not a play test.'
} else {
    Write-Output 'PASS: BN data loading, ID checks and pure policy checks. This is not a play test.'
}
