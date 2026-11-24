param(
    [string]$ManifestPath = "bucket/codex.json",
    [string]$ReleaseManifestUrl = "https://github.com/Wangnov/codex-app-mirror/releases/latest/download/release-manifest.json"
)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$manifestFile = Join-Path $root $ManifestPath

if (-not (Test-Path -LiteralPath $manifestFile)) {
    throw "Manifest not found: $manifestFile"
}

$release = Invoke-RestMethod -UseBasicParsing -Uri $ReleaseManifestUrl
$version = [string]$release.codexVersion
$pkgVersion = [string]$release.derived.windowsPackageVersion

if ([string]::IsNullOrWhiteSpace($version) -or [string]::IsNullOrWhiteSpace($pkgVersion)) {
    throw "Missing codexVersion or windowsPackageVersion in $ReleaseManifestUrl"
}

$manifest = Get-Content -LiteralPath $manifestFile -Raw | ConvertFrom-Json
if ($manifest.version -eq $version) {
    Write-Host "Codex is already up to date ($version)."
    exit 0
}

$x64Asset = "OpenAI.Codex_${pkgVersion}_x64__2p2nqsd0c76g0.Msix"
$arm64Asset = "OpenAI.Codex_${pkgVersion}_arm64__2p2nqsd0c76g0.Msix"

$checksums = $release.derived.latestChecksums
$x64Hash = [string]$checksums.$x64Asset
$arm64Hash = [string]$checksums.$arm64Asset

if ([string]::IsNullOrWhiteSpace($x64Hash) -or [string]::IsNullOrWhiteSpace($arm64Hash)) {
    throw "Missing Windows MSIX checksums for $pkgVersion in $ReleaseManifestUrl"
}

$baseUrl = "https://github.com/Wangnov/codex-app-mirror/releases/download/codex-app-$version"
$manifest.version = $version
$manifest.architecture.'64bit'.url = "$baseUrl/$x64Asset"
$manifest.architecture.'64bit'.hash = $x64Hash.ToLowerInvariant()
$manifest.architecture.arm64.url = "$baseUrl/$arm64Asset"
$manifest.architecture.arm64.hash = $arm64Hash.ToLowerInvariant()

$json = ($manifest | ConvertTo-Json -Depth 8) + "`n"
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($manifestFile, $json, $utf8NoBom)

Write-Host "Updated Codex to $version (package $pkgVersion)"
Write-Host "x64 SHA256: $($manifest.architecture.'64bit'.hash)"
Write-Host "arm64 SHA256: $($manifest.architecture.arm64.hash)"
