# AGENTS.md — muhenkan-switch

3-crate Cargo workspace + Tauri v2 GUI + kanata プロセス管理。
詳細構成は `Cargo.toml` 参照。フロントエンドは `muhenkan-switch/frontend/` (TypeScript strict + Vite + Vitest)。`mise run build` 内で `npm ci` + `vite build` まで自動実行される。

## マルチプラットフォーム (Win / Linux / macOS)

非自明な落とし穴のみ列挙。

### シェルスクリプト

- **`sed -i` を直接使わない** — macOS の BSD sed は `sed -i ''` が必要。`scripts/dev/sync-kanata-version.sh` の `sedi()` ヘルパーを使うか、一時ファイル + mv で回避
- **GNU 拡張オプション禁止** — `readlink -f`, `find -printf`, `grep -P` 等は macOS で動かない。POSIX 互換で書く

### Rust

- **プラットフォーム分岐は `mod imp` パターン** — 同一ファイル内に `#[cfg(target_os = "...")] mod imp { ... }` でまとめる (`muhenkan-switch-core/src/commands/` 参照)

## コーディング規約

- **エラー型 (Rust)**: `anyhow::Result<T>`。独自エラー型は作らない。致命的は `bail!()`、外部ツール (wmctrl/xdotool/notify-send 等) の失敗は `eprintln!` で警告して続行
- **テスト命名 (Rust)**: `test_{対象}_{条件}` または `{関数名}_{シナリオ}`
- **言語**: UI 日本語 / コードコメント英語可 / コミット日本語
- **フロントエンド**: スタイル・lint 規約は `muhenkan-switch/frontend/eslint.config.js` と `.prettierrc.json` が single source of truth。AGENTS.md には書かず、`npm run lint` / `npm run format:check` で検証する

## フロントエンド (TypeScript + Vite + Vitest)

`muhenkan-switch/frontend/` 配下で実行。CI で typecheck / lint / format:check / test / build を全 OS で強制している。

```bash
cd muhenkan-switch/frontend
npm run typecheck     # tsc --noEmit
npm run lint          # eslint .
npm run format:check  # prettier --check .
npm run test          # vitest run --coverage (coverage 閾値 per-file 80% を強制)
npm run build         # vite build (mise run build からも呼ばれる)
```

- **テスト配置**: `src/{lib,forms}/__tests__/` 集約 (co-locate しない)
- **vitest 設定**: `vitest.config.ts` を独立配置 (vite.config.js には統合しない)
- **coverage 閾値**: `vitest.config.ts` の `coverage.include` を **テスト済ファイルだけ whitelist**、各ファイルに per-file 80% (lines/functions/branches/statements) を強制。新規テスト追加時は include に対象ファイルを足す
- **DOM env**: happy-dom (jsdom より軽量。足りない API に当たったら jsdom 切替を検討)
- **vitest globals**: `false`。各テストで `import { describe, expect, it } from 'vitest'` を明示
- **改行コード**: Prettier `endOfLine: 'lf'` (`.prettierrc.json`) のため `.gitattributes` で対象拡張子を `eol=lf` 指定済 (Windows checkout 時の CRLF で format:check が落ちるのを回避)

## ブランチ・PR 運用

- `main` 直 push 禁止。Issue 対応は `feat/issue-{番号}` ブランチ + PR
- PR 本文に `Closes #番号`
- **機能追加・変更時は以下のドキュメント更新を確認**:
  - `README.md` (機能一覧)
  - `docs/design.md` (設計)
  - `docs/setup.md` (セットアップ)
  - `docs/customize.md` (カスタマイズ)
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
