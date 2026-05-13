param(
    [string]$ManifestPath = "bucket/powershell.json",
    [string]$Repository = "PowerShell/PowerShell"
)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$manifestFile = Join-Path $root $ManifestPath

if (-not (Test-Path -LiteralPath $manifestFile)) {
    throw "Manifest not found: $manifestFile"
}

$headers = @{
    "User-Agent" = "secsky-scoop-bucket-updater"
    "Accept" = "application/vnd.github+json"
}

$releasesUri = "https://api.github.com/repos/$Repository/releases"
$releases = Invoke-RestMethod -Uri $releasesUri -Headers $headers
$release = $releases |
    Where-Object {
        -not $_.draft -and
        -not $_.prerelease -and
        $_.tag_name -match '^v\d+\.\d+\.\d+$'
    } |
    Select-Object -First 1

if (-not $release) {
    throw "Stable PowerShell release was not found from $releasesUri"
}

$version = $release.tag_name.TrimStart("v")
$assetName = "PowerShell-$version-win-x64.zip"
$asset = $release.assets | Where-Object { $_.name -eq $assetName } | Select-Object -First 1

if (-not $asset) {
    throw "Release asset was not found: $assetName"
}

$hashPattern = "(?im)^\s*[-*]\s+$([regex]::Escape($assetName))\s*\r?\n\s*[-*]\s+(?<hash>[0-9a-f]{64})\s*$"
$hashMatch = [regex]::Match($release.body, $hashPattern)

if (-not $hashMatch.Success) {
    $hashAsset = $release.assets | Where-Object { $_.name -eq "hashes.sha256" } | Select-Object -First 1

    if (-not $hashAsset) {
        throw "SHA256 hash was not found in release notes and hashes.sha256 is missing."
    }

    $hashes = (Invoke-WebRequest -UseBasicParsing -Uri $hashAsset.browser_download_url -Headers $headers).Content
    $hashLine = $hashes -split "\r?\n" |
        Where-Object { $_ -match "(?i)(^|\s)$([regex]::Escape($assetName))(\s|$)" } |
        Select-Object -First 1

    if (-not $hashLine -or $hashLine -notmatch "(?i)\b(?<hash>[0-9a-f]{64})\b") {
        throw "SHA256 hash was not found for $assetName."
    }

    $hash = $Matches["hash"].ToLowerInvariant()
}
else {
    $hash = $hashMatch.Groups["hash"].Value.ToLowerInvariant()
}

$manifest = [ordered]@{
    version = $version
    description = "PowerShell is a cross-platform task automation solution made up of a command-line shell, a scripting language, and a configuration management framework."
    homepage = "https://github.com/$Repository"
    license = "MIT"
    architecture = [ordered]@{
        "64bit" = [ordered]@{
            url = $asset.browser_download_url
            hash = $hash
        }
    }
    bin = "pwsh.exe"
    shortcuts = @(
        , @("pwsh.exe", "PowerShell")
    )
    checkver = [ordered]@{
        github = "https://github.com/$Repository"
    }
    autoupdate = [ordered]@{
        architecture = [ordered]@{
            "64bit" = [ordered]@{
                url = "https://github.com/$Repository/releases/download/v`$version/PowerShell-`$version-win-x64.zip"
            }
        }
    }
}

$json = $manifest | ConvertTo-Json -Depth 8
[System.IO.File]::WriteAllText($manifestFile, $json + [Environment]::NewLine, [System.Text.UTF8Encoding]::new($false))

Write-Host "Updated PowerShell to $version"
Write-Host "URL: $($asset.browser_download_url)"
Write-Host "SHA256: $hash"
