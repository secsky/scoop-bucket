# Scoop Bucket

Personal Scoop bucket.

## Usage

```powershell
scoop bucket add scoop-bucket https://github.com/secsky/scoop-bucket.git
scoop install scoop-bucket/pixpin
```

## Manifests

- `pixpin`: PixPin portable edition from <https://pixpin.cn/download/>
- `powershell`: PowerShell portable win-x64 ZIP from <https://github.com/PowerShell/PowerShell/releases>

## Updates

The update workflows run on GitHub Actions:

- `Update PixPin` reads the portable download link from the PixPin download page, downloads the ZIP, calculates the SHA256 hash, updates `bucket/pixpin.json`, and pushes the change when a new version is available.
- `Update PowerShell` reads the latest stable GitHub release, uses the published release hash for `PowerShell-$version-win-x64.zip`, updates `bucket/powershell.json`, and pushes the change when a new version is available.
