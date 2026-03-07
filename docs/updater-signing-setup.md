# Updater 署名鍵セットアップガイド

tauri-plugin-updater による自動更新では、更新ファイルの改ざんを防ぐために署名が必要です。

## 仕組み

1. **秘密鍵** — CI でビルド時に更新ファイル (`.nsis.zip`) に署名する
2. **公開鍵** — アプリに埋め込まれ、ダウンロードした更新ファイルの署名を検証する
3. **GitHub Secrets** — 秘密鍵とパスワードを安全に保管し、CI ワークフローから参照する

## 鍵の生成

Tauri CLI で鍵ペアを生成します:

```bash
npx @tauri-apps/cli@2 signer generate -w ~/.tauri/muhenkan-switch.key
```

- 秘密鍵: `~/.tauri/muhenkan-switch.key`
- 公開鍵: `~/.tauri/muhenkan-switch.key.pub`
- パスワードの入力を求められます（空でも可、設定推奨）

## GitHub Secrets への登録

リポジトリの Settings → Secrets and variables → Actions に以下を登録:

| Secret 名 | 値 |
|---|---|
| `TAURI_SIGNING_PRIVATE_KEY` | 秘密鍵ファイルの内容（`cat ~/.tauri/muhenkan-switch.key`） |
| `TAURI_SIGNING_PRIVATE_KEY_PASSWORD` | 鍵生成時に設定したパスワード（空の場合は空文字列） |

## tauri.conf.json への公開鍵設定

`muhenkan-switch/tauri.conf.json` の `plugins.updater.pubkey` に公開鍵を設定:

```json
{
  "plugins": {
    "updater": {
      "pubkey": "dW50cnVzdGVkIGNvbW1lbnQ6...(公開鍵の内容)",
      "endpoints": [
        "https://github.com/kimushun1101/muhenkan-switch-rs/releases/latest/download/latest.json"
      ]
    }
  }
}
```

公開鍵は `cat ~/.tauri/muhenkan-switch.key.pub` で確認できます。

## バックアップの注意

- **秘密鍵を紛失すると、署名付き更新が配信できなくなります**
- 秘密鍵は安全な場所にバックアップしてください
- 鍵を再生成した場合、既にインストール済みのアプリは新しい鍵で署名された更新を受け入れないため、ユーザーは再インストールが必要になります

## ワークフローでの利用

`.github/workflows/release.yml` の Windows ビルドステップで環境変数として渡されます:

```yaml
env:
  TAURI_SIGNING_PRIVATE_KEY: ${{ secrets.TAURI_SIGNING_PRIVATE_KEY }}
  TAURI_SIGNING_PRIVATE_KEY_PASSWORD: ${{ secrets.TAURI_SIGNING_PRIVATE_KEY_PASSWORD }}
```

ビルド時に自動的に `.nsis.zip.sig` ファイルが生成され、`latest.json` に含まれます。
