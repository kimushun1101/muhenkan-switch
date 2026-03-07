# UI 設計リファレンス

設計判断の参考にした Web ページをまとめる。

## メニュー・ヘルプ構成

- [メニューバー徹底解説](https://it-notes.stylemap.co.jp/programs/the-ultimate-guide-to-menu-bars/) — メニューバーの一般的な項目構成
- [Oracle CDE スタイルガイド — メニュー・バー](https://docs.oracle.com/cd/E19683-01/816-4039/cdechk-58/index.html) — ファイル/編集/表示/ヘルプの標準構成
- [Microsoft — Windows 7 メニュー設計ガイドライン](https://learn.microsoft.com/ja-jp/windows/win32/uxguide/cmd-menus) — ヘルプメニューの標準項目

## アイコン設計・生成

- [App Icons | Tauri v2](https://v2.tauri.app/develop/icons/) — Tauri v2 のアイコン仕様と `tauri icon` コマンドの使い方
- [Command Line Interface — icon | Tauri v2](https://v2.tauri.app/reference/cli/#icon) — `tauri icon [INPUT]` の入力形式（PNG/SVG、正方形必須）と生成ファイル一覧
- [draw.io CLI export](https://www.drawio.com/blog/export-diagrams) — draw.io デスクトップアプリの `--export` フラグによる SVG エクスポート（クロスプラットフォーム対応）

## タイムスタンプ・ファイル命名

- [Harvard Library — File Naming Best Practices](https://guides.library.harvard.edu/c.php?g=1033502&p=7496710) — タイムスタンプフォーマットの参考
- [UConn — File Naming and Date Formatting](https://guides.lib.uconn.edu/c.php?g=832372&p=8226285)
- [ISO 8601 — Wikipedia](https://en.wikipedia.org/wiki/ISO_8601) — 日付フォーマットの国際標準
- [ファイル名に日付をつけるときのルール](https://hokodate-eiichilaw.com/revival/work65) — 日本語圏での命名慣習

## 自動更新 (tauri-plugin-updater)

- [Tauri v2 Updater Plugin](https://v2.tauri.app/plugin/updater/) — 公式ドキュメント
- [tauri-plugin-updater crate](https://crates.io/crates/tauri-plugin-updater) — crates.io

### Windows のみ自動更新とした理由

- Windows ユーザーはインストーラー (.msi / NSIS) 経由で導入するため、アプリ内で完結する自動更新が UX として自然
- Linux / macOS ユーザーはコマンドライン経由（`curl | sh`）でインストールするパワーユーザーが多く、スクリプト更新の方が馴染みやすい
- Linux / macOS 向けの Tauri updater は AppImage / DMG 形式が前提であり、現在の配布形態（tar.gz）とは合わない（詳細は以下）

### AppImage (Linux) を採用しない理由

- **sidecar バイナリの破損リスク** — linuxdeploy が ELF の rpath を `$ORIGIN/../lib` に書き換えるため、kanata_cmd_allowed 等の sidecar が壊れる既知バグ（[tauri#11898](https://github.com/tauri-apps/tauri/issues/11898), [tauri#5445](https://github.com/tauri-apps/tauri/issues/5445)、upstream 未修正）。回避には AppImage 展開→バイナリ差替→再パックが必要
- **設定ファイルの永続化** — AppImage は読み取り専用ファイルシステム。config.toml や muhenkan.kbd を exe_dir に置く現行設計は使えず、XDG ディレクトリへの移行が必要
- **kanata の権限設定が依然必要** — uinput グループ追加 + udev ルール作成にはシステムレベルの設定が必要で、AppImage の「DL して即実行」のメリットが薄い
- **FUSE 依存** — Ubuntu 24.04+ / Fedora 39+ では libfuse2 が標準搭載されておらず、別途インストールが必要
- **バンドルサイズ** — GTK/WebKitGTK を同梱するため 70 MB 超。sidecar 含めると 100 MB 超になる可能性

### DMG/.app バンドル (macOS) を採用しない理由

- **Apple Developer Program の年間費用** — コード署名 + 公証（notarization）には $99/年の Developer ID 証明書が必須（[Apple Developer Program](https://developer.apple.com/programs/enroll/)）。署名なしだと「開発元が未確認」ダイアログが表示される
- **更新時の権限リセット** — 署名なし or 署名変更時、macOS が Input Monitoring 権限をリセットし kanata が動作不能に（[tauri#10567](https://github.com/tauri-apps/tauri/issues/10567)）。ユーザーが毎回手動で System Settings から再付与する必要がある
- **sidecar の署名・公証** — .app バンドル内の全バイナリを同一証明書で署名する必要あり。サードパーティ製の kanata バイナリも自分の証明書で署名が必要（[tauri#11992](https://github.com/tauri-apps/tauri/issues/11992)）
- **Universal Binary 要件** — Intel (x86_64) + Apple Silicon (aarch64) の両方をサポートするには、sidecar も含めて universal binary 化（lipo）が必要
- **設定ファイルの永続化** — .app バンドル内は読み取り専用。config.toml 等は `~/Library/Application Support/` に移す再設計が必要

### 参考リンク

- [Tauri v2 AppImage docs](https://v2.tauri.app/distribute/appimage/)
- [Tauri v2 macOS Code Signing](https://v2.tauri.app/distribute/sign/macos/)
- [Tauri v2 macOS Application Bundle](https://v2.tauri.app/distribute/macos-application-bundle/)
- [kanata Linux setup](https://github.com/jtroo/kanata/blob/main/docs/setup-linux.md)
- [kanata — Avoid using sudo on Linux](https://github.com/jtroo/kanata/wiki/Avoid-using-sudo-on-Linux)
