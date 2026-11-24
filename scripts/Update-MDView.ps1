param(
    [string]$ManifestPath = "bucket/mdview.json",
    [string]$DownloadPage = "https://www.mdview.cn/download.html"
)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$manifestFile = Join-Path $root $ManifestPath

if (-not (Test-Path -LiteralPath $manifestFile)) {
    throw "Manifest not found: $manifestFile"
}

$response = Invoke-WebRequest -UseBasicParsing -Uri $DownloadPage
$html = $response.Content

$linkPattern = '(?<url>https://www\.mdview\.cn/download/mdview-portable-(?<version>\d+(?:\.\d+)+)\.zip)'
$match = [regex]::Match($html, $linkPattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)

if (-not $match.Success) {
    throw "Portable download link was not found on $DownloadPage"
}

$version = $match.Groups["version"].Value
$manifest = Get-Content -LiteralPath $manifestFile -Raw | ConvertFrom-Json
if ($manifest.version -eq $version) {
    Write-Host "MDView is already up to date ($version)."
    exit 0
}

$url = $match.Groups["url"].Value
$tempFile = Join-Path ([System.IO.Path]::GetTempPath()) ("mdview-portable-{0}.zip" -f $version)
try {
    $ProgressPreference = 'SilentlyContinue'
    Invoke-WebRequest -UseBasicParsing -Uri $url -OutFile $tempFile
    $hash = (Get-FileHash -LiteralPath $tempFile -Algorithm SHA256).Hash.ToLowerInvariant()
}
finally {
    Remove-Item -LiteralPath $tempFile -Force -ErrorAction SilentlyContinue
}

$manifest.version = $version
$manifest.url = $url
$manifest.hash = $hash

$json = ($manifest | ConvertTo-Json -Depth 8) + "`n"
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($manifestFile, $json, $utf8NoBom)

Write-Host "Updated MDView to $version"
Write-Host "URL: $url"
Write-Host "SHA256: $hash"
