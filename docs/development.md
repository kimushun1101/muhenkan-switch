# 開発ガイド

## 前提条件

- [Rust ツールチェーン](https://rustup.rs/)
- [mise](https://mise.jdx.dev/)（タスクランナーとして使用）

```bash
# Rust のインストール
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# mise のインストール (Linux/macOS)
curl https://mise.jdx.dev/install.sh | sh

# mise のインストール (Windows - PowerShell)
# winget install jdx.mise
# または Scoop: scoop install mise
```

### Linux の追加セットアップ

Tauri のビルドにはシステムライブラリが必要です。`mise run setup` で一括インストールできます。

```bash
mise run setup
```

<details>
<summary>インストールされるパッケージ一覧（Ubuntu/Debian）</summary>

| パッケージ | 用途 |
|---|---|
| `libwebkit2gtk-4.1-dev` | WebView エンジン（Tauri GUI） |
| `libsoup-3.0-dev` | HTTP ライブラリ |
| `libjavascriptcoregtk-4.1-dev` | JavaScript エンジン |
| `libgtk-3-dev` | GTK3 ツールキット |
| `libayatana-appindicator3-dev` | システムトレイ |
| `librsvg2-dev` | SVG レンダリング |
| `libssl-dev` | TLS/暗号化 |
| `build-essential` | C/C++ コンパイラ |
| `pkexec` | GUI 権限昇格（uinput 設定用） |
| `wmctrl` | ウィンドウアクティブ化（アプリ切り替え） |
| `xdotool` | ウィンドウ検索・操作（アプリ切り替え） |
| `libnotify-bin` | デスクトップ通知（notify-send） |

Fedora/Arch の場合は `mise.toml` 内の対応コマンドが実行されます。
</details>

## 開発タスク

```bash
mise run setup      # Linux: システムライブラリ + uinput 設定ガイド（初回のみ）
mise run build      # debug ビルド → ルートにコピー
mise run release    # release ビルド → ルートにコピー
mise run dev        # debug ビルド + kanata ダウンロード + GUI 起動
mise run test       # ユニットテスト
```

## Windows Defender 除外設定

ビルド後の `.exe` 実行時に、Windows Defender のリアルタイム保護により `Permission denied` が発生することがある。
新しく生成・コピーされた未署名の `.exe` をスキャンし、一時的にロックするのが原因。

リポジトリのルートディレクトリごと除外するのが簡単（管理者権限 PowerShell で実行）:

```powershell
# 除外に追加
Add-MpPreference -ExclusionPath "C:\Users\<ユーザー名>\repos\muhenkan-switch"

# 確認
Get-MpPreference | Select-Object -ExpandProperty ExclusionPath

# 除外を解除（開発終了後）
Remove-MpPreference -ExclusionPath "C:\Users\<ユーザー名>\repos\muhenkan-switch"
```

## Updater 署名鍵セットアップ

tauri-plugin-updater による自動更新では、更新ファイルの改ざんを防ぐために署名が必要。

### 鍵の生成

```bash
npx @tauri-apps/cli@2 signer generate -w ~/.tauri/muhenkan-switch.key
```

- 秘密鍵: `~/.tauri/muhenkan-switch.key`
- 公開鍵: `~/.tauri/muhenkan-switch.key.pub`

### GitHub Secrets への登録

リポジトリの Settings → Secrets and variables → Actions に以下を登録:

| Secret 名 | 値 |
|---|---|
| `TAURI_SIGNING_PRIVATE_KEY` | 秘密鍵ファイルの内容（`cat ~/.tauri/muhenkan-switch.key`） |
| `TAURI_SIGNING_PRIVATE_KEY_PASSWORD` | 鍵生成時に設定したパスワード（空の場合は空文字列） |

### tauri.conf.json への公開鍵設定

`muhenkan-switch/tauri.conf.json` の `plugins.updater.pubkey` に公開鍵を設定:

```json
{
  "plugins": {
    "updater": {
      "pubkey": "dW50cnVzdGVkIGNvbW1lbnQ6...(公開鍵の内容)",
      "endpoints": [
        "https://github.com/kimushun1101/muhenkan-switch/releases/latest/download/latest.json"
      ]
    }
  }
}
```

### バックアップの注意

- **秘密鍵を紛失すると、署名付き更新が配信できなくなる**
- 鍵を再生成した場合、既にインストール済みのアプリは新しい鍵で署名された更新を受け入れないため、ユーザーは再インストールが必要

### ワークフローでの利用

`.github/workflows/release.yml` の Windows ビルドステップで環境変数として渡される:

```yaml
env:
  TAURI_SIGNING_PRIVATE_KEY: ${{ secrets.TAURI_SIGNING_PRIVATE_KEY }}
  TAURI_SIGNING_PRIVATE_KEY_PASSWORD: ${{ secrets.TAURI_SIGNING_PRIVATE_KEY_PASSWORD }}
```

## テスト

### 自動テスト（cargo test）

```
cargo test --workspace
```

#### テストの場所

- `muhenkan-switch-config/src/lib.rs` — config crate 単体テスト (24件)
- `muhenkan-switch-core/src/commands/timestamp.rs` — timestamp コマンド単体テスト (11件)
- `muhenkan-switch-core/src/commands/open_folder.rs` — フォルダ展開・ゴミ箱パス解決テスト (10件)
- `muhenkan-switch-core/src/commands/switch_app.rs` — Linux ウィンドウ検索テスト (6件, Linux のみ)
- `muhenkan-switch-core/src/commands/toast.rs` — 通知テスト (3件)

#### カテゴリ

**config crate:**
- **パース** (`test_parse_*`) — TOML デシリアライズ
- **ディスパッチ** (`test_dispatch_*`) — キー→アクション検索、優先順位
- **バリデーション** (`test_validate_*`) — 設定値の検証、キー重複検出
- **Save/Load** (`test_roundtrip_*`, `test_save_*`) — ファイル書き出しと復元、ソート順
- **ヘルパー** (`test_get_*`, `test_app_*`) — ユーティリティ関数

**CLI crate (muhenkan-switch-core):**
- **timestamp** (`test_compose_*`, `test_resolve_*`) — タイムスタンプ結合・アクション解決の純粋ロジック
- **open_folder** — `expand_home` のチルダ展開、存在しないフォルダのエラー、空パスのエラー
- **switch_app** — `try_wmctrl`/`try_xdotool` が存在しないアプリでパニックしないこと、`activate_window` のエラーハンドリング
- **toast** — `Toast::show`/`finish` が notify-send 不在でもパニックしないこと、日本語メッセージ対応

#### テスト追加時の規約

- テスト名: `test_{カテゴリ}_{何を検証するか}` または `{関数名}_{条件}_{期待結果}`
- 場所: 各 `.rs` ファイル内 `#[cfg(test)] mod tests`
- ファイル I/O を伴うテストは `std::env::temp_dir()` を使用し、末尾で cleanup

### 手動テスト（Ubuntu 22.04 X11）

<details>
<summary>手動テスト手順の詳細</summary>

#### 前提条件

```bash
sudo apt install wmctrl xdotool libnotify-bin xdg-utils
cargo build --workspace
```

#### ゴミ箱を開く（キー 5）

```bash
cargo run -p muhenkan-switch-core -- open-folder --target trash
```

| 条件 | 期待動作 |
|------|---------|
| `~/.local/share/Trash/files/` が存在する | ファイルマネージャでゴミ箱フォルダが開く |
| `~/.local/share/Trash/files/` が存在しない | エラーメッセージ `Trash folder not found` が表示される |

#### 通常フォルダを開く（キー 1,2,3）

```bash
cargo run -p muhenkan-switch-core -- open-folder --target documents
cargo run -p muhenkan-switch-core -- open-folder --target downloads
cargo run -p muhenkan-switch-core -- open-folder --target desktop
```

#### アプリ切り替え — ブラウザ（キー f）

```bash
cargo run -p muhenkan-switch-core -- switch-app --target browser
```

| 条件 | 期待動作 |
|------|---------|
| Firefox が起動済み | Firefox ウィンドウが最前面にアクティブ化される |
| Firefox が未起動 | Firefox が新規起動される |
| wmctrl 未インストール | xdotool にフォールバックして動作する |
| wmctrl も xdotool も未インストール | launch コマンド実行を試み、失敗しても正常終了する |

#### アプリ切り替え — エディタ（キー a）

```bash
cargo run -p muhenkan-switch-core -- switch-app --target editor
```

#### Web 検索（キー g）

```bash
echo -n "Rust programming" | xclip -selection clipboard
cargo run -p muhenkan-switch-core -- search --engine google
```

#### タイムスタンプ — V/C/X

```bash
# テキストエディタにフォーカスした状態で
cargo run -p muhenkan-switch-core -- timestamp --action paste   # V: タイムスタンプ入力
cargo run -p muhenkan-switch-core -- timestamp --action copy    # C: プレーンテキストコピー
cargo run -p muhenkan-switch-core -- timestamp --action cut     # X: テキスト時 no-op
```

#### フォールバック検証

```bash
# wmctrl を一時的に無効にしてフォールバック確認
sudo mv /usr/bin/wmctrl /usr/bin/wmctrl.bak
cargo run -p muhenkan-switch-core -- switch-app --target browser
sudo mv /usr/bin/wmctrl.bak /usr/bin/wmctrl
```

</details>
