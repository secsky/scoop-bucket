param(
    [string]$ManifestPath = "bucket/dingtalk.json",
    [string]$CastUrl = "https://dtapp-cast.dingtalk.com/dingtalk-desktop/win_x64/vista_later_v2.json"
)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$manifestFile = Join-Path $root $ManifestPath

if (-not (Test-Path -LiteralPath $manifestFile)) {
    throw "Manifest not found: $manifestFile"
}

$cast = Invoke-RestMethod -Uri $CastUrl
$urlV2 = $cast.win.install.url_v2

if (-not $urlV2 -or $urlV2 -notmatch 'DingTalk_v(?<version>[\d.]+)\.exe') {
    throw "DingTalk version was not found in $CastUrl (url_v2=$urlV2)"
}

$latestVersion = $Matches.version
$manifest = Get-Content -LiteralPath $manifestFile -Raw | ConvertFrom-Json

if ($manifest.version -eq $latestVersion) {
    Write-Host "DingTalk is already up to date ($latestVersion)."
    exit 0
}

$manifest.version = $latestVersion
$json = ($manifest | ConvertTo-Json -Depth 10) + "`n"
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($manifestFile, $json, $utf8NoBom)

Write-Host "Updated DingTalk manifest to $latestVersion."
