$ErrorActionPreference = 'Stop'
$manifestPath = ".pixpin-test-$([guid]::NewGuid()).json"
$manifestFile = Join-Path (Split-Path -Parent $PSScriptRoot) $manifestPath
$downloadUrl = 'https://download.pixpin.cn/PixPin_win_3.5.5.1.zip'
$pageHtml = '<a href="https://down.pixpin.cn/PixPin_win_3.5.5.1.exe">Installer</a><a id="portable-download-link" class="text-gray-500" data-pp-artifact="portable" href="https://down.pixpin.cn/PixPin_win_3.5.5.1.zip">Portable</a>'

function Invoke-WebRequest {
    param([switch]$UseBasicParsing, [string]$Uri, [string]$OutFile)
    if ($OutFile) {
        if ($Uri -ne $downloadUrl) { throw "Unexpected download: $Uri" }
        [System.IO.File]::WriteAllText($OutFile, 'test archive')
    }
    else {
        @{ Content = $pageHtml }
    }
}

try {
    Set-Content -LiteralPath $manifestFile -Value '{}'
    & "$PSScriptRoot/Update-PixPin.ps1" -ManifestPath $manifestPath
    $manifest = Get-Content -LiteralPath $manifestFile -Raw | ConvertFrom-Json
    if ($manifest.version -ne '3.5.5.1' -or $manifest.url -ne $downloadUrl) {
        throw 'Wrong portable version or URL.'
    }
    $expectedHash = [Convert]::ToHexString([System.Security.Cryptography.SHA256]::HashData([System.Text.Encoding]::UTF8.GetBytes('test archive'))).ToLowerInvariant()
    if ($manifest.hash -ne $expectedHash) { throw 'Wrong archive hash.' }
    $versionMatch = [regex]::Match($pageHtml, $manifest.checkver.regex)
    if (-not $versionMatch.Success -or $versionMatch.Groups[1].Value -ne $manifest.version) {
        throw 'Scoop checkver failed.'
    }
    if ($manifest.autoupdate.url.Replace('$version', $manifest.version) -ne $downloadUrl) {
        throw 'Scoop autoupdate URL differs from the portable link.'
    }

    $before = Get-Content -LiteralPath $manifestFile -Raw
    $pageHtml = $pageHtml.Replace('https://down.pixpin.cn/', 'https://example.com/')
    $rejected = $false
    try { & "$PSScriptRoot/Update-PixPin.ps1" -ManifestPath $manifestPath }
    catch {
        if ($_.Exception.Message -notlike 'Portable download link was not found*') { throw }
        $rejected = $true
    }
    if (-not $rejected -or (Get-Content -LiteralPath $manifestFile -Raw) -cne $before) {
        throw 'Invalid download page must fail without changing the manifest.'
    }
    Write-Host 'PixPin updater checks passed.'
}
finally {
    Remove-Item -LiteralPath $manifestFile -Force
}
