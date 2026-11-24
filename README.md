# Scoop Bucket

Personal Scoop bucket.

## Usage

```powershell
scoop bucket add scoop-bucket https://github.com/secsky/scoop-bucket.git
scoop install scoop-bucket/pixpin
```

## Manifests

- `dingtalk`: DingTalk desktop client via official cast manifest and signed installer URL
- `mdview`: MDView portable community edition from <https://www.mdview.cn/download.html>
- `pixpin`: PixPin portable edition from <https://pixpin.cn/download/>

## Updates

The update workflows run on GitHub Actions:

- `Update DingTalk` checks the official DingTalk cast JSON for the latest version, updates `bucket/dingtalk.json`, and pushes the change when a new version is available.
- `Update MDView` reads the portable community download link from the MDView download page, downloads the ZIP when a new version is available, calculates the SHA256 hash, updates `bucket/mdview.json`, and pushes the change.
- `Update PixPin` reads the portable download link from the PixPin download page, downloads the ZIP when a new version is available, calculates the SHA256 hash, updates `bucket/pixpin.json`, and pushes the change.
