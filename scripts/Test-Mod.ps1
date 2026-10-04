param([Parameter(Mandatory=$true)][string]$GameDirectory)
$ErrorActionPreference = 'Stop'
$dogsGame = (Resolve-Path -LiteralPath $GameDirectory).Path
$dogsExecutable = Join-Path $dogsGame 'cataclysm-bn-tiles.exe'
if (-not (Test-Path -LiteralPath $dogsExecutable)) { throw 'BN tiles executable not found.' }
$dogsSource = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '../DoGS_mod')).Path
$dogsTest = Join-Path ([IO.Path]::GetTempPath()) ('dogs-check-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path (Join-Path $dogsTest 'mods') -Force | Out-Null
Copy-Item -LiteralPath $dogsSource -Destination (Join-Path $dogsTest 'mods/DoGS') -Recurse
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
foreach ($dogsMarker in @('event=selftest scope=policy result=pass', 'event=load build=claude-rebuild', 'event=finalize result=pass')) {
    if (-not $dogsLogText.Contains($dogsMarker)) { throw "Missing Lua validation marker: $dogsMarker" }
}
Write-Output 'PASS: BN data loading, ID checks and pure policy checks. This is not a play test.'
