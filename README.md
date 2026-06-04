# Fastlane Deliver 永久樹（跨專案）

先讀：`永久列管/05_iOS上架Fastlane技能/SKILL.md`

## 套用到新專案

```bash
cd "/Volumes/Crucial X6/@CodexAPP 13套戰略"
./apply_fastlane_deliver_template.sh "/你的專案路徑/"
```

## 每個專案第一次設定

1. 複製 `.env.fastlane.example` 為 `.env.fastlane`
2. 確認 `ASC_ISSUER_ID` / `ASC_KEY_ID` / `ASC_KEY_FILE`
3. 填入 `APP_IDENTIFIER`（可寫在 `.env.fastlane`）
4. 如要上傳 IPA，填入 `IPA_PATH`
5. 更新 `fastlane/metadata/zh-Hant/*.txt`
6. 確認 Privacy Policy / Support 兩頁已在 repo 且已 push

## 執行

```bash
./scripts/deliver_upload_all.sh
```

此腳本會上傳 metadata、screenshots；若 `.env.fastlane` 有 `IPA_PATH`，也會執行 IPA 上傳。
