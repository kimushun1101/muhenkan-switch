# AGENTS.md — muhenkan-switch

3-crate Cargo workspace + Tauri v2 GUI + kanata プロセス管理。
詳細構成は `Cargo.toml` 参照。フロントエンドは `muhenkan-switch/frontend/` (Vanilla JS + Vite。`frontend/package.json` で依存管理、`mise run build` で自動ビルドされる)。

## マルチプラットフォーム (Win / Linux / macOS)

非自明な落とし穴のみ列挙。

### シェルスクリプト

- **`sed -i` を直接使わない** — macOS の BSD sed は `sed -i ''` が必要。`scripts/dev/sync-kanata-version.sh` の `sedi()` ヘルパーを使うか、一時ファイル + mv で回避
- **GNU 拡張オプション禁止** — `readlink -f`, `find -printf`, `grep -P` 等は macOS で動かない。POSIX 互換で書く

### Rust

- **プラットフォーム分岐は `mod imp` パターン** — 同一ファイル内に `#[cfg(target_os = "...")] mod imp { ... }` でまとめる (`muhenkan-switch-core/src/commands/` 参照)

## コーディング規約

- **エラー型**: `anyhow::Result<T>`。独自エラー型は作らない。致命的は `bail!()`、外部ツール (wmctrl/xdotool/notify-send 等) の失敗は `eprintln!` で警告して続行
- **テスト命名**: `test_{対象}_{条件}` または `{関数名}_{シナリオ}`
- **言語**: UI 日本語 / コードコメント英語可 / コミット日本語

## ブランチ・PR 運用

- `main` 直 push 禁止。Issue 対応は `feat/issue-{番号}` ブランチ + PR
- PR 本文に `Closes #番号`
- **機能追加・変更時は以下のドキュメント更新を確認**:
  - `README.md` (機能一覧)
  - `docs/design.md` (設計)
  - `docs/setup.md` (セットアップ)
  - `config/default-*.toml` (設定コメント)
  - `muhenkan-switch/frontend/help.html` (ヘルプ)

## バージョン管理 (single source of truth)

- **Rust クレート**: `Cargo.toml` の `[workspace.package] version`
- **kanata**: `kanata-version.txt` → `mise run sync-kanata-version` で 4 ファイルに同期

## 開発コマンド

```bash
mise run build                # debug ビルド → bin/
mise run test                 # cargo test --workspace
mise run dev                  # ビルド + kanata 取得 + GUI 起動
mise run sync-kanata-version  # kanata バージョンを全ファイルに同期
mise run fetch-kanata         # 開発用 kanata バイナリをダウンロード
mise run gen-icons            # img/icon.svg からアイコン全サイズ生成 (Node.js 使用)
```
