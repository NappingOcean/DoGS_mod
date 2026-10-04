param([Parameter(Mandatory=$true)][string]$GameDirectory)
$ErrorActionPreference = 'Stop'
$dogsGame = (Resolve-Path -LiteralPath $GameDirectory).Path
$dogsSource = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '../DoGS_mod')).Path
if (-not (Test-Path -LiteralPath (Join-Path $dogsGame 'cataclysm-bn-tiles.exe'))) { throw 'BN tiles executable not found.' }
$dogsMods = Join-Path $dogsGame 'mods'
New-Item -ItemType Directory -Force -Path $dogsMods | Out-Null
$dogsLink = Join-Path $dogsMods 'DoGS'
if (Test-Path -LiteralPath $dogsLink) {
    $dogsExisting = Get-Item -LiteralPath $dogsLink
    if ($dogsExisting.LinkType -eq 'Junction' -and $dogsExisting.Target -contains $dogsSource) {
        Write-Output "Already linked: $dogsLink"
        return
    }
    # Re-point only a junction to this repository's pre-rebuild mod folder; removing a junction keeps its target.
    $dogsLegacy = Join-Path (Split-Path -Parent $dogsSource) 'mod'
    if ($dogsExisting.LinkType -eq 'Junction' -and $dogsExisting.Target -contains $dogsLegacy) {
        $dogsExisting.Delete()
        Write-Output "Removed legacy junction to $dogsLegacy"
    } else {
        throw "Destination already exists; inspect it before replacing: $dogsLink"
    }
}
New-Item -ItemType Junction -Path $dogsLink -Target $dogsSource | Out-Null
Write-Output "Linked $dogsLink to $dogsSource"
