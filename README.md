# Scoop Bucket

Personal Scoop bucket.

## Usage

```powershell
scoop bucket add scoop-bucket https://github.com/<owner>/<repo>
scoop install scoop-bucket/pixpin
```

## Manifests

- `pixpin`: PixPin portable edition from <https://pixpin.cn/download/>

## Updates

The `Update PixPin` GitHub Actions workflow reads the portable download link from the PixPin download page, downloads the ZIP, calculates the SHA256 hash, updates `bucket/pixpin.json`, and pushes the change when a new version is available.
