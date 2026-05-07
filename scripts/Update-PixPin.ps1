param(
    [string]$ManifestPath = "bucket/pixpin.json",
    [string]$DownloadPage = "https://pixpin.cn/download/"
)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$manifestFile = Join-Path $root $ManifestPath

if (-not (Test-Path -LiteralPath $manifestFile)) {
    throw "Manifest not found: $manifestFile"
}

$response = Invoke-WebRequest -UseBasicParsing -Uri $DownloadPage
$html = $response.Content

$linkPattern = '<a\b[^>]*\bid="portable-download-link"[^>]*\bhref="(?<url>https://download\.pixpin\.cn/PixPin_cn_zh-cn_(?<version>[\d.]+)\.zip)"'
$match = [regex]::Match($html, $linkPattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)

if (-not $match.Success) {
    throw "Portable download link was not found on $DownloadPage"
}

$version = $match.Groups["version"].Value
$url = $match.Groups["url"].Value

$tempFile = Join-Path ([System.IO.Path]::GetTempPath()) ("PixPin_cn_zh-cn_{0}.zip" -f $version)
try {
    Invoke-WebRequest -UseBasicParsing -Uri $url -OutFile $tempFile
    $hash = (Get-FileHash -LiteralPath $tempFile -Algorithm SHA256).Hash.ToLowerInvariant()
}
finally {
    Remove-Item -LiteralPath $tempFile -Force -ErrorAction SilentlyContinue
}

$manifest = [ordered]@{
    version = $version
    description = "A screenshot, pinboard, OCR, long screenshot, and annotation tool."
    homepage = "https://pixpin.cn/"
    license = "Freeware"
    url = $url
    hash = $hash
    extract_dir = "PixPin"
    persist = @("Config", "Data", "History")
    shortcuts = @(
        , @("PixPin.exe", "PixPin")
    )
    checkver = [ordered]@{
        url = $DownloadPage
        regex = 'id="portable-download-link"[^>]+href="https://download\.pixpin\.cn/PixPin_cn_zh-cn_([\d.]+)\.zip"'
    }
    autoupdate = [ordered]@{
        url = 'https://download.pixpin.cn/PixPin_cn_zh-cn_$version.zip'
    }
}

$json = $manifest | ConvertTo-Json -Depth 8
[System.IO.File]::WriteAllText($manifestFile, $json + [Environment]::NewLine, [System.Text.UTF8Encoding]::new($false))

Write-Host "Updated PixPin to $version"
Write-Host "URL: $url"
Write-Host "SHA256: $hash"
