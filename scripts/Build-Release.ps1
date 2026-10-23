param(
    # With a game directory, the staged folder is also checked with Test-Mod.ps1 -Release.
    [string]$GameDirectory
)
$ErrorActionPreference = 'Stop'
$dogsRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path
$dogsSource = Join-Path $dogsRoot 'DoGS_mod'
$dogsVersion = (Get-Content -LiteralPath (Join-Path $dogsSource 'modinfo.json') -Raw | ConvertFrom-Json)[0].version
if (-not (Get-Content -LiteralPath (Join-Path $dogsSource 'dogs/config.lua') -Raw).Contains('dev_tools = false,')) {
    throw 'config.lua must ship with dev_tools = false.'
}
if (git -C $dogsRoot status --porcelain) { throw 'Working tree is not clean; commit before building a release.' }

# Developer-only files, never loaded with dev_tools = false.
$dogsDevOnly = @('dogs/tests.lua')
$dogsDist = Join-Path $dogsRoot 'dist'
$dogsStage = Join-Path $dogsDist "stage-$dogsVersion"
$dogsMod = Join-Path $dogsStage 'DoGS'
if (Test-Path -LiteralPath $dogsStage) { Remove-Item -LiteralPath $dogsStage -Recurse -Force }
New-Item -ItemType Directory -Force -Path $dogsStage | Out-Null
Copy-Item -LiteralPath $dogsSource -Destination $dogsMod -Recurse
foreach ($dogsFile in $dogsDevOnly) { Remove-Item -LiteralPath (Join-Path $dogsMod $dogsFile) }
Copy-Item -LiteralPath (Join-Path $dogsRoot 'LICENSE') -Destination $dogsMod
Copy-Item -Path (Join-Path $dogsRoot 'release/*.md') -Destination $dogsMod

if ($GameDirectory) { & (Join-Path $PSScriptRoot 'Test-Mod.ps1') -GameDirectory $GameDirectory -ModDirectory $dogsMod -Release }

$dogsZip = Join-Path $dogsDist "DoGS-$dogsVersion.zip"
if (Test-Path -LiteralPath $dogsZip) { Remove-Item -LiteralPath $dogsZip }
Add-Type -AssemblyName System.IO.Compression.FileSystem
# .NET's ZipFile writes forward-slash entry names; the zip holds the single folder DoGS/.
[IO.Compression.ZipFile]::CreateFromDirectory($dogsStage, $dogsZip)
Write-Output "Built $dogsZip"
Get-ChildItem -LiteralPath $dogsMod -Recurse -File | ForEach-Object { $_.FullName.Substring($dogsStage.Length + 1) }
