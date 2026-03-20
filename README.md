# muhenkan-switch-rs

無変換キーと同時押しを起点としたクロスプラットフォーム・ショートカットツール。

[muhenkan-switch](https://github.com/kimushun1101/muhenkan-switch)（AutoHotkey版）を
[kanata](https://github.com/jtroo/kanata) + Rust製バイナリ で再実装したものです。

## 対応環境

| OS | 対応状況 | 備考 |
|----|----------|------|
| Windows 10/11 | ✅ 検証済み | |
| Linux (X11/Wayland) | ✅ 検証済み | evdev 対応ディストリビューション |
| macOS | ⚠️ 未検証 | JIS配列Mac向け設定ファイルを同梱。動作報告歓迎 |

**日本語キーボード（JIS配列）が必須です。** US配列には対応していません。

## 機能

無変換キーを押しながら他のキーを押すことで、以下の操作ができます。

- **Vim風カーソル移動**: H/J/K/L → ←/↓/↑/→
- **単語・行頭行末移動**: U/I → 単語移動、Y/O → Home/End
- **削除**: N → BackSpace、M → Delete
- **ESC**: ; → Escape
- **アプリ切り替え**: A/T/S/E/F → 指定アプリを最前面に（デフォルト設定）
- **Web検索**: Q/R/W/G/B → 選択テキストで辞書・Google翻訳・AI検索
- **フォルダオープン**: 1/2/3/4/5 → Downloads/Desktop/Documents 等
- **タイムスタンプ**: V/C/X → ファイルマネージャ上ではファイル更新日時でリネーム・複製・除去、テキスト入力時は V でタイムスタンプ入力
- **プレーンテキストコピー**: C → テキスト入力時に選択テキストをプレーンテキストとしてコピー
- **インデント操作**: カンマ → 逆インデント、ピリオド → インデント

詳細は [docs/design.md](docs/design.md) を参照してください。

## セットアップ

### Windows

[最新リリース](https://github.com/kimushun1101/muhenkan-switch-rs/releases/latest) から
`muhenkan-switch_x64-setup.exe` をダウンロードしてインストール。
スタートメニューから `muhenkan-switch` を起動してください。

> 上記を自動で実施するスクリプトは以下のとおりです。PowerShellにコマンドを入力してください。
> ```powershell
> irm https://raw.githubusercontent.com/kimushun1101/muhenkan-switch-rs/main/scripts/install/get.ps1 | iex
> ```

### Linux / macOS

```bash
curl -fsSL https://raw.githubusercontent.com/kimushun1101/muhenkan-switch-rs/main/scripts/install/get.sh | sh
```

Linux ではアプリ一覧（Super キー）または Dock から `muhenkan-switch` を起動できます。
macOS ではターミナルから `muhenkan-switch` を実行してください。

無変換キーを押しながら H/J/K/L でカーソルが移動すれば成功です。

手動インストール・追加設定・アンインストール・更新等の詳細は [docs/setup.md](docs/setup.md) を参照してください。

## カスタマイズ

### キーマッピングの変更

`muhenkan.kbd` を編集してください。
kanata の設定ガイドは [こちら](https://github.com/jtroo/kanata/wiki/Configuration-guide)。

### muhenkan-switch の設定変更

`config.toml` で検索エンジンのURL、アプリ名、フォルダパス等を変更できます。

#### デフォルトのキー割り当て

| キー | 種別 | デフォルト割り当て |
|------|------|------------------|
| 1 | フォルダ | ~/Downloads |
| 2 | フォルダ | ~/Desktop |
| 3 | フォルダ | ~/Documents |
| 4 | フォルダ | ~/repos（カスタマイズ推奨） |
| 5 | フォルダ | ゴミ箱 |
| q | 検索 | 英辞郎 (Weblio) |
| r | 検索 | 類語辞典 (Weblio) |
| w | 検索 | Web翻訳 (Google 翻訳) |
| g | 検索 | Google |
| b | 検索 | ChatGPT |
| a | アプリ | エディタ (VS Code) |
| t | アプリ | Terminal |
| s | アプリ | Slack |
| e | アプリ | ファイルマネージャ |
| f | アプリ | ブラウザ |
| **d** | **アプリ** | **空き（カスタマイズ推奨）** |

> **`d` キーについて**: デフォルトでは未割り当てです。Word・Obsidian・Notion など、よく使う **Document 系アプリ**を設定すると便利です。`config.toml` のコメントに例を記載しています。

## 開発

[docs/development.md](docs/development.md) を参照してください。

## ライセンス

LGPL-3.0-only

本プロジェクト（muhenkan-switch-rs）は Rust によるフルスクラッチ実装です。
旧版（[muhenkan-switch](https://github.com/kimushun1101/muhenkan-switch) AutoHotkey 版）の仕様を一部継承していますが、
コードの流用はないため LGPL-3.0 で提供します。

同梱する kanata も LGPL-3.0 です（`LICENSE` 参照）。

## 旧版（AutoHotkey版）

Windows 専用の AutoHotkey 版は [muhenkan-switch](https://github.com/kimushun1101/muhenkan-switch) にあります。
